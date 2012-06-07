package Hier::Report::nextactions;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_nextactions);
}

use Hier::util;
use Hier::Meta;
use Hier::Filter;

sub Report_nextactions { #-- List next actions
	my($tid, $pid, $pref, $tic, $parent, $pic, $name, $desc);
	my(@row);

	meta_filter('+next', '^title', 'none');
	meta_desc(@ARGV);

print <<"EOF";
-Par [-] Parent           -Tid [-] Next Action
==== === ================ ==== === ============================================ 
EOF

format HIER   =
@>>> @<< @<<<<<<<<<<<<<<< @>>> @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$pid, $pic, $parent,      $tid, $tic, $name,
.
	$~ = "HIER";	# set STDOUT format name to HIER

	for my $ref (meta_pick('actions')) {
		$tid = $ref->get_tid();
##FILTER	next unless $ref->is_nextaction();
##FILTER	next if $ref->filtered();

		$name = $ref->get_task() || '';
		$tic = action_disp($ref);

		$pref = $ref->get_parent();
#next unless $pref->is_nextaction();
		if (defined $pref) {
			$parent = $pref->get_task();
			$pid = $pref->get_tid();
		} else {
			$parent = '-orphined-';
			$pid = '--';
		}
		$pic = type_disp($pref);

		write;
	}
}


1;  # don't forget to return a true value from the file
