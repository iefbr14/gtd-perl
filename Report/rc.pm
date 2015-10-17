package Hier::Report::rc;

=head1 Bulk Load Syntax

  num:	Id of Roal/Goal/Proj/Action (Tab/Empty for New)
  type:	Type of Id (R/G/P) (if no num, will lookup this entry)
 or
  [_]	Next Action
  [ ]	Action
  [*]	Done
  [X]	Delete
  [-]	Hidden
  { }	Somday/maybe
 or
  ?attr	Attribute
  +	Description
  =	Result
  @cct	Category/Context/Timeframe
  *tag	Tag(s)
  #	comment
 or	
	Blank line end of group

=cut

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_rc);
}

use strict;
use warnings;

use Hier::Meta;
use Hier::Option;
use Hier::Format;
use Hier::Report::edit;

my $Parent;
my $Child;
my $Type;
my $Info = {};

my $Mode = option('Mode', 'task');
my $Prompt = '';
my $Debug = 1;

my($Pid) = '';	# current Parrent task;
my($Pref);	# current Parrent task reference;

my($Parents) = {};	# parrents we know about

my($Cmds) = {
	'up'	=> \&rc_up,
	'p'	=> \&rc_print,
	'edit'	=> \&rc_edit,

	option	=> \&rc_option,
	format  => \&rc_format,
	sort    => \&rc_sort,

	clear   => \&rc_clear,
};

sub Report_rc { #-- rc - Run Commands

	if (-t STDIN) {
		$Prompt = '>';
		$| = 1;
	}

	for (;;) {
		if ($Prompt) {
			print "$Pid$Prompt ";	# 12>
		}

		$_ = <>;
		last unless defined $_;
		chomp;

		next if /^\s*#/;
		next if /^\s*$/;

		eval {
			rc($_);
		}; if ($@) {
			print "? $@\n";
		}
	}
	rc_save();
	print "quit # eof\n";
}

sub rc {
	my($line) = @_;

	if ($line =~ /^debug/) {
		$Debug = 1;
		print "Debug on\n";
		return;
	}

	if ($line =~ /^\?/) {
		help();
		return;
	}

	if ($line =~ s/^\!//) {
		system($line);
		return;
	}

	my($cmd, @args) = split(' ', $line);

	# maybe we shouldn't split this?
	if ($cmd =~ s/:$//) {
		rc_set_key($cmd, @args);
		return;
	}

	if (defined $Cmds->{$cmd}) {
		my($func) = $Cmds->{$cmd};

		&$func(@args);
		return;
	}

	if (/^(\d+)$/) {
		rc_save();

		# get context
		$Pref = meta_find($cmd);
		unless ($Pref) {
			$Pid = '';
			print "Can't find pid: $cmd\n";
			next;
		}

		$Pid = $Pref->get_tid();
		my($type) = $Pref->get_type();
		$Parents->{$type} = $Pid;
		
		print "Current($type): $cmd - ", $Pref->get_title(), "\n";
		return;
	}

	report($cmd, @args);
}

sub rc_set_key {
	my($key) = shift(@_);

	unless (defined $Pref) {
		print "No task set.\n";
		return;
	}
	set_KEY($key, join(' ', $_));
}

sub rc_save {
	return unless $Pref;

	$Pref->update();
}

sub rc_up {
	unless (defined $Pref) {
		print "No task set.\n";
		return;
	}
	$Pref = $Pref->get_parent();
	$Pid = $Pref->get_tid();
	my($type) = $Pref->get_type();
	$Parents->{$type} = $Pid;
	
	print "Parent($type): $Pid - ", $Pref->get_title(), "\n";
}

sub rc_option {
	my($option, $value) = @_;

	my($old) = option($option, $value);

	print "Option $option: $old => $value\n";
}

sub rc_edit {
	use Hier::Report::edit;

	if (@_) {
		Report_edit(@_);
	} else {
		Report_edit($Pid);
	}
}

sub rc_print {
	if (scalar(@_) == 0) {
		display_task($Pref);
		return;
	}

	for my $tid (@_) {
		my($ref) = meta_find($tid);

		unless ($ref) {
			print "? not found: $ref\n";
			next;
		}
		display_task($ref);
	}
}

#==============================================================================
# Mode setting
#------------------------------------------------------------------------------
sub rc_format {
	my($mode) = @_;

	set_option('Mode', $mode);
	set_option('Format', $mode);

	display_mode($mode);
}

sub rc_sort {
	my($mode) = @_;

	set_option('Sort', $mode);
	sort_mode($mode);
}

#==============================================================================
# Utility builtins
#------------------------------------------------------------------------------
sub rc_clear {
	print "\e[H\e[2J";

	if (@_) {
		rc(join(' ', @_));	# shouldn't have to do this
	}
}

#==============================================================================

sub fixme {
	my($action) = \&add_nothing;
	my($desc) = '';

	my(@lines);

	#---------------------------------------------------
	# default values
	if (/^pri\D+(\d+)/) {
		set_option('Priority', $1);
		next;
	}
	if (/^limit\D+(\d+)/) {
		set_option('Limit', $1);
		next;
	}
	if (/^format\s(\S+)/) {
		set_option('Format', $1);
		next;
	}
	if (/^header\s(\S+)/) {
		set_option('Header', $1);
		next;
	}

	if (/^sort\s(\S+)/) {
		set_option('Header', $1);
		next;
	}
	if (/^edit$/) {
		eval {
			Report_edit($Pid, $Child);
		}; if ($@) {
			print "Trapped error: $@\n";
		}
		next;
	}

	#---------------------------------------------------


	if (s/^([a-z]+):\s*//) {
		chomp;
		$Info->{$1} = $_;
		next;
	}

	if (s/^(\d+)\t[A-Z]:\s*//) {
		&$action($Parents, $desc);
		$action = \&add_update;
		$Pid = $1;
		$Parents->{me} = $Pid;
		next;
	}
	if (s/^R:\s*//) {
		&$action($Parents, $desc);

		$Pid = find_hier('r', $_);
		die unless $Pid;
		$Parents->{r} = $Pid;
		next;
	}
	if (s/^G:\s*//) {
		&$action($Parents, $desc);

		$Pid = find_hier('g', $_);
		if ($Pid) {
			$action = \&add_nothing;
			$Parents->{g} = $Pid;
		} else {
			$action = \&add_goal;
		}
		next;
	}
	if (s/^[P]:\s*//) {
		&$action($Parents, $desc);

		$action = \&add_project;
		set_option(Title => $_);
		$desc = '';
		next;
	}
	if (s/^\[_*\]\s*//) {
		&$action($Parents, $desc);

		$action = \&add_action;
		set_option(Title => $_);
		$desc = '';
		next;
	}
	$desc .= "\n" . $_;
}


sub find_hier {
	my($type, $goal) = @_;

	for my $ref (meta_hier()) {
		next unless $ref->get_type() eq $type;
		next unless $ref->get_title() eq $goal;

		return $ref->get_tid();
	}
	for my $ref (meta_hier()) {
		next unless $ref->get_type() eq $type;
		next unless lc($ref->get_title()) eq lc($goal);

		return $ref->get_tid();
	}

	for my $ref (meta_hier()) {
		next unless $ref->get_title() eq $goal;
	
		my($type) = $ref->get_type();
		my($tid) = $ref->get_tid();
		warn "Found: something close($type) $tid: $goal\n";
		return $tid;
	}
	die "Can't find a hier item for '$goal' let alone a $type.\n";
}

sub add_nothing {
	my($parents, $desc) = @_;

	# do nothing
	print "# nothing pending\n" if $Debug;

	if ($desc) {
		print "Lost description\n" if $desc;
	}
}

sub add_goal {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'r'};

	$tid = add_task('g', $desc);

	$parents->{'g'} = $tid;
}

sub add_project {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'g'};

	$tid = add_task('p', $desc);

	$parents->{'p'} = $tid;
}

sub add_action {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;
	$Parent = $parents->{'p'};

	$tid = add_task('a', $desc);
}

sub add_task {
	my($type, $desc) = @_;

	my($pri, $title, $category, $note, $line);

	$title    = option("Title");
	$pri      = option('Priority') || 4;
	$desc     = option("Desc") || $desc;

	$category = option('Category') || '';
	$note     = option('Note'); 

	my $ref = Hier::Tasks->new(undef);

	$ref->set_category($category);
	$ref->set_title($title);
	$ref->set_description($desc);
	$ref->set_note($note);

	$ref->set_type($type);

	if ($pri > 5) {
		$pri -= 5;
		$ref->set_isSomeday('y');
	}
	$ref->set_nextaction('y') if $pri < 3;
	$ref->set_priority($pri);

	print "Parent: $Parent\n";

	$Child = $ref->get_tid();

	$ref->set_parents_ids($Parent);

	print "Created ($type): ", $ref->get_tid(), "\n";

	for my $key (keys %$Info) {
		$ref->set_KEY($key, $Info->{$key});
	}
	$Info = {};

	$ref->insert();
	return $ref->get_tid();
}

sub report {
	my($report) = shift @_;

	eval "use Hier::Report::$report";
	if ($@) {
		my($error) = "Report compile: $@\n";
		if ($error =~ /Can't locate Hier.Report.$report/) {
			print "Unknown command $report\n";
			print "try:  reports # for a list of reports\n";
			return;
		}
		print "Report compile failed: $@\n";
		return;
	}

	print "### Report $report args: @_\n" if $Debug;

	set_option('Format', undef);
	eval "Report_$report(\@_);";	# call report with argv
	if ($@) {
		print "Report $report failed: $@";
		return;
	}
#	$Cmds->{$report} = \&"Report_$report";

	display_mode(option('Mode', 'task'));
}

1;  # don't forget to return a true value from the file
