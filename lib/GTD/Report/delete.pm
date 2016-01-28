package GTD::Report::delete;

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
	@EXPORT      = qw(&Report_delete);
}


use GTD::Meta;

sub Report_delete {	#-- Delete listed actions/projects (will orphan items)
	my($ref);

	for my $tid (@_) {
		$ref = meta_find($tid);

		unless (defined $ref) {
			print "Task $tid doesn't exists\n";
			next;
		}

		for my $child ($ref->get_children) {
			die "Delete ", $child->get_tid(), " first\n";
		}

		$ref->delete();
		print "Task $tid deleted\n";
	}
}

sub delete_hier {
        for my $tid (@_) {
                my $ref = GTD::Tasks::find{$tid};
                if (defined $ref) {
                        warn "Category $tid deleted\n";

                        $ref->delete();

                } else {
                        warn "Category $tid not found\n";
                }
        }
}


1;  # don't forget to return a true value from the file
