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

use Hier::Util;
use Hier::Color;


//-- Detailed list of projects with (next) actions
func Report_color(args []string) {

	my(@bg) = qw(WHITE BK  RED  GREEN YELLOW  BLUE PURPLE  CYAN );
	my(@fg) = qw(
	BLACK  RED  GREEN BROWN  NAVY PURPLE  CYAN GREY
	SILVER PINK LIME  YELLOW BLUE MAGENTA AQUA WHITE
	NONE);

	my($col) = columns();
	my($wid) = int($col/9)-1;
	my($sw) = $wid - 3;

	if ($Debug) {
		my($use) = $wid*10;
		print "col: $col, wid: $wid, sw: $sw, use: $use\n";
		my($dash) = substr("----+----|"x20, 0, $wid*10-1);
		print "$dash\n";
	}

	my($title) = '';
	for my $bg ("\fg/bg:", @bg) {
		$title .= sprintf "%-${wid}.${wid}s ", $bg;
	}
	$title =~ s/ *$//;
	print $title; nl();

	for my $fg (@fg) {
		printf "%-${wid}.${wid}s", $fg;

		for my $bg (@bg) {
			my($label) = sprintf " %-${wid}.${wid}s",
				substr($fg,0,$sw).'/'.$bg;

			print_color($fg, $bg);
			print $label;
		}
		nl();
	}
}
