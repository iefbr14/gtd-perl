package Hier::Report::tasks;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_tasks );
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;

sub Report_tasks {	#-- quick List by various methods
	meta_filter('+g:live', '^title', 'task');	# Tasks filtered by goals

	my($title) = join(' ', @_);

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		meta_pick('actions');
	}
	report_header('Tasks', $title);

	for my $ref (sort_tasks @list) {
		display_task($ref);
	}
}

1;  # don't forget to return a true value from the file
