package Hier::Report::planner;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_planner);
}

use Hier::util;
use Hier::Walk;
use Hier::Resource;
use Hier::Meta;
use Hier::CCT;
use Hier::Filter;

my $Today = `date +%04Y%02m%02dT080000Z`; chomp $Today;

my %Pred;
my $Pred_id = 0;

my %Alloc_resource = ( 999 => 'Drew');
my %Alloc_tasks = ();

sub Report_planner {	#-- Create a planner file from gtd db
	my($criteria) = @_;
	my($tid, $pri, $task, $cat, $ins, $due, $desc);
	my(@row);

	meta_filter('+all', '^tid', 'none');
	meta_argv(@ARGV);
	my($planner) = new Hier::Walk;
	$planner->set_depth('a');
	$planner->filter();

	planner_project();
	planner_calendar();

	bless $planner;
	print "<tasks>\n";
	$planner->walk('m');
	print "</tasks>\n";

	planner_resource();
	planner_allocations();
	print "</project>\n";

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

#	if ($done && $done lt '2010-') {
#		$planner->{want}{$tid} = 0;
#		return;
#	}

	# number of hours/days => min
	$work  = $resource->hours($ref) * 60;
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
		
	
		my($context) = $ref->get_context();
		my($cid);
		if ($context) {
			my($cref) = Hier::CCT->use('Context');
			$cid = $cref->get($context);
			$Alloc_resource{$cid} = $context;
		} else {
			$cid = 999;
		}
		$Alloc_tasks{$tid} = $cid;
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


sub planner_project() {
	print <<"EOF";
<?xml version="1.0"?>
<project name="" company="" manager="" phase="" project-start="$Today" mrproject-version="2" calendar="1">
  <properties/>
  <phases/>
EOF
}

sub planner_calendar() {
	print <<"EOF";
  <calendars>
    <day-types>
      <day-type id="0" name="Working" description="A default working day"/>
      <day-type id="1" name="Nonworking" description="A default non working day"/>
      <day-type id="2" name="Use base" description="Use day from base calendar"/>
    </day-types>
    <calendar id="1" name="Default">
      <default-week mon="0" tue="0" wed="0" thu="0" fri="0" sat="1" sun="1"/>
      <overridden-day-types>
        <overridden-day-type id="0">
          <interval start="0800" end="1200"/>
          <interval start="1300" end="1700"/>
        </overridden-day-type>
      </overridden-day-types>
      <days/>
    </calendar>
  </calendars>
EOF
}

sub planner_resource() {
	my($who);

	print "  <resource-groups/>\n";
	print "  <resources>\n";
	foreach my $id (sort {$a <=> $b } keys %Alloc_resource) {
		$who = $Alloc_resource{$id};
		print qq(    <resource id="$id" name="$who" short-name="" type="1" units="0" email="" note="" std-rate="0"/>\n);
	}
	print "  </resources>\n";
}

sub planner_allocations() {
	my($who);

	print "  <allocations>\n";
	foreach my $id (sort {$a <=> $b } keys %Alloc_tasks) {
		$who = $Alloc_tasks{$id};
		print qq(    <allocation task-id="$id" resource-id="$who" units="100"/>\n);
	}
	print "  </allocations>\n";
}

1;  # don't forget to return a true value from the file
