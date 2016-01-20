package Hier::Report::taskjuggler;

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_taskjuggler);
}

use Hier::Util;
use Hier::Walk;
use Hier::Resource;
use Hier::Meta;
use Hier::Format;
use Hier::Option;	# get_today

my $ToOld;
my $ToFuture;

my $Someday = 0;

our $Debug;

sub Report_taskjuggler {	#-- generate taskjuggler file from gtd db
	my($tid, $task, $cat, $ins, $due, $desc);

	$ToOld = pdate(get_today(-7));	# don't care about done items > 2 week

	meta_filter('+all', '^focus', 'none');
	my($top) = 'o';			# default to top of everything
	for my $criteria (meta_argv(@_)) {
		if ($criteria eq 'all') {
			$Someday = 1;
			next;
		}

		if ($criteria =~ /^\d+$/) {
			$top = $criteria;
			next;
		} 
		my($type) = type_val($criteria);
		if ($type) {
			$type = 'p' if $type eq 's';
			$top = $type;
		} else {
			die "unknown type $criteria\n";
		}
	}

	if ($Someday) {
		meta_filter('+all', '^focus', 'none');
		# 5 year plan everything plan
		$ToFuture = pdate(get_today(5*365));	
	} else {
		meta_filter('+active', '^focus', 'none');
		# don't care about start more > 3 months
		$ToFuture = pdate(get_today(60));	
	}

	my($walk) = new Hier::Walk(
		pre    => \&build_deps,
		detail => \&hier_detail,
		done   => \&end_detail,
	);
	$walk->set_depth('a');
	$walk->filter();

	tj_header();

	$walk->walk($top);
}

sub calc_est {
	my($hours) = 0;
	my($task) = 0;

	for my $ref (meta_selected()) {
		++$task;

		my($resource) = new Hier::Resource($ref);
		$hours += $resource->hours($ref);
	}
	my($days) = $hours / 4;

	warn "Tasks: $task Est days $days (min 90)\n";

	$days = 90 if $days < 90;
	return $days;
}

sub tj_header {
	my $est = calc_est();
	my $projection = pdate(get_today($est));	
print <<"EOF";
project GTD "Get Things Done" "1.0" $ToOld - $projection {
  # Hide the clock time. Only show the date.
  timeformat "%Y-%m-%d"

  # The currency for all money values is CAN
  currency "CAN"
  weekstartssunday

  # We want to compare the baseline scenario, to one with a slightly
  # delayed start.
  scenario plan "Plan" {
    scenario done "Done"
  }
}

include "Triad-resource.tji"
include "Triad-reports.tji"

EOF

}

sub hier_detail {
	my($walk, $ref) = @_;
	my($sid, $name, $cnt, $desc, $type, $note);
	my($per, $start, $end, $done, $due, $we);
	my($who, $doit, $depends);
	my($tj_pri);

	my($tid) = $ref->get_tid();

	print "# taskjuggler::hier_detail($tid)\n" if $Debug;

	my($indent) = indent($ref);
	my($resource) = new Hier::Resource($ref);

	$name = $ref->get_title() || '';
	$tj_pri  = task_priority($ref);
	$desc = display_summary($ref->get_description(), '', 1);
	$note = display_summary($ref->get_note(), '', 1);
	$type = $ref->get_type() || '';
	$per  = $ref->get_completed() ? 100 : 0;
	$due  = pdate($ref->get_due());
	$done = pdate($ref->get_completed());
	$start = pdate($ref->get_tickledate());
	$doit = pdate($ref->get_doit());
	$depends = $ref->get_depends();

	my $user = $resource->resource();
	my $hint = $ref->get_hint();

	print "## $tid $tj_pri $type $name\n" if $Debug;

	return if skip($walk, $ref);

	if ($start && $start lt $ToOld) {
		$start = '';
	}

	$who = 'drew';

	my($effort) = $resource->how();

	$due = '' if $due && $due lt '2010-';
	$we    = $due || '';

	my($pri) = $ref->get_priority();
	$we    = '' if $pri >= 6;

	my($fd) = $walk->{fd};

	$name =~ s/"/'/g;
	print {$fd} $indent, qq(task $type\_$tid "$name" \{\n);

	if ($indent eq '') {
		print {$fd} $indent, qq(   start \${now}\n);
		print {$fd} $indent, qq(   allocate $user # $hint\n);
	} elsif ($user && parent_user($ref) ne $user) {
		print {$fd} $indent, qq(   allocate $user { mandatory } # $hint\n);
	}

	foreach my $depend (split(/[ ,]/, $depends)) {
		my($dep_path) = dep_path($depend);

		unless ($dep_path) {
			warn "depend $tid: needs $depend failed to produce path!";
			next;
		}
		if ($dep_path =~ /^\s*#/) {
			warn "depend $tid: no-longer depends: $depend $dep_path\n";
			next;
		}

		warn "depend $tid: $depend dep_path $dep_path\n";
		print {$fd} $indent, qq(   depends $dep_path\n);
	}

	###BUG### taskjuggler need to check for un-filtered children for effort
	if ($ref->get_children()) {
		# nope has children, we just accumlate effor in them
	} else {
		if ($effort) {
			++$ref->{_effort};
		}
		print {$fd} $indent, qq(   effort $effort\n) if $effort;
	}
	print {$fd} $indent, qq(   priority $tj_pri\n) if $tj_pri;
	
	print {$fd} $indent, qq(   start $start\n) if $start && $we eq '';
	print {$fd} $indent, qq(   maxend  $we\n)   if $we && $we gt $ToOld;
	print {$fd} $indent, qq(   complete  100\n)   if $done;
}

sub indent {
	my($ref) = @_;

	my($level) = $ref->level() - 1;

	return '' if $level <= 0;

	return '   ' x ($level);
}

sub end_detail {
	my($walk, $ref) = @_;

	return if skip($walk, $ref);

	my($tid) = $ref->get_tid();

	my($fd) = $walk->{fd};
	my($indent) = indent($ref);

	my($type) = $ref->get_type();

	unless ($ref->{_effort}) {
		my($task) = $ref->get_title();
		my($type) = $ref->get_type();
		my ($effort) = '1h # action';
		$effort = '2h # Need planning' if $type eq 'p';
		$effort = '8h # Need planning' if $type eq 'g';

		print {$fd} $indent, qq(   effort $effort\n);
		warn "Task $tid: $task |<<< Needs effort planning\n";

		++$ref->{_effort};
	}

	my($pref) = $ref->get_parent();
	++$pref->{_effort};

	if ($type =~ /[mvog]/) {
		print {$fd} $indent, qq(} # $type\_$tid\n);
		return;
	}
	print {$fd} $indent, qq(}\n);
}

sub pdate {
	my($date) = @_;

	return '' if $date eq '';
	return '' if $date =~ /^0000/;

	$date =~ s/ .*$//;
	return $date;
}

sub parent_user {
	my($ref) = @_;

	my($pref) = $ref->get_parent();
	return '' unless $pref;

	my($resource) = new Hier::Resource($pref);
	return $resource->resource();
}

sub old_task_priority {
	my($ref) = @_;

	my($pri) = $ref->get_priority();

	return '' unless $pri;

	my($type) = $ref->get_type();
	return '' if $type eq 'o';
	return '' if $type eq 'g';
	return '' if $type eq 'p';

	my($boost) = $ref->is_nextaction();

	my($prival) = '';

	for (;;) {
		$pri = $ref->get_priority();
		$pri += 4 if $ref->is_someday();
		$prival = $pri . $prival;

		last if $ref->get_type() eq 'g';

		$ref = $ref->get_parent();
		last unless $ref;
		last if $ref->get_type() eq 'g';
	}

	return '' if $prival =~ /^4+$/;	 # all defaults

	my($tj_pri) = 1100 - int(('.' . $prival) * 1000);

	$tj_pri = 1 if $tj_pri <= 0;

	if ($type eq 'a' && $boost) {
		$tj_pri += 100;
		$tj_pri = 999 if $tj_pri >= 1000;
	}
	return $tj_pri . " # $prival.$boost";
}

sub task_priority {
	my($ref) = @_;

	my($pf) = Hier::Sort::calc_focus($ref);

	my($tj_pri) = substr($pf.'zzzzzz', 2, 3);
	$pf =~ s/^(..)/$1./;

	#         123451234512345
	$tj_pri =~ tr{abcdefghijklmnoz}
                     {9987766544321000};

	$tj_pri = 1000 if $tj_pri >= 1000;
	$tj_pri = 1 if $tj_pri <= 0;

	return $tj_pri . " # $pf";
}

sub skip {
	my($walk, $ref) = @_;

	my $start = pdate($ref->get_tickledate());
	my $done = pdate($ref->get_completed());

	if ($Someday == 0 && $ref->is_someday()) {
		supress($walk, $ref);
		return 1;
	}

	if ($done) {
		supress($walk, $ref);
		return 1;
	}
	if ($start && $start gt $ToFuture) {
		supress($walk, $ref);
		return 1;
	}

	return 0;
}


sub supress {
	my($walk, $ref) = @_;

	my($tid) = $ref->get_tid();
	$walk->{want}{$tid} = 0;

	foreach my $child ($ref->get_children()) {
		supress($walk, $child);
	}
}
#==============================================================================
my %Dep_list;

sub build_deps {
	my($walk, $ref, $level) = @_;

	$level ||= 1;

	calc_depends($walk, $ref, $level);
	for my $child ($ref->get_children()) {
		build_deps($walk, $child, $level+1);
	}
}

sub calc_depends {
	my($walk, $ref, $level) = @_;

	my($tid) = $ref->get_tid();
	return if defined $Dep_list{$tid};

#	return if skip($walk, $ref);

	my($path) = $ref->get_type() . '_' . $tid;

	if ($level == 1) {
		$Dep_list{$tid} = $path;
		return;
	}

	my $pref = $ref->get_parent();
	my $pid = $pref->get_tid();

	if ($Dep_list{$pid}) {
		$path = $Dep_list{$pid} . '.' . $path;
		$Dep_list{$tid} = $path;
		
		return;
	}
}


sub dep_path {
	my($tid) = @_;

	my($ref) = meta_find($tid);
	return unless $ref;

	my($path) = $Dep_list{$tid};

	my($task) = $ref->get_title($ref);

	return "$path # $task" if $path;

	print "# Can't map $tid ($task) as a depencency\n";
	warn "Can't map $tid ($task) as a depencency\n";

	return ''
}


1;  # don't forget to return a true value from the file
