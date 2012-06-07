package Hier::Report::todo;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_todo);
}

use Hier::util;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

sub Report_todo {	#-- List high priority next actions
	my($limit) = option('Limit', 10);
	my($list)  = option('List', 0);

	meta_filter('+live', '^priority', 'priority');
	my($title) = meta_desc(@ARGV) || 'ToDo Tasks';

	report_header($title);

	my($count) = 0;
	for my $ref (meta_sorted('^pri')) {
		next unless $ref->is_task();	# only actions
##FILTER	next if $ref->filtered();		# other filterings

		display_task($ref);

		last if ++$count >= $limit;
	}
}

1;  # don't forget to return a true value from the file
