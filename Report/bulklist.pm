package Hier::Report::bulklist;  # assumes Some/Module.pm

use strict;
use warnings;

use Hier::Tasks;

sub Report_bulklist { #-- Bulk List project for use in bulk load
	die;
}

=head1 Bulk List Syntax

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

use strict;
use warnings;

use Hier::Tasks;
use Hier::util;
use Hier::Walk;
use Hier::Resource;

my($Parent);
my($Type);

sub old_bulkload { 
	my($pid);
	my($action, $parents, $desc);

		next if /^#/;

		if (s/^(\d+)\t[A-Z]:\s*//) {
			&$action($parents, $desc);
			$action = \&add_update;
			$pid = $1;
			$parents->{me} = $pid;
			next;
		}
		if (s/^R:\s*//) {
			&$action($parents, $desc);

			$pid = find_hier('r', $_);
			die unless $pid;
			$parents->{r} = $pid;
			next;
		}
		if (s/^G:\s*//) {
			&$action($parents, $desc);

			$pid = find_hier('g', $_);
			if ($pid) {
				$action = \&add_nothing;
				$parents->{g} = $pid;
			} else {
				$action = \&add_goal;
			}
			next;
		}
		if (s/^[P]:\s*//) {
			&$action($parents, $desc);

			$action = \&add_project;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		if (s/^\[_*\]\s*//) {
			&$action($parents, $desc);

			$action = \&add_action;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		$desc .= "\n" . $_;
	&$action($parents, $desc);
}

sub find_hier {
	my($type, $goal) = @_;

	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_type() eq $type;
		next unless $ref->get_task() eq $goal;

		return $ref->get_tid();
	}
	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_type() eq $type;
		next unless lc($ref->get_task()) eq lc($goal);

		return $ref->get_tid();
	}

	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_task() eq $goal;
	
		my($type) = $ref->get_type();
		my($tid) = $ref->get_tid();
		warn "Found: something close($type) $tid: $goal\n";
		return $tid;
	}
	die "Can't find a hier item for '$goal' let alone a $type.\n";
}

sub add_nothing {
	# do nothing
}

sub add_goal {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'r'};
	$Type = 'g';

	$tid = add_task($desc);
	print "Added goal $tid: $desc\n";

	$parents->{'g'} = $tid;
}

sub add_project {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'g'};
	$Type = 'p';

	$tid = add_task($desc);
	print "Added project $tid: $desc\n";

	$parents->{'p'} = $tid;
}

sub add_action {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;
	$Parent = $parents->{'p'};
	$Type = 'n';

	$tid = add_task($desc);
	print "Added task $tid: $desc\n";
}


sub _report_hier {	
	add_filters('+live');

	my($criteria) = meta_desc(@ARGV);

	my($walk) = new Hier::Walk();
	$walk->filter();

	if ($criteria) {
		my($type) = type_val($criteria);
		if ($type) {
			$walk->set_depth($type);
		} else {
			die "unknown type $criteria\n";
		}
	}
	$walk->walk();
}


sub _report_taskjuggler {	
	my(@criteria) = @_;
	my($tid, $task, $cat, $ins, $due, $desc);

	add_filters('+any', '+all', @criteria);
	my($planner) = new Hier::Walk;
	bless $planner;

	$planner->set_depth('a');
	$planner->filter();
	$planner->walk();
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

	if ($done && $done lt '2010-') {
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
	
#	print {$fd} $indent, qq(  start $start\n) if $start;
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


use Hier::util;
use Hier::Tasks;

sub _report_actions {	
	add_filters('+active', '+next');
	report_actions(1, 'Actions', meta_desc(@ARGV));
}

sub report_actions {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($tid, $pid, $pref, $proj, %active, $title);

	# find all projects (next actions?)
	for my $ref (Hier::Tasks::all()) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		$pref = $ref->get_parent();
		next unless defined $pref;

		next if $pref->filtered();

		$pid = $pref->get_tid();
		$active{$pid} = $pref;

		$tid = $ref->get_tid();
		$proj->{$pid}{$tid} = $ref;
	}

### format:
### 99	P:Title
### +	Description
### =	Outcome
### 222	[_] Action
### +	Description
### =	Outcome
	my($cols) = columns() - 2;
	my($gid, $gref);

	my($last_goal) = 0;
	for my $pref (sort by_task values %active) {
		next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = $pref->get_parent();
		$gid = $gref->get_tid();

		if ($last_goal != $gid) {
			print '#', "=" x $cols, "\n" if $last_goal;
			print "$gid:\tG:",$gref->get_task(),"\n";
			$last_goal = $gid;
		} 
		print "$pid:\tP:", $pref->get_title(),"\n";

		bulk_display('+', $pref->get_description());
		bulk_display('=', $pref->get_note());

		my $tasks = $proj->{$pid};

		for my $ref (sort by_task values %$tasks) {
			next if $ref->filtered();

			$tid = $ref->get_tid();
			$title = $ref->get_title();

			if ($ref->get_completed()) {
				print "$tid:\t     [X] $title\n";
				next;
			}
			if ($ref->get_later()) {
				print "$tid:\t     <_] $title\n";
				next;
			}
			if ($ref->get_isSomeday() eq 'y') {
				print "$tid:\t     [_> $title\n";
				next;
			}
			if ($ref->get_nextaction() eq 'y') {
				print "$tid:\t     [_] $title\n";
			} else {
				print "$tid:\t     [ ] $title\n";
			}
			bulk_display('+', $ref->get_description());
			bulk_display('=', $ref->get_note());
			print "\n";
		}
		print '#', "-" x $cols, "\n";
	}
}

sub by_task {
	return $a->get_title() cmp $b->get_title()
	||     $a->get_tid()   <=> $b->get_tid();
}

sub bulk_display {
	my($tag, $text) = @_;

	return unless defined $text;
	return if $text eq '';
	return if $text eq '-';

	for my $line (split("\n", $text)) {
		print "$tag\t$line\n";
	}
}

1;  # don't forget to return a true value from the file
