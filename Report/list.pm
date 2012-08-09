package Hier::Report::list;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_list);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;

sub Report_list {	#-- list titles for any filtered class (actions/projects etc)
	meta_filter('+active', '^title', 'title');

	my($title) = join(' ', @_);

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		print "No items requested\n";
	}
	report_header('List', $title);

	for my $ref (sort_tasks @list) {
		display_task($ref);
	}
}


1;  # don't forget to return a true value from the file
