package Hier::Report::actions;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_actions report_actions);
}

use Hier::util;
use Hier::Tasks;
use Hier::Option;
use Hier::Filter;
use Hier::Sort;

my $Projects;
my %Active;

my %Want;

sub Report_actions {	#-- Detailed list of projects with (next) actions
	my($list) = option('List', 0);

	add_filters('+live');
	my($desc) = meta_desc(@ARGV);
	report_select($desc);
	if ($list) {
		report_list();
	} else {
		report_actions(1, 'Actions', $desc);
	}
}

sub report_select {
	my($top_name) = @_;

	my($select);
	my($tid, $pid, $pref);

	my($top) = 0;
	if ($top_name) {
		$top = find_in_hier($top_name);
	}

	# find all projects (next actions?)
	for my $ref (Hier::Tasks::selected()) {
		next unless $ref->is_ref_task();
		next if $top && !has_parent($ref, $top);

		next if $ref->filtered();

		$pref = $ref->get_parent();
		next unless defined $pref;

		next if $pref->filtered();

		$pid = $pref->get_tid();
		$Active{$pid} = $pref;

		$tid = $ref->get_tid();
		$Projects->{$pid}{$tid} = $ref;
	}
}

sub report_list {
	my($top_name) = @_;

	my($tid, $pid, $pref, $ref);

	my($limit) = option('Limit', 20);

### format:
### goal  proj_id  project action_id action hours
	my($cols) = columns() - 2;
	my($gid, $gref);
	my($rid, $rref);

	my($last_goal) = 0;
	my($last_proj) = 0;
	for my $pref (sort { by_goal($a, $b) } values %Active) {
		next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = get_goal($pref);
		$gid = $gref->get_tid();

		my $tasks = $Projects->{$pid};

		my($task_cnt) = 0;
		for my $ref (sort { by_task($a, $b) } values %$tasks) {
			next if $ref->filtered();

			$tid = $ref->get_tid();
			print join("\t", 
				$gref->get_title(), 
				$pid, $pref->get_title(),
				$tid, $ref->get_title(),
				$ref->get_effort()
				), "\n";
			$task_cnt++;
		}
		unless ($task_cnt) {
			print join("\t", 
				$gref->get_title(), 
				$pid, $pref->get_title(),
				), "\n";
		}
		last if $limit-- <= 0;
	}
}

sub report_actions {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($tid, $pid, $pref, $title);

### format:
### 99	P:Title
### +	Description
### =	Outcome
### 222	[_] Action
### +	Description
### =	Outcome
	my($cols) = columns() - 2;
	my($gid, $gref);
	my($rid, $rref);

	my($last_goal) = 0;
	my($last_proj) = 0;
	for my $pref (sort { by_goal($a, $b) } values %Active) {
		next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = get_goal($pref);
		$gid = $gref->get_tid();

		$rref = $gref->get_parent();
		$rid = $rref->get_tid();

		if ($last_goal != $gid) {
			print '#', "=" x $cols, "\n" if $last_goal;
			print "\t\tR $rid: ",$rref->get_task()," -- ";
			print "G $gid: ",$gref->get_task(),"\n\n";
			$last_goal = $gid;
		} elsif ($last_proj != $pid) {
			print '#', "-" x $cols, "\n";
			$last_proj = $pid;
		} 
		print "$pid:\t", type_disp($pref), ' ', $pref->get_title(),"\n";

		bulk_display('+', $pref->get_description());
		bulk_display('=', $pref->get_note());
		print "\n";

		my $tasks = $Projects->{$pid};

		for my $ref (sort { by_task($a, $b) } values %$tasks) {
			next if $ref->filtered();

			$tid = $ref->get_tid();
			$title = $ref->get_title();

			print "$tid:\t     ", type_disp($ref), " $title\n";
			bulk_display('+', $ref->get_description());
			bulk_display('=', $ref->get_note());
			print "\n";
		}
	}
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

# handle imbeded project and return first top level value as goal
sub get_goal {
	my($pref) = @_;

	my($gref) = $pref->get_parent();

	while ($gref->get_type() eq 'p') {
#print join(' ', "up:", $gref->get_tid(), $gref->get_title), "\n";
		$gref = $gref->get_parent();
	}
	return $gref;
}

sub find_in_hier {
	my($title) = @_;

	for my $ref (Hier::Tasks::selected()) {
		next unless $ref->is_ref_hier();
		next if $ref->get_title() ne $title;

		add_children($ref);
		###BUG### should walk down from here vi get_children
		###BUG### rather walk up in has_parent
		return $ref->get_tid();
	}
	die "Can't find hier $title\n";
	return 0;
}

sub add_children {
	my($ref) = @_;

	## print "w tid: ", $ref->get_tid, " ", $ref->get_title, "\n";
	$Want{$ref->get_tid()} = 1;
	foreach my $cref ($ref->get_children()) {
		add_children($cref);
	}
}

sub has_parent {
	my($ref, $top) = @_;

	my($tid) = $ref->get_tid();
	## print "o tid: ", $tid, " ", $ref->get_title, "\n" if $Want{$tid};
	return $Want{$tid};
}

1;  # don't forget to return a true value from the file
