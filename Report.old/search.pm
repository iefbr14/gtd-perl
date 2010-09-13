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

use Hier::header;
use Hier::globals;
use Hier::Tasks;

sub Report_search {	#-- List Goals
	my($ref);
	my($found) = 0;

	add_filters('+hier', '+live');
	meta_desc(@ARGV);
	for my $name (split(/,/, $ARGV[0])) {
		for my $tid (keys %Hier) {
			$ref = $Hier{$tid};

			next if filtered($ref);
			next unless match_desc($ref, $name);
			
			detail(\%Hier, $tid, $ref, 0);
			$found = 1;
		}
	}
	exit $found ? 0 : 1;
}
1;  # don't forget to return a true value from the file
