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

use Hier::globals;
use Hier::walk;
use Hier::util;
use Hier::Tasks;

my $Today = `date +%04Y%02m%02dT080000Z`; chomp $Today;

sub Report_taskjuggler {	#-- Hiericial List of Values/Visions/Roles...
	my($criteria) = @_;
	my($tid, $task, $cat, $ins, $due, $desc);

	add_filters('+any', '+all');
	my($planner) = new Hier::walk;
	#$planner->{fd} = \*FD;

	$planner->walk();
}

sub header {
	hier_detail(@_);
}

sub hier_detail {
	my($all, $tid, $ref, $planner) = @_;
	my($sid, $name, $cnt, $desc, $pri, $type, $note);
	my($per, $work, $start, $end, $done, $due, $ws);

	my $level = $planner->{level};
	my($indent) = '  ' x $level;
	

	$name = $ref->{task} || '';
	$pri  = $ref->{priority} || 3;
	$desc = summary_line($ref->{description}, '', 1);
	$note = summary_line($ref->{note}, '', 1);
	$type = $ref->{type} || '';
	$per  = $ref->{completed} ? 100 : 0;
	$due  = $ref->{due} || $Today;
	$done = pdate($ref->{completed});
	$start = pdate($ref->{created});

	$work  = 28800;			# number of hours
	$ws    = $due;
	$end   = $ws;

	my($fd) = $planner->{fd};

# <task id="1" name="Task 1" note="" work="28800" start="20090319T000000Z" end="20090319T170000Z" work-start="20090319T080000Z" percent-complete="0" priority="0" type="normal" scheduling="fixed-work">

	print $fd $indent, qq(<task id="$tid" name="$name" note="$note" work="$work" ) , 
		qq(start="$start" end="$end" work-start="$ws" ),
		qq(percent-complete="$per" priority="$pri" type="normal" scheduling="fixed-work">), "\n";

}

sub end_detail {
	my($all, $tid, $ref, $planner) = @_;
	my($fd) = $planner->{fd};
	my($indent) = $planner->indent();
	print {$fd} $indent, "</task>\n";
}

sub pdate {
	my($date) = @_;

	return $Today unless $date;

	$date =~ s/-//g;

	$date .= "T000000Z";

	return $date;
}

1;  # don't forget to return a true value from the file
