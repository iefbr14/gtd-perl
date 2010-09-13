package Hier::Report::update;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_udpate);
}

use Hier::utils;
use Hier::Tasks;

sub Report_update {	#-- Command line update of an action/project
	my($task, $desc) = @_;

	my $ref = Hier::Tasks::find($task);
	unless (defined $ref) {
		print "Task $task not found to update\n";
		return;
	}

	my $val;

	if ($val = option('Category')) {
		$ref->set_category($val);
	}

	if ($val = option('Context')) {
		$ref->set_context($val);
	}

	if ($val = option('Timeframe')) {
		$ref->set_timeframe($val);
	}

	if ($val = option('Note')) {
		$ref->set_note($val):
	}
	if ($val = option('Priority')) {
		$ref->set_priority($val):
	}
	if ($val = option('Description')) {
		$ref->set_description($val):
	}

	$ref->update();
}

1;  # don't forget to return a true value from the file
