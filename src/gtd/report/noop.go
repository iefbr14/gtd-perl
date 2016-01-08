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

import "gtd/meta"
import "gtd/option"

var report_debug = false

//-- No Operation
func Report_noop(args []string) {
	if report_debug {
		fmt.Printf("### Debug noop = %v", debug)
	}

	meta.Filter("+live", "^tid", "tid")

	//list := meta.Pick(args)
	_ = meta.Pick(args)

	//???	walk := gtd.Walk()
	//???	walk.Filter()

	if debug {
		fmt.Printf("noop: %#v\n", args)
	}
}
