package report

/*
NAME:

rc

=head1 USAGE

rc 

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

rc is 

=head1 DIAGNOSTICS

=head1 EXIT STATUS

none

=head1 CONFIGURATION

=item format

=item option

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR,  LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

Started life as a copy of the bulkload but tuned for more interactive processing

*/

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_rc);
}

use strict;
use warnings;

use Term::ReadLine;

use Hier::Meta;
use Hier::Option;
use Hier::Format;
use Hier::Sort;
use Hier::Prompt;

my $Parent;
my $Child;
my $Type;
my $Info = {};

my $Mode = option('Mode', 'task');

my $Filter = '-';
my $Format = '-';
my $Header = '-';
my $Sort   = '-';

my $Prompt = '>';
our $Debug = 0;

my($Pid) = '';	// current Parrent task;
my($Pref);	// current Parrent task reference;

my($Parents) = {};	// parents we know about

my($Cmds) = {
	help    => \&rc_help,

	'up'	=> \&rc_up,
	'p'	=> \&rc_print,

	option	=> \&rc_option,
	filter  => \&rc_filter,
	format  => \&rc_format,
	sort    => \&rc_sort,

	clear   => \&rc_clear,
	gtd     => \&rc_clear,
};

sub Report_rc { #-- rc - Run Commands
	// init from command line.
	// there are commands to override later
	$Filter = option('Filter') || '-';
	$Format = option('Format') || '-';
	$Sort   = option('Sort')   || '-';

//	my $OUT = $term->OUT || \*STDOUT;
//       print $OUT $res, "\n" unless $@;

	for (;;) {
		prompt($Prompt, '#');
		last unless defined $_;

		eval {
			rc($_);
		}; if ($@) {
			print "? $@\n";
		}
	}
	rc_save();
}

sub rc {
	my($line) = @_;

	//## remove leading white space from commands.
	$line =~ s/^\s+//;

	//##   :cmd  =>  rc command mode (noop here)
	if ($line =~ s/^\://) {
		//## continue this is redundent
	}

	if ($line =~ s/^set\s+//) {
		//# continue as if set wasn't said
	}

	if ($line =~ s/^debug\s*//) {
		if ($line) {
			debug($line);
			return;
		}

		$Debug = 1;
		print "Debug rc on\n";
		return;
	}

	if ($line =~ s/^\?//) {
		rc_help($line);
		return;
	}

	//##   .tid  =>  kanban .tid
	if ($line =~ m/^\./) {
		report('kanban', split(' ', $line));
		return;
	}

	//##   /key  =>  search  key
	if ($line =~ s/^\///) {
		rc_find_tasks($line);
		return;
	}

	//##   !cmd  =>  shell out for cmd
	if ($line =~ s/^\!//) {
		system($line);
		return;
	}

	// check for task member updates ie: 'key:value' pairs
	if ($line =~ s/^(\w+)\:\s*//) {
		rc_set_key($1, $line);
		return;
	}

	my($cmd, @args) = split(/[\s;]+/, $line);

	if (defined $Cmds->{$cmd}) {
		my($func) = $Cmds->{$cmd};

		&$func(@args);
		return;
	}

	return load_task($cmd) if $cmd =~ /^\d+$/;

	rc_save();
	report($cmd, @args);
}

sub rc_set_key {
	my($key) = shift(@_);

	unless (defined $Pref) {
		print "No task set.\n";
		return;
	}
	$Pref->set_KEY($key, join(' ', @_));
}

sub rc_save {
	return unless $Pref;

	$Pref->update() if $Pref->is_dirty();
}

sub rc_help {
	if (@_ && $_[0] ne '') {
		report('help', @_);
		return;
	}

print << 'EOF';
   #        comments (and blank lines ignored)
   !        shell commands
   /        search and set task
   .tid     kanban bump tid

   clear     clear screen before running command
   option    set option
   format    to set default formats
   sort      to set default sort order

   999       to set current task
   p         to print current task
   up        to go to current task's parent
   field:    to change any field in the current task

   ....      to run any current report
EOF
}
   

sub rc_up {
	unless (defined $Pref) {
		print "No task set.\n";
		return;
	}

	load_task_ref('Parent', $Pref->get_parent());
}

sub rc_option {
	my($option, $value) = @_;

	my($old) = option($option, $value);

	print "Option $option: $old => $value\n";
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

//==============================================================================
// Mode setting
//------------------------------------------------------------------------------
sub rc_filter {
	my($mode) = @_;

	unless ($mode) {
		print "Filter: $Filter\n";
		return;
	}
	
	print "Filter $Filter => $mode\n";

	set_option('Filter', dash_null($mode));
	meta_reset_filters($mode eq '-' ? '+live' : $mode);

	$Filter = $mode;
}

sub rc_format {
	my($mode) = @_;

	unless ($mode) {
		print "Format $Format\n";
		return;
	}
	
	print "Format $Format => $mode\n";

	set_option('Format', dash_null($mode));
	display_mode($mode eq '-' ? 'task' : $mode);

	$Format = $mode;
}

sub rc_header {
	my($mode) = @_;

	unless ($mode) {
		print "Header $Header\n";
		return;
	}
	
	print "Header $Header => $mode\n";

	set_option('Header', dash_null($mode));
	display_mode($mode eq '-' ? 'task' : $mode);

	$Header = $mode;
}

sub rc_sort {
	my($mode) = @_;

	unless ($mode) {
		print "Sort $Sort\n";
		return;
	}

	print "Sort $Sort => $mode\n";

	set_option('Sort', dash_null($mode));
	sort_mode($mode eq '-' ? '^title' : $mode);

	$Sort = $mode;
}

//==============================================================================
// Utility builtins
//------------------------------------------------------------------------------
sub rc_clear {
	//##BUG### this should call ff and have it
	//######## clear the screen in termial mode

	local($|) = 1;
	print "\e[H\e[2J";

	if (@_) {
		rc(join(' ', @_));	// shouldn't have to do this
	}
}

sub rc_prompt {
	my($prompt) = @_;

}

sub load_task {
	my($tid) = @_;

	rc_save();

	// get context
	my($ref) = meta_find($tid);
	unless ($ref) {
		print "Can't find tid: $tid\n";
		return;
	}

	load_task_ref('Current', $ref);
}

sub load_task_ref {
	my($why, $ref) = @_;

	$Pref = $ref;
	$Pid = $ref->get_tid();

	my($type) = $ref->get_type();
	my($title) = $ref->get_title();

	$Parents->{$type} = $Pid;

	$Prompt = "$Pid>";
	set_option('Current', $Pid);
		
	print "$why($type): $Pid - $title\n";
}

//==============================================================================

sub fixme {
	my($action) = \&add_nothing;
	my($desc) = '';

	my(@lines);

	//---------------------------------------------------
	// default values
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

	//---------------------------------------------------


	if (s/^([a-z]+):\s*//) {
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
		panic("No parge $_") unless $Pid;
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


sub rc_find_tasks {
	my($pattern) = @_;

	$pattern =~ s=/$==;	// remove trailing /

	my(@list);

	for my $ref (Hier::Tasks::all()) {
		my($title) = $ref->get_title();
		if ($title =~ /$pattern/i) {
			display_task($ref);
		}
	}
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
	panic("Can't find a hier item for '$goal' let alone a $type.\n");
}

sub add_nothing {
	my($parents, $desc) = @_;

	// do nothing
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

	$ref->set_parent_ids($Parent);

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

	Hier::Tasks::clean_up_database();

	return unless load_report($report);
	print "### Report $report args: @_\n" if $Debug;

	// force options back to our defaults (including no defaults)
	set_option('Filter', dash_null($Filter));
	set_option('Format', dash_null($Format));
	set_option('Header', dash_null($Header));
	set_option('Sort',   dash_null($Sort));

//	$Cmds->{$report} = \&"Report_$report";

	run_report($report, @_);
	display_mode(option('Mode', 'task'));
	Hier::Tasks::reload_if_needed_database();
}

sub dash_null {
	my($val) = @_;

	return undef if $val eq '-';
	return $val;
}

1;  # don't forget to return a true value from the file
