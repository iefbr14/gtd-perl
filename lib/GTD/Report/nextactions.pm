package GTD::Report::nextactions;

=head1 NAME

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

=cut

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

use GTD::Util;
use GTD::Meta;

sub Report_nextactions { #-- List next actions
	my($tid, $pid, $pref, $tic, $parent, $pic, $name, $desc);
	my(@row);

	meta_filter('+next', '^title', 'none');
	meta_desc(@_);

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

		$name = $ref->get_title() || '';
		$tic = action_disp($ref);

		$pref = $ref->get_parent();
#next unless $pref->is_nextaction();
		if (defined $pref) {
			$parent = $pref->get_title();
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
