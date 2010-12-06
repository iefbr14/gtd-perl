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
use Hier::Tasks;

my $ToOld;
my $ToFuture;

sub Report_taskjuggler {	#-- generate taskjuggler file from gtd db
	my(@criteria) = @_;
	my($tid, $task, $cat, $ins, $due, $desc);

	$ToOld = today(-180);	# don't care about done items > 6months
	$ToFuture = today(180);	# don't care about start more > 6months

	add_filters('+any', '+all', @criteria);
	my($planner) = new Hier::Walk;
	$planner->set_depth('a');
	$planner->filter();

	bless $planner;
	$planner->walk();
}

sub tj_header {
	my($start);
print <<'EOF';
project GTD "RockSalt Upgrade" "1.0" 2006-01-01 - 2012-12-31 {
  # Hide the clock time. Only show the date.
  timeformat "%Y-%m-%d"

  # The currency for all money values is CAN
  currency "CAN"

  # We want to compare the baseline scenario, to one with a slightly
  # delayed start.
  scenario plan "Plan" {
    scenario done "Done"
  }
}
account costs "Costs" cost
rate 50.0
resource drew "Drew" {}
EOF
}

sub header {
	hier_detail(@_);
}

sub task_detail {
	hier_detail(@_);
	end_detail(@_);
}

sub hier_detail {
	my($planner, $ref) = @_;
	my($sid, $name, $cnt, $desc, $pri, $type, $note);
	my($per, $start, $end, $done, $due, $we);
	my($who, $doit, $role, $depends);

	my($tid) = $ref->get_tid();

	my($indent) = $planner->indent();
	my($resource) = new Hier::Resource($ref);
	
	$name = $ref->get_task() || '';
	$pri  = $ref->get_priority() || 3;
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

	if ($done && $done lt $ToOld) {
		$planner->{want}{$tid} = 0;
		return;
	}
	if ($start && $start gt $ToFuture) {
		$planner->{want}{$tid} = 0;
		return;
	}

	$who = 'drew';

	my($effort) = $resource->effort($ref);

	# pri 1=>200 and 5=>1000 so tj 1=>900 and 5=>100
	my $tj_pri = 1100 - $pri * 200;
	$tj_pri -= 100 if $ref->get_isSomeday() eq 'y';
#	$tj_pri += $ref->count_actions();
	$tj_pri = 1 if $tj_pri <= 0;


	$due = '' if $due && $due lt '2010-';
	$we    = $done || $due || '';

	my($fd) = $planner->{fd};

	print {$fd} $indent, qq(task $type\_$tid "$name" \{\n);


	if ($type eq 'm') {
		print {$fd} $indent, qq(  start \${now}\n);
	}
	if ($role && parent_role($ref) ne $role) {
		print {$fd} $indent, qq(  allocate $role\n);
	}
	foreach my $depend (split(/[ ,]/, $depends)) {
		my($dep_path) = dep_path($depend);
warn "depend: $depend dep_path $dep_path\n";
		next unless $dep_path;
		print {$fd} $indent, qq(  depends $dep_path\n);
	}

	print {$fd} $indent, qq(  effort $effort\n) if $effort;
	print {$fd} $indent, qq(  priority $tj_pri\n) if $tj_pri != 500;
	
	print {$fd} $indent, qq(  start $start\n) if $start;
	print {$fd} $indent, qq(  end   $we\n)   if $we;
	print {$fd} $indent, qq(  complete  100\n)   if $done;
}

sub indent {
	my($planner) = @_;

	my($level) = $planner->{level} || 0;

	return '' if $level <= 0;

	return '  ' x $level;
}

sub end_detail {
	my($planner, $ref) = @_;

	my($tid) = $ref->get_tid();
	return if $planner->{want}{$tid} == 0;

	my($fd) = $planner->{fd};
	my($indent) = $planner->indent();
	

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
	return $date;
}

sub parent_role {
	my($ref) = @_;

	my($pref) = $ref->get_parent();
	return '' unless $pref;

	return $pref->get_resource();
}

sub dep_path {
	my($tid) = @_;

	my($ref) = Hier::Tasks::find($tid);
	return unless $ref;

	my($path) = $ref->get_type() . '_' . $tid;
	my($pref);

	for (;;) {
		$ref = $ref->get_parent();
		last unless $ref;

		$path = $ref->get_type() . '_' . $ref->get_tid() . '.' . $path;
	}
	return $path;
}

1;  # don't forget to return a true value from the file
