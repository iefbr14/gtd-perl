package Hier::Report::hier;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_hier);
}

use Hier::globals;
use Hier::walk;
use Hier::header;
use Hier::util;
use Hier::Tasks;

my %Depth = (
	'value'   => 1,
	'vision'  => 2,
	'role'    => 3,
	'goal'    => 4,
	'project' => 5,
	'action'  => 6,
);

sub Report_hier {	#-- Hiericial List of Values/Visions/Roles...
	add_filters('+hier', '+live');

	my($criteria) = meta_desc(@ARGV);
	my(%Keys) = %Hier;

	my($walk) = new Hier::walk();
	$walk->filter();

	if ($criteria) {
		my($depth) = $Depth{lc($criteria)};
		if ($depth) {
			$walk->{depth} = $depth;
		} else {
			die "unknown depth $criteria\n";
		}
	} else {
		$walk->{depth} = 5;
	}
	$walk->walk();
}

1;  # don't forget to return a true value from the file
