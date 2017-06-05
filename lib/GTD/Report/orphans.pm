package GTD::Report::orphans;

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
	@EXPORT      = qw(&Report_orphans);
}

use GTD::Util;
use GTD::Meta;
use GTD::Sort;
use GTD::Format;

sub Report_orphans {	#-- list all items without a parent 
	meta_filter('+any', '^title', 'todo');

	my(@list) = meta_pick(@_);
	
	report_header('Orphans', @_);

	my($count) = 0;

	for my $ref (meta_selected()) {
		next if $ref->get_type eq 'm';	# Values never have parents
		next if $ref->get_type eq 'L';	# Lists never have parents
		next if $ref->get_type eq 'C';	# Checklists never have parents

		next if $ref->get_parent();	# Has a parent

		display_task($ref);
		++$count;
	}

	return $count > 0;
}


1;  # don't forget to return a true value from the file
