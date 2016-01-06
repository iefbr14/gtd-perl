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
	@EXPORT      = qw(&Report_hier);
}

use Hier::Util;
use Hier::Color;
use Hier::Walk;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

my $Mask = 0;

sub Report_hier {	//-- Hiericial List of Values/Visions/Roles...
	gtd.Meta_filter('+active', '^title', 'hier');

	$Mask  = option('Mask');

	my(@top);
	my($depth) = '';
	for my $criteria (gtd.Meta_argv(@_)) {
		if ($criteria =~ /^\d+$/) {
			push(@top, $criteria);
		} else {
			my($type) = type_val($criteria);
			if ($type) {
				$depth = $type;
			} else {
				panic("unknown type $criteria\n");
			}
		}
	}
	if (@top == 0) {
		my $parent = option('Current');
		if ($parent) {
			@top = ( $parent );
		} else {
			@top = ( 'm' );
		}
	}

	for my $top (@top) {
		my($walk) = new Hier::Walk(
			detail => \&hier_detail,
			done   => \&end_detail,
		);
		$walk->filter();
		$walk->set_depth(map_depth($top, $depth));

		$walk->walk($top);
	}
}

sub map_depth {
	my($ref, $depth) = @_;

	return $depth if $depth;

	my($type) = 'm';

	// not a reference to a task
	if (!ref $ref) {
		// is it a tid?
		if ($ref =~ /^\d+$/) {
			$ref = Hier::Tasks::find($ref);
			$type = $ref->get_type();
		} else {
			// use the type that was pass
			$type = $ref;
		}
	}

	return 'a' if $type eq 'p';
	return 'p' if $type eq 'g';
	return 'g' if $type eq 'o'; # o == ROLE
	return 'o';
}

sub hier_detail {
//	hier_detail_old(@_); # return;

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
