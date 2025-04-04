package GTD::Report::items;

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
	@EXPORT      = qw(&Report_items);
}

use GTD::Util;
use GTD::Meta;
use GTD::Format;
use GTD::Option;
use GTD::Sort;

sub Report_items {	#-- list titles for any filtered class (actions/projects etc)
	# everybody into the pool by name
	meta_filter('+any', '^title', 'item');

	my($name) = meta_desc(@_);
	if ($name) {
		my($want) = type_val($name);
		if ($want) {
			$want = 'p' if $want eq 's';
			list_items($want, $name);
			return;
		}
		print "**** Can't understand Type $name\n";
		return 1;
	}
	print "No items requested\n";
}

sub list_items {	#-- List projects with waiting-fors
	my($type, $typename) = @_;

	report_header($typename);

        my($tid, $title, $desc, @list);
        for my $ref (meta_matching_type($type)) {
##FILTER	next if $ref->filtered();

                push(@list, $ref);
        }
        for my $ref (sort_tasks @list) {
		display_task($ref, '');
        }
}

1;  # don't forget to return a true value from the file
