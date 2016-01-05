package report

/*
NAME:

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

*/

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

use Hier::Util;
use Hier::Meta;

sub Report_hierlist {	#-- List all top level item (Project and above)
	my($tid, $pid, $pref, $cnt, $parent, $cat, $name, $desc);
	my(@row);

	meta_filter('+p:live', '^title', 'simple');
	meta_desc(@_);

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
		$name = $ref->get_title() || '';
		$desc = $ref->get_description() || '';

		$pref = $ref->get_parent();
		if (defined $pref) {
			$parent = $pref->get_title();
			$pid = $pref->get_tid();
		} else {
			$parent = 'orphined';
			$pid = '--';
		}

		write;
	}
}


1;  # don't forget to return a true value from the file
