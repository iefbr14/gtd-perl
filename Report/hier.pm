package Hier::Report::hier;

=head1 NAME

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

=cut

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
	meta_filter('+active', '^title', 'hier');

	$Mask  = option('Mask');

	my(@top);
	my($depth) = 'p';
	for my $criteria (meta_argv(@_)) {
		if ($criteria =~ /^\d+$/) {
			push(@top, $criteria);
		} else {
			my($type) = type_val($criteria);
			if ($type) {
				$depth = $type;
			} else {
				die "unknown type $criteria\n";
			}
		}
	}
	if (@top == 0) {
		@top = ( 'm' );
	}

	for my $top (@top) {

		my($walk) = new Hier::Walk();
		$walk->filter();
		$walk->set_depth($depth);

		bless $walk;	# take ownership and walk the tree

		$walk->walk($top);
	}
}

sub hier_detail {
#	hier_detail_old(@_); # return;

	my($self, $ref) = @_;

	color_ref($ref);
	display_task($ref);
}

sub hier_detail_old {
	my($self, $ref) = @_;

	my $level = $ref->level();

	my $tid  = $ref->get_tid();
	my $name = $ref->get_title() || '';

	if ($level == 1) {
		color_ref($ref);
		print "===== $tid -- $name ====================";
		nl();
		return;
	}
	if ($level == 2) {
		color_ref($ref);
		print "----- $tid -- $name --------------------";
		nl();
		return;
	}

	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority();
	my $desc = summary_line($ref->get_description(), '');
	my $done = $ref->get_completed() || '';

	color_ref($ref);

	printf "%5s %3s ", $tid, $cnt;
	printf "%-15s", $ref->task_mask_disp() if $Mask;

	print "|  " x ($level-3), '+-', type_disp($ref). '-';
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
