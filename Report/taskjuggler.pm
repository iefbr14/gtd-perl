package Hier::Report::taskjuggler;

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

use Hier::util;
use Hier::Walk;
use Hier::Resource;
use Hier::Meta;
use Hier::Format;
use Hier::Option;	# get_today

my $ToOld;
my $ToFuture;

my $Someday = 0;

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

	my($walk) = new Hier::Walk();
	$walk->set_depth('a');
	$walk->filter();

	Taskjuggler::build_deps($walk, $top);

	tj_header();

	bless $walk;	# take ownership and walk the tree
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
	my($who, $doit, $role, $depends);
	my($tj_pri);

	my($tid) = $ref->get_tid();

	my($indent) = $walk->indent();
	my($resource) = new Hier::Resource($ref);
	
	$name = $ref->get_task() || '';
	$tj_pri  = task_priority($ref);
	$desc = summary_line($ref->get_description(), '', 1);
	$note = summary_line($ref->get_note(), '', 1);
	$type = $ref->get_type() || '';
	$per  = $ref->get_completed() ? 100 : 0;
	$due  = pdate($ref->get_due());
	$done = pdate($ref->get_completed());
	$start = pdate($ref->get_tickledate());
	$doit = pdate($ref->get_doit());
	$depends = $ref->get_depends();

	$role = $resource->resource($ref);

	return if $type eq 'C'; # Checklists
	return if $type eq 'L'; # Lists
	return if $type eq 'T'; # Item

	return if skip($walk, $ref);

	if ($start && $start lt $ToOld) {
		$start = '';
	}

	$who = 'drew';

	my($effort) = $resource->effort($ref);

	$due = '' if $due && $due lt '2010-';
	$we    = $due || '';

	my($pri) = $ref->get_priority();
	$we    = '' if $pri >= 6;

	my($fd) = $walk->{fd};

	$name =~ s/"/'/g;
	print {$fd} $indent, qq(task $type\_$tid "$name" \{\n);

	if ($indent eq '') {
		print {$fd} $indent, qq(   start \${now}\n);
		print {$fd} $indent, qq(   allocate $role\n);
	} elsif ($role && parent_role($ref) ne $role) {
		print {$fd} $indent, qq(   allocate $role { mandatory }\n);
	}

	foreach my $depend (split(/[ ,]/, $depends)) {
		my($dep_path) = Taskjuggler::dep_path($depend);

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

	print {$fd} $indent, qq(   effort $effort\n) if $effort;
	print {$fd} $indent, qq(   priority $tj_pri\n) if $tj_pri;
	
	print {$fd} $indent, qq(   start $start\n) if $start && $we eq '';
	print {$fd} $indent, qq(   maxend  $we\n)   if $we && $we gt $ToOld;
	print {$fd} $indent, qq(   complete  100\n)   if $done;
}

sub indent {
	my($walk) = @_;

	my($level) = $walk->{level} || 0;

	return '' if $level <= 0;

	return '   ' x ($level);
}

sub end_detail {
	my($walk, $ref) = @_;

	my($tid) = $ref->get_tid();
	return if $walk->{want}{$tid} == 0;

	my($fd) = $walk->{fd};
	my($indent) = $walk->indent();

	my($type) = $ref->get_type();

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

sub parent_role {
	my($ref) = @_;

	my($pref) = $ref->get_parent();
	return '' unless $pref;

	my($resource) = new Hier::Resource($pref);
	return $resource->resource($pref);
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

	my($pri) = $ref->get_priority();
	$pri += 4 if $ref->is_someday();

	return '' unless $pri;
	return '' if $pri == 4;

	my($type) = $ref->get_type();
#	return '' if $type eq 'o';
#	return '' if $type eq 'g';
#	return '' if $type eq 'p';

	my($boost) = $ref->is_nextaction();

	my($tj_pri) = (1000 - ($pri*100)) + $boost*50;

	$tj_pri = 1000 if $tj_pri >= 1000;
	$tj_pri = 1 if $tj_pri <= 0;

	return $tj_pri . " # $pri.$boost";
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
package Taskjuggler;

use Hier::Walk;
use Hier::Meta;

my %Dep_list;

sub build_deps {
	my($walk, $top) = @_;

	bless $walk;	# take ownership and walk the tree
	$walk->walk($top);
}

sub hier_detail {
	my($walk, $ref) = @_;

	my($tid) = $ref->get_tid();
	return if defined $Dep_list{$tid};

	return if Hier::Report::taskjuggler::skip($walk, $ref);

	my($path) = $ref->get_type() . '_' . $tid;

	if ($walk->{level} == 0) {
		$Dep_list{$tid} = $path;
		return;
	}

	my($fook) = '';

	for my $pref ($ref->get_parents()) {
		my $pid = $pref->get_tid();

		if ($Dep_list{$pid}) {
			$path = $Dep_list{$pid} . '.' . $path;
			$Dep_list{$tid} = $path;
			
			return;
		}

		$fook .= " $pid ";
	}
	warn "Can't find parrent for $tid -> $fook\n";
}


sub dep_path {
	my($tid) = @_;

	my($ref) = meta_find($tid);
	return unless $ref;

	my($path) = $Dep_list{$tid};

	my($task) = $ref->get_task($ref);

	return "$path # $task" if $path;

	print "# Can't map $tid ($task) as a depencency\n";
	warn "Can't map $tid ($task) as a depencency\n";

	return ''
}


sub end_detail {
}
1;  # don't forget to return a true value from the file
