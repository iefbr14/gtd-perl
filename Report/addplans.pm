package Hier::Report::addplans;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_addplans);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Filter;
use Hier::Format;
use Hier::Option;

my $Debug;

sub Report_addplans {	#-- add plan action items to unplaned projects
	meta_filter('+live', '^goaltask', 'simple');

	$Debug = option('Debug', 0);

	my($desc) = meta_desc(@ARGV);
	report_header('Projects needing planing', $desc);

	for my $ref (meta_matching_type('p')) {
		my($pid) = $ref->get_tid();

		my($work, $children) = count_children($ref);
		print "$pid: $children\n" if $Debug;

		next unless $work;

		display_rgpa($ref);
	}
}

1;  # don't forget to return a true value from the file
