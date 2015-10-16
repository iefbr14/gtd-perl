
package Hier::Report::color;

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

	my(@bg) = qw(WHITE BK  RED  GREEN YELLOW  BLUE PURPLE  CYAN GRAY );
	my(@fg) = qw(
	BLACK  RED  GREEN BROWN  NAVY PURPLE  CYAN GREY
	SILVER PINK LIME  YELLOW BLUE MAGENTA AQUA WHITE
	NONE);

	for my $bg ('fg', @bg) {
		printf "%-7s ", $bg;
	}
	print "\n";

	for my $fg (@fg) {
		for my $bg (@bg) {
			print_color($fg, $bg);
			printf "%-4.4s/%.2s ", $fg,$bg;
		}
		print_color();
		print "\n";
	}
}

1;
