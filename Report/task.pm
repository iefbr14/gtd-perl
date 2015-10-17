package Hier::Report::task;

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
	@EXPORT      = qw( &Report_task );
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;

sub Report_task {	#-- quick List by various methods
	meta_filter('+g:live', '^title', 'task');	# Tasks filtered by goals

	my($title) = join(' ', @_);

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		meta_pick('actions');
	}
	report_header('Tasks', $title);

	for my $ref (sort_tasks @list) {
		display_task($ref);
	}
}

1;  # don't forget to return a true value from the file
