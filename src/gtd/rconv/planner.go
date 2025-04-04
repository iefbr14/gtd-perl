package report

/*
NAME:

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

*/

import "gtd/meta"
import "gtd/task"
import "gtd/cct"

/*?
my $Today = `date +%04Y%02m%02dT080000Z`; chomp $Today

my %Pred
my $Pred_id = 0

my %Alloc_resource = ( 999 => "Drew")
my %Alloc_tasks = ()
?*/

//-- Create a planner file from gtd db
func Report_planner(args []string) {
	meta.Filter("+active", "^tid", "none")

	/*?
		my($criteria) = @_
		my($tid, $pri, $task, $cat, $ins, $due, $desc)
		my(@row)

		meta.Argv(args))

		w := meta.Walk(args)
		w.Detail = planner_detail
		w.Done   = planner_end

		w.Set_depth('a')
		w.Filter()

		planner_project()
		planner_calendar()

		print "<tasks>\n"

		w.Walk('m')

		print "</tasks>\n"

		planner_resource()
		planner_allocations()
		print "</project>\n"

	?*/
}

func planner_detail() { /*?
		my($planner, $ref) = @_
		my($sid, $name, $cnt, $desc, $pri, $type, $note)
		my($per, $work, $start, $end, $done, $due, $ws)

		my($tid) = t.Tid()


		my($indent) = indent($ref)
		my($resource) = $ref->Project()
		my($user) = $resource->resource()

		$name = xml(t.Title() || '')
		$pri  = t.Priority()
		$desc = xml(display.Summary(t.Description(), '', 1))
		$note = xml(display.Summary(t.Note(), '', 1))
		$type = t.Type() || ''
		$per  = t.Completed() ? 100 : 0
		$due  = t.Due() || $Today
		$done = pdate(t.Completed())
		$start = pdate(t.Created())

	//	if ($done && $done lt "2010-") {
	//		$planner->{want}{$tid} = 0
	//		return
	//	}

		// number of hours/days => min
		$work  = $resource->hours($ref) * 60
		$ws    = $due
		$end   = $ws

		my($fd) = $planner->{fd}

	// <task id="1" name="Task 1" note="" work="28800" start="20090319T000000Z" end="20090319T170000Z" work-start="20090319T080000Z" percent-complete="0" priority="0" type="normal" scheduling="fixed-work">

		print {$fd} $indent, qq(<task id="$tid" name="$name" note="$note" work="$work" ) ,
			qq(start="$start" end="$end" work-start="$ws" ),
			qq(percent-complete="$per" priority="$pri" type="normal" scheduling="fixed-work">), "\n"

		if ($type == 'a') {
			my($pred) = $Pred{$user} || ''
			//print "# $type $tid $user $pred\n"
			if ($pred) {
				++$Pred_id
				print {$fd}
					$indent, "  <predecessors>\n",
					$indent, "    <predecessor id=\"1\" predecessor-id=\"$pred\" type=\"FS\"/>\n",
					$indent, "  </predecessors>\n",
			}
			$Pred{$user} = $tid


			my($context) = t.Context()
			my($cid)
			if ($context) {
				my($cref) = Hier::CCT->use("Context")
				$cid = $cref->get($context)
				$Alloc_resource{$cid} = $context
			} else {
				$cid = 999
			}
			$Alloc_tasks{$tid} = $cid
		}
	?*/
}

func planner_end() { /*?
		my($planner, $ref) = @_

		my($tid) = t.Tid()
		return if $planner->{want}{$tid} == 0

		my($fd) = $planner->{fd}

		my($indent) = $planner->indent()
		print {$fd} $indent, "</task>\n"
	?*/
}

func pdate() { /*?
		my($date) = @_

		return $Today unless $date

		$date =~ s/-//g

		$date .= "T000000Z"

		return $date
	?*/
}

func xml() { /*?
		my($str) = @_

		return '' unless defined $str

		my %map = (
			'&" => "&amp;',
			'<" => "&gt;',
			'>" => "&lt;',
			'"" => "&dquote;',
			""" => "&quote;',
		)

		$str =~ s/[&<>'"]/ /g
		return $str
	?*/
}

func indent() { /*?
		my($ref) = @_

		my($level) = $ref->level() || 0

		return '' if $level <= 0

		return "  " x $level
	?*/
}

func planner_project() { /*?
		print <<"EOF"
	<?xml version="1.0"?>
	<project name="" company="" manager="" phase="" project-start="$Today" mrproject-version="2" calendar="1">
	  <properties/>
	  <phases/>
	EOF
	?*/
}

func planner_calendar() { /*?
		print <<"EOF"
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
	?*/
}

func planner_resource() { /*?
		my($who)

		print "  <resource-groups/>\n"
		print "  <resources>\n"
		for my $id (sort {$a <=> $b } keys %Alloc_resource) {
			$who = $Alloc_resource{$id}
			print qq(    <resource id="$id" name="$who" short-name="" type="1" units="0" email="" note="" std-rate="0"/>\n)
		}
		print "  </resources>\n"
	?*/
}

func planner_allocations() { /*?
		my($who)

		print "  <allocations>\n"
		for my $id (sort {$a <=> $b } keys %Alloc_tasks) {
			$who = $Alloc_tasks{$id}
			print qq(    <allocation task-id="$id" resource-id="$who" units="100"/>\n)
		}
		print "  </allocations>\n"
	?*/
}
