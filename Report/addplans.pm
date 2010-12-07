package Hier::Report::addplans;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_addplans);
}

use Hier::util;
use Hier::Tasks;
use Hier::Filter;

sub Report_addplans {	#-- add plan action items to unplaned projects
	add_filters('+plan', '+live');
	report_addplans(1, 'Projects needing planing', meta_desc(@ARGV));
}

sub report_addplans {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($pid, $proj);

	my(%has_children);
	my(%want_child);

	# find all next actions and remember there projects
	for my $ref (Hier::Tasks::selected()) {
		next unless $ref->is_ref_task();
		next unless $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;

		$pid = $pref->get_tid();

		$has_children{$pid}++;
	}

	for my $ref (Hier::Tasks::matching_type('p')) {
		$pid = $ref->get_tid();

		next if $has_children{$pid};
		next if $ref->filtered($ref);

		$want_child{$pid} = $ref;
	}

### format:
### ==========================
### Value Vision Role
### -------------------------
### 99	Goal 999 Project
	my($cols) = columns() - 2;

	my($g_id) = 0;
	my($last_parent) = 0;
	my($g_ref);
	for my $ref (sort by_goal_task values %want_child) {
		$g_ref = $ref->get_parent();
		$g_id  = $g_ref->get_tid();

		if ($g_id != $last_parent) {
			print '#', "=" x $cols, "\n" if $last_parent;
			print "$g_id:\tG:", $g_ref->get_title(), "\n";
			$last_parent = $g_id;
		}

		print "$pid:\tP:", $ref->get_title(), "\n";

	}
}

sub by_goal_task {
	return $a->get_parent()->get_tid() <=> $b->get_parent()->get_tid()
	    or $a->get_title() cmp $b->get_title()
	    or $a->get_tid() <=> $b->get_tid();
}

1;  # don't forget to return a true value from the file
