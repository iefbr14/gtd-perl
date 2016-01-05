package report

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
	@EXPORT      = qw(&Report_search);
}

use Hier::Util;
use Hier::Format;
use Hier::Meta;

sub Report_search {	#-- Search for items
	my($found) = 0;

	my($tid, $title, $type);

	meta_filter('+all', '^title', 'simple');
	meta_desc(@_);
# type filtering?
#	if ($name) {
#		my($want) = type_val($name);
#		if ($want) {
#			$want = 's' if $type eq 'p';
#			list_desc($want, $name);
#			return;
#		}
#		die "**** Can't understand Type $name\n";
#	}
#	print "No items requested\n";

	for my $name (split(/,/, $_[0])) {
		for my $ref (meta_sorted()) {
			next unless match_desc($ref, $name);
			
			display_task($ref);
			$found = 1;
		}
	}
	return ($found ? 0 : 1);
}

sub match_desc {
	my($ref, $desc) = @_;

	return 1 if $ref->get_title() =~ m/$desc/i;
	return 1 if $ref->get_description() =~ m/$desc/i;
	return 1 if $ref->get_note() =~ m/$desc/i;
	return 0;
}

1;  # don't forget to return a true value from the file
