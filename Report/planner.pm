package Hier::Report::planner;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter Hier::Walk);
	@EXPORT      = qw(&Report_planner);
}

use Hier::util;
use Hier::Walk;
use Hier::Resource;
use Hier::Tasks;

my $Today = `date +%04Y%02m%02dT080000Z`; chomp $Today;

my %Pred;
my $Pred_id = 0;

sub Report_planner {	#-- Hiericial List of Values/Visions/Roles...
	my($criteria) = @_;
	my($tid, $pri, $task, $cat, $ins, $due, $desc);
	my(@row);

	add_filters('+any', '+all');
	my($planner) = new Hier::Walk;
	$planner->set_depth('a');
	$planner->filter();

	bless $planner;
	print "<tasks>\n";
	$planner->walk();
	print "</tasks>\n";
}

sub header {
	my($self) = shift @_;

	$self->detail(@_);
}

sub task_detail {
	hier_detail(@_);
	end_detail(@_);
}

sub hier_detail {
	my($planner, $ref) = @_;
	my($sid, $name, $cnt, $desc, $pri, $type, $note);
	my($per, $work, $start, $end, $done, $due, $ws);

	my($tid) = $ref->get_tid();


	my($indent) = $planner->indent();
	my($resource) = new Hier::Resource($ref);
	my($role) = $resource->resource($ref);
	

	$name = xml($ref->get_task() || '');
	$pri  = $ref->get_priority() || 3;
	$desc = xml(summary_line($ref->get_description(), '', 1));
	$note = xml(summary_line($ref->get_note(), '', 1));
	$type = $ref->get_type() || '';
	$per  = $ref->get_completed() ? 100 : 0;
	$due  = $ref->get_due() || $Today;
	$done = pdate($ref->get_completed());
	$start = pdate($ref->get_created());

	if ($done && $done lt '2010-') {
		$planner->{want}{$tid} = 0;
		return;
	}

	my($effort) = $resource->effort($ref);
	$work  = fix_effort($effort); # number of hours/days => min
	$ws    = $due;
	$end   = $ws;

	my($fd) = $planner->{fd};

# <task id="1" name="Task 1" note="" work="28800" start="20090319T000000Z" end="20090319T170000Z" work-start="20090319T080000Z" percent-complete="0" priority="0" type="normal" scheduling="fixed-work">

	print {$fd} $indent, qq(<task id="$tid" name="$name" note="$note" work="$work" ) , 
		qq(start="$start" end="$end" work-start="$ws" ),
		qq(percent-complete="$per" priority="$pri" type="normal" scheduling="fixed-work">), "\n";

	if ($type eq 'a') {
		my($pred) = $Pred{$role} || '';
		#print "# $type $tid $role $pred\n";
		if ($pred) {
			++$Pred_id;
			print {$fd}
				$indent, "  <predecessors>\n",
				$indent, "    <predecessor id=\"1\" predecessor-id=\"$pred\" type=\"FS\"/>\n",
				$indent, "  </predecessors>\n",
		}
		$Pred{$role} = $tid;
	}
}

sub end_detail {
	my($planner, $ref) = @_;

	my($tid) = $ref->get_tid();
	return if $planner->{want}{$tid} == 0;

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

sub xml {
	my($str) = @_;

	return '' unless defined $str;

	my %map = (
		'&' => '&amp;',
		'<' => '&gt;',
		'>' => '&lt;',
		'"' => '&dquote;',
		"'" => '&quote;',
	);

	$str =~ s/[&<>'"]/ /g;
	return $str;
}

sub indent {
	my($planner) = @_;

	my($level) = $planner->{level} || 0;

	return '' if $level <= 0;

	return '  ' x $level;
}

sub fix_effort {
	my($effort) = @_;

	return 0 unless $effort;

	if ($effort =~ m/^([.\d]+)h.*$/) {
		return $1 * 60*60;
	}
	if ($effort =~ m/^([.\d]+)d.*$/) {
		return $1 * 4*60*60;
	}
	return $effort;
}
1;  # don't forget to return a true value from the file
