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

use Hier::header;
use Hier::util;
use Hier::globals;
use Hier::Tasks;

sub Report_hierlist {	#-- List all top level item (Project and above)
	my($tid, $pid, $cnt, $parent, $cat, $name, $desc);
	my(@row);

	add_filters('+hier', '+live');
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

	my($ref);

	for my $id (sort { $a cmp $b } keys %Hier) {
		$tid = $id;
		$ref = $Hier{$tid};

		next if filtered($ref);

		$cnt = $ref->{_actions} || '';

		$pid = parent($ref);
		
		$cat = $ref->{category} || '';
		$name = $ref->{task} || '';
		$desc = $ref->{description} || '';

		if (defined $Hier{$pid}) {
			$parent = $Hier{$pid}->{task};
		} else {
			$parent = 'fook';
		}

		write;
	}
}


1;  # don't forget to return a true value from the file
