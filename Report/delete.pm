package Hier::Report::delete;

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


use Hier::Tasks;

sub Report_delete {	#-- Delete listed actions/projects (will orphine items)
	my($ref, $tid);

	foreach my $task (@_) {
		$ref = Hier::Tasks::find($task);

		unless (defined $ref) {
			print "Task $task doesn't exists\n";
			next;
		}

		$ref->delete();
		print "Task $task deleted\n";
	}
}

1;  # don't forget to return a true value from the file
