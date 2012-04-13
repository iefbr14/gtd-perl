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
use Hier::Format;

sub Report_tasks {	#-- quick List by various methods
	meta_filter('+a:live', 'title', 'task');	# Actions
	list_tasks('Actions', meta_desc(@ARGV));
}

sub list_tasks {
	my($head, $desc) = @_;

	report_header($head, $desc);

	# find all projects (next actions?)
	for my $ref (meta_selected()) {
		next unless $ref->is_task();
		next if $ref->filtered();

		display_task($ref);
	}
}


1;  # don't forget to return a true value from the file
