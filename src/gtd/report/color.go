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

import "fmt"

import "gtd/color"
import "gtd/display"

//-- Detailed list of projects with (next) actions
func Report_color(args []string) int {
	bg_list := []string{
		"WHITE", "BK", "RED", "GREEN",
		"YELLOW", "BLUE", "PURPLE", "CYAN"}
	fg_list := []string{
		"BLACK", "RED", "GREEN", "BROWN",
		"NAVY", "PURPLE", "CYAN", "GREY",
		"SILVER", "PINK", "LIME", "YELLOW",
		"BLUE", "MAGENTA", "AQUA", "WHITE",
		"NONE"}

	col := display.Columns()
	wid := col/9 - 1
	sw := wid - 3 - 1
	w := fmt.Sprintf("%d", wid)

	//	if (report_debug) {
	//		my($use) = $wid*10;
	//		print "col: $col, wid: $wid, sw: $sw, use: $use\n";
	//		my($dash) = substr("----+----|"x20, 0, $wid*10-1);
	//		print "$dash\n";
	//	}

	// %-9.9s
	f := "%-" + w + "." + w + "s "

	title := fmt.Sprintf(f, "fg/bg:")
	for _, bg := range bg_list {
		title += fmt.Sprintf(f, bg)
	}

	//	title =  strings.Trim(title)
	fmt.Print(title)
	display.Nl()

	for _, fg := range fg_list {
		f := "%-" + w + "." + w + "s"
		fmt.Printf(f, fg)

		for _, bg := range bg_list {
			f := " %-" + w + "." + w + "s"
			var label string

			if len(fg) < sw {
				label = fmt.Sprintf(f, fg+"/"+bg)
			} else {
				label = fmt.Sprintf(f, fg[0:sw]+"/"+bg)
			}

			fmt.Print(color.FgBg(fg, bg), label)
		}
		display.Nl()
	}
	return 0
}
