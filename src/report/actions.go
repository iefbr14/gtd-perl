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

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_actions report_actions);
}

use Hier::Util;
use Hier::Meta;
use Hier::Option;
use Hier::Sort;
use Hier::Format;

my $Projects;
my %Active;

my %Want;

sub Report_actions {	//-- Detailed list of projects with (next) actions
	my($list) = option('List', 0);

	meta_filter('+a:next', '^focus', 'detail');

	my($desc) = meta_desc(@_);
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

	// find all projects (next actions?)
	for my $ref (meta_selected()) {
		next unless $ref->is_task();
		next if $top && !has_parent($ref, $top);

//#FILTER	next unless $ref->is_nextaction();
//#FILTER	next if $ref->filtered();

		$pref = $ref->get_parent();
		next unless defined $pref;
next unless $pref->is_active();

//#FILTER	next if $pref->filtered();

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

//## format:
//## goal  proj_id  project action_id action hours
	my($cols) = columns() - 2;
	my($gid, $gref);
	my($rid, $rref);

	my($last_goal) = 0;
	my($last_proj) = 0;
	for my $pref (sort_tasks values %Active) {
//#FILTER	next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = get_goal($pref);
		$gid = $gref->get_tid();

		my $tasks = $Projects->{$pid};

		my($task_cnt) = 0;
		for my $ref (sort_tasks values %$tasks) {
//#FILTER		next if $ref->filtered();

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

//## format:
//## 99	P:Title
//## +	Description
//## =	Outcome
//## 222	[_] Action
//## +	Description
//## =	Outcome
	my($cols) = columns() - 2;
	my($gid, $gref);
	my($rid, $rref);

	my($last_goal) = 0;
	my($last_proj) = 0;
	for my $pref (sort_tasks values %Active) {
//#FILTER	next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = get_goal($pref);
		next unless $gref;
		$gid = $gref->get_tid();

		$rref = $gref->get_parent();
		$rid = $rref->get_tid();

		if ($last_goal != $gid) {
			print '#', "=" x $cols, "\n" if $last_goal;
			print "\t\tR $rid: ",$rref->get_title()," -- ";
			print "G $gid: ",$gref->get_title(),"\n\n";
			$last_goal = $gid;
		} elsif ($last_proj != $pid) {
			print '#', "-" x $cols, "\n";
			$last_proj = $pid;
		} 

		display_task($pref);
		my $tasks = $Projects->{$pid};

		for my $ref (sort_tasks values %$tasks) {
			next if $ref->filtered();

			display_task($ref);
		}
	}
}

// handle imbeded project and return first top level value as goal
sub get_goal {
	my($pref) = @_;

	my($gref) = $pref->get_parent();

	unless ($gref) {
		warn "Parent of ", $pref->get_tid(), " is null\n";
		return;
	}

	while ($gref->get_type() eq 'p') {
//warn join(' ', "up:", $gref->get_tid(), $gref->get_title), "\n";
		$gref = $gref->get_parent();
	}
	return $gref;
}

sub find_in_hier {
	my($title) = @_;

	for my $ref (meta_selected()) {
		next unless $ref->is_hier();
		next if $ref->get_title() ne $title;

		add_children($ref);
		//##BUG### should walk down from here vi get_children
		//##BUG### rather walk up in has_parent
		return $ref->get_tid();
	}
	panic("Can't find hier $title\n");
	return 0;
}

sub add_children {
	my($ref) = @_;

	//# warn "w tid: ", $ref->get_tid, " ", $ref->get_title, "\n";
	$Want{$ref->get_tid()} = 1;
	foreach my $cref ($ref->get_children()) {
		add_children($cref);
	}
}

sub has_parent {
	my($ref, $top) = @_;

	my($tid) = $ref->get_tid();
	//# warn "o tid: ", $tid, " ", $ref->get_title, "\n" if $Want{$tid};
	return $Want{$tid};
}

1;  # don't forget to return a true value from the file
