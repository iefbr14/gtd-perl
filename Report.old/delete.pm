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


use Hier::globals;
use Hier::Tasks;

sub Report_delete {
	my($ref, $tid);

	foreach my $task (@_) {
		$ref = $Task{$task};

		unless (defined $ref) {
			print "Task $task doesn't exists\n";
			next;
		}

		gtd_delete($ref);
		print "Task $task deleted (todo_id: $tid)\n";
	}
}

1;  # don't forget to return a true value from the file
