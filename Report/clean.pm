package Hier::Report::clean;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_clean);
}

use Hier::Tasks;

sub Report_clean {	#-- clean unused categories
	die "###ToDo -- write clean categories\n";

	my($done, $tickle);
	
	for my $ref (Hier::Tasks::all()) {
		$done = $ref->get_completed();
		if ($done) {
			# clean next action
			# clean tickles
		}
		if ($tickle) {
			# clean next action
			# clean tickles
		}
	}
}

1;  # don't forget to return a true value from the file
