package Hier::Report::hierlist;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_hierlist);
}

use Hier::util;
use Hier::Meta;
use Hier::Filter;

sub Report_hierlist {	#-- List all top level item (Project and above)
	my($tid, $pid, $pref, $cnt, $parent, $cat, $name, $desc);
	my(@row);

	meta_filter('+p:live', '^title', 'simple');
	meta_desc(@ARGV);

print <<"EOF";
-Gtd -Par Cnt Category  Parent       Name         Description
==== ==== === ========= ============ =========== ==============================
EOF

format HIER   =
@>>> @>>> @>> @<<<<<<<< @<<<<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid, $pid,$cnt,$cat,     $parent,     $name,      $desc
.
	$~ = "HIER";	# set STDOUT format name to HIER

	for my $ref (meta_sorted('^title')) {
		$tid = $ref->get_tid();

##FILTER	next if $ref->filtered();

		$cnt = $ref->count_children() || '';
		
		$cat = $ref->get_category() || '';
		$name = $ref->get_task() || '';
		$desc = $ref->get_description() || '';

		$pref = $ref->get_parent();
		if (defined $pref) {
			$parent = $pref->get_task();
			$pid = $pref->get_tid();
		} else {
			$parent = 'orphined';
			$pid = '--';
		}

		write;
	}
}


1;  # don't forget to return a true value from the file
