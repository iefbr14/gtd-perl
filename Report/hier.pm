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
use Hier::Color;
use Hier::Walk;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

my $Mask = 0;

sub Report_hier {	#-- Hiericial List of Values/Visions/Roles...
	meta_filter('+live', '^title', 'none');

	$Mask  = option('Mask');

	my($top) = 'm';
	my($depth) = 'p';
	for my $criteria (meta_argv(@_)) {
		if ($criteria =~ /^\d+$/) {
			$top = $criteria;
		} else {
			my($type) = type_val($criteria);
			if ($type) {
				$depth = $type;
			} else {
				die "unknown type $criteria\n";
			}
		}
	}

	my($walk) = new Hier::Walk();
	$walk->filter();
	$walk->set_depth($depth);

	bless $walk;	# take ownership and walk the tree

	$walk->{level} = 1 if $top ne 'm';
	$walk->walk($top);
}

sub hier_detail {
	my($self, $ref) = @_;

	my $level = $self->{level};

	my $tid  = $ref->get_tid();
	my $name = $ref->get_task() || '';

	if ($level == 0) {
		color($ref);
		print "===== $tid -- $name ====================";
		nl();
		return;
	}
	if ($level == 1) {
		color($ref);
		print "----- $tid -- $name --------------------";
		nl();
		return;
	}

	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority() || 3;
	my $desc = summary_line($ref->get_description(), '');
	my $done = $ref->get_completed() || '';

	color($ref);

	printf "%5s %3s ", $tid, $cnt;
	printf "%-15s", $ref->task_mask_disp() if $Mask;

	print "|  " x ($level-2), '+-', type_disp($ref). '-';
	if ($name eq $desc or $desc eq '') {
		printf "%.50s",  $name;
	} else {
		printf "%.50s",  $name . ': ' . $desc;
	}
	nl();
}
sub task_detail {
	return hier_detail(@_);

	my($self, $ref) = @_;

	my $level = $self->{level};

	my $tid  = $ref->get_tid();
	my $name = $ref->get_task() || '';
	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority() || 3;
	my $desc = summary_line($ref->get_description(), '');
	my $type = $ref->get_type() || '';
	my $done = $ref->get_completed() || '';

	color($ref);

	printf "%5s %3s ", $tid, $cnt;
	printf "%-15s", $ref->task_mask_disp() if $Mask;

	my($dots) = "..." x $level;
	substr($dots, 1, 6) = '(done)' if $done;
	print $dots, "...";
	if ($name eq $desc or $desc eq '') {
		printf "%.50s",  $name;
	} else {
		printf "%.50s",  $name . ': ' . $desc;
	}
	nl();
}

sub end_detail {
}

1;  # don't forget to return a true value from the file
