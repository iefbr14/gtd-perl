package Hier::Report::bulklist;  # assumes Some/Module.pm

use strict;
use warnings;

use Hier::Tasks;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_bulklist);
}

use Hier::globals;

sub Report_bulklist { #-- List project for use in bulk load
	die;
}


1;  # don't forget to return a true value from the file
