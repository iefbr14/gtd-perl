package Hier::Report::hier;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_hier);
}

use Hier::util;
use Hier::Walk;
use Hier::Tasks;
use Hier::Option;
use Hier::Filter;

my $Mask = 0;

sub Report_hier {	#-- Hiericial List of Values/Visions/Roles...
	add_filters('+live');

	$Mask  = option('Mask');
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

	bless $walk;	# take ownership and walk the tree

	$walk->walk();
}

sub hier_header {
	my($walk, $ref) = @_;

	my($tid) = $ref->get_tid();
	my($task) = $ref->get_task();

	return unless $walk->{want}{$tid};

	print "===== $tid -- $task ====================\n";
	return;
}

sub hier_detail {
	my($self, $ref) = @_;

	my $level = $self->{level};

	if ($level == 0) {
		hier_header($self, $ref);
		return;
	}

	my $tid  = $ref->get_tid();
	my $name = $ref->get_task() || '';
	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority() || 3;
	my $desc = summary_line($ref->get_description(), '');
	my $type = $ref->get_type() || '';
	my $done = $ref->get_completed() || '';

	printf "%5s %3s ", $tid, $cnt;
	printf "%-15s", $ref->task_mask_disp() if $Mask;

	print "|  " x $level, "+-($type)-";
	if ($name eq $desc or $desc eq '') {
		printf "%.50s\n",  $name;
	} else {
		printf "%.50s\n",  $name . ': ' . $desc;
	}
}
sub task_detail {
	my($self, $ref) = @_;

	my $level = $self->{level};

	my $tid  = $ref->get_tid();
	my $name = $ref->get_task() || '';
	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority() || 3;
	my $desc = summary_line($ref->get_description(), '');
	my $type = $ref->get_type() || '';
	my $done = $ref->get_completed() || '';

	printf "%5s %3s ", $tid, $cnt;
	printf "%-15s", $ref->task_mask_disp() if $Mask;

	my($dots) = "..." x $level;
	substr($dots, 1, 6) = '(done)' if $done;
	print $dots, "...";
	if ($name eq $desc or $desc eq '') {
		printf "%.50s\n",  $name;
	} else {
		printf "%.50s\n",  $name . ': ' . $desc;
	}
}

sub end_detail {
}

1;  # don't forget to return a true value from the file
