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

my %Goal;

sub Report_actions {	#-- List all projects with actions
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
	my($rid, $rref);

	my($last_goal) = 0;
	my($last_proj) = 0;
	for my $pref (sort by_task values %active) {
		next if $pref->filtered();

		$pid = $pref->get_tid();

		$gref = $pref->get_parent();
		$gid = $gref->get_tid();

		$rref = $gref->get_parent();
		$rid = $rref->get_tid();

		if ($last_goal != $gid) {
			print '#', "=" x $cols, "\n" if $last_goal;
			print "\t\tR $rid: ",$rref->get_task()," -- ";
			print "G $gid: ",$gref->get_task(),"\n";
			$last_goal = $gid;
		} elsif ($last_proj != $pid) {
			print '#', "-" x $cols, "\n";
			$last_proj = $pid;
		} 
		print "$pid:\t", type_disp($pref), ' ', $pref->get_title(),"\n";

		bulk_display('+', $pref->get_description());
		bulk_display('=', $pref->get_note());

		my $tasks = $proj->{$pid};

		for my $ref (sort by_task values %$tasks) {
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

sub by_task {
	return sort_goal($a) cmp sort_goal($b);
}

sub sort_goal {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	return $Goal{$tid} if defined $Goal{$tid};

	my($pref) = $ref->get_parent();
	my($gref) = $pref->get_parent();

	$Goal{$tid} = join("\0", 
		$gref->get_title(), $gref->get_tid(),
		$pref->get_title(), $pref->get_tid(),
		$ref->get_title(), $tid);

	return $Goal{$tid};
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
