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
use Hier::Meta;
use Hier::Sort;
use Hier::Filter;
use Hier::Format;
use Hier::Option;

sub Report_addplans {	#-- add plan action items to unplaned projects
	report_addplans(1, 'Projects needing planing', meta_desc(@ARGV));
}

sub report_addplans {
	my($all, $head, $desc) = @_;

	meta_filter('+p:plan', '^focus', 'simple');

	report_header($head, $desc);

	my($proj);

	my(%has_children);
	my(%want_child);

	# find all next actions and remember there projects
	for my $ref (meta_selected()) {
		next unless $ref->is_task();
##FILTER	next unless $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;

		my($pid) = $pref->get_tid();

		$has_children{$pid}++;
	}

	for my $ref (meta_matching_type('p')) {
		my($pid) = $ref->get_tid();

		next if $has_children{$pid};
##FILTER	next if $ref->filtered($ref);
		next if $ref->get_completed();

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
		my($pid) = $ref->get_tid();
		my($title) = $ref->get_tid();

		$g_ref = $ref->get_parent();
		unless ($g_ref) {
			warn "Parent of $pid ($title) is undefined!\n";
			next;
		}
		$g_id  = $g_ref->get_tid();

		if ($g_id != $last_parent) {
			print '#', "=" x $cols, "\n" if $last_parent;
			print type_disp($g_ref), " $g_id: ",
				$g_ref->get_title(), "\n";
			$last_parent = $g_id;
		}

		display_task($ref);
	}
}

1;  # don't forget to return a true value from the file
