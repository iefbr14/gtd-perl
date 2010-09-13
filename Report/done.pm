package Hier::Report::done;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_done);
}

use Hier::util;
use Hier::Tasks;

sub Report_done {	#-- Tag listed projects/actions as done
	for my $tid (@_) {
		my $ref = Hier::Tasks::find($tid);

		unless (defined $ref) {
			print "Task $tid not found to tag done\n";
			next;
		}
		$ref->set_completed(today());
		$ref->update();
	}
}

1;  # don't forget to return a true value from the file
