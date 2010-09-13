package Hier::Report::purge;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_purge);
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

sub Report_purge {	#-- Hiericial List of Values/Visions/Roles...
die;
	#add_hier_filters('+all');
	#add_task_filters('+dead');
	add_filters('+all');

	my($criteria) = meta_desc(@ARGV);
	my(%Keys) = %Hier;

	my($walk) = new Hier::walk();
	bless $walk;
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

sub hier_detail {
}
sub task_detail {
}
###BUG### walk forward stopping on excludes
###BUG### walk backward keeping on includes

1;  # don't forget to return a true value from the file
