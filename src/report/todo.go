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
	@EXPORT      = qw(&Report_todo);
}

use Hier::Util;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

sub Report_todo {	//-- List high priority next actions
	my($limit) = option('Limit', 10);

	gtd.Meta_filter('+active', '^priority', 'priority');
	my($title) = gtd.Meta_desc(@_) || 'ToDo Tasks';

	report_header($title);

	my($count) = 0;
	for my $ref (gtd.Meta_sorted('^pri')) {
		next unless $ref->is_task();	// only actions
//#FILTER	next if $ref->filtered();		// other filterings

		display_task($ref);

		last if ++$count >= $limit;
	}
}

1;  # don't forget to return a true value from the file
