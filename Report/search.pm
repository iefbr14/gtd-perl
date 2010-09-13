package Hier::Report::search;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_search);
}

use Hier::utils;
use Hier::Tasks;

sub Report_search {	#-- Search for items
	my($found) = 0;

	add_filters('+live');
	meta_desc(@ARGV);
	for my $name (split(/,/, $ARGV[0])) {
		for my $ref (Hier::Tasks::hier()) {
			$tid = $ref->get_tid();

			next if $ref->filtered();
			next unless match_desc($ref, $name);
			
			print $tid, "\n";
			$found = 1;
		}
	}
	exit $found ? 0 : 1;
}
1;  # don't forget to return a true value from the file
