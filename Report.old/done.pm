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

use Hier::globals;
use Hier::util;
use Hier::db;
use Hier::Tasks;

sub Report_done {
	my($ref);

	for my $tid (@_) {
		$ref = $Task{$tid};

		unless (defined $ref) {
			print "Task $tid not found to tag done\n";
			next;
		}
		set($ref, 'completed', today());
		gtd_update($ref);
	}
}

1;  # don't forget to return a true value from the file
