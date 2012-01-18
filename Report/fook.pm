package Hier::Report::fook;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_fook);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Filter;
use Hier::Option;
use Hier::Format;

sub Report_fook {	#-- list titles for any filtered class (actions/projects etc)
	meta_filter('+/a:live', '^title', 'simple');

	my(@list) = meta_pick({'fook' => \&fook}, @_);
	if (@list == 0) {
		print "No items requested\n";
		exit 0;
	}
		
	report_header('fook');

	for my $ref (sort_tasks @list) {
		display_task($ref);
	}
}

sub fook {
	my($arg) = @_;

	print "Fooked! ($arg)\n";
}


1;  # don't forget to return a true value from the file
