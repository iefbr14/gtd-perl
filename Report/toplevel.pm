package Hier::Report::toplevel;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_toplevel);
}

use Hier::Report::list;

sub Report_toplevel {	#-- List Values/Visions/Roles
	Report_list('Values');
	Report_list('Visions');
	Report_list('Goals');
}


1;  # don't forget to return a true value from the file
