
package Hier::Report::color;

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
	@EXPORT      = qw(&Report_color);
}

use Hier::util;
use Hier::Color;

sub Report_color {	#-- Detailed list of projects with (next) actions

	my(@bg) = qw(WHITE BK  RED  GREEN YELLOW  BLUE PURPLE  CYAN );
	my(@fg) = qw(
	BLACK  RED  GREEN BROWN  NAVY PURPLE  CYAN GREY
	SILVER PINK LIME  YELLOW BLUE MAGENTA AQUA WHITE
	NONE);

	for my $bg ('\fg/bg:', @bg) {
		printf "%-8s ", $bg;
	}
	print "\n";

	for my $fg (@fg) {
		printf "%-8s ", $fg;
		for my $bg (@bg) {
			print_color($fg, $bg);
			printf "%-5.5s/%.2s ", $fg,$bg;
		}
		print_color();
		print "\n";
	}
}

1;
