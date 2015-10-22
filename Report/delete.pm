package Hier::Report::delete;

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


use Hier::Meta;

sub Report_delete {	#-- Delete listed actions/projects (will orphine items)
	my($ref, $tid);

	foreach my $task (@_) {
		$ref = meta_find($task);

		unless (defined $ref) {
			print "Task $task doesn't exists\n";
			next;
		}

		for my $child ($ref->get_children) {
			die "Delete ", $child->get_tid(), " first\n";
		}

		$ref->delete();
		print "Task $task deleted\n";
	}
}

1;  # don't forget to return a true value from the file
