# $Id: PrintTicket.pm,v 1.3 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::PrintTicket;

 $id = function(arg);

=head1 DESCRIPTION

Needs to be written

=cut


package Cos::PrintTicket;

use strict;
#use warnings;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&PrintTicket);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw($Var1 %Hashit &func3);
}
use vars @EXPORT_OK;


use Cos::StoreConfig;

sub PrintTicket {
	my($req) = @_;

	my($raw_store) = $req->{raw_store};

	my $storeid    = getStoreId($raw_store);
	my $store_name = getStoreName($raw_store);

	my($seperator) = "-" x 80;
	my($strdate);

 	printf "                   PICK TICKET FOR: %s\n",
		"CC Systems - Live Normal";

	if ($req->{redo_code}) {
		print $seperator, "\n";

		printf "\n  REDO code(%d)   reason(%s)\n\n",
			$req->{store}, $req->{redo_string};

		print $seperator, "\n";
	}

	print $seperator, "\n";
	printf "Transmission # %03d-%03d         Cust id %6s   %-25s\n",
		$req->{store}, $req->{seq_no}, $storeid, $store_name;

	print $seperator, "\n";

#	$strdate = mdy($req->{date_ord});
	printf "Patient: %-22sDate ordered:  %-10s Retail order# %4d\n",
		$req->{patient}, $req->{date_ord}, $req->{invc_no};

	print $seperator, "\n";

	$strdate = $req->{date_prom} . ' ' . $req->{time_prom};

	printf "Tray #  %-5s                  Date promised: %-10s Dispenser: %s\n",
		$req->{tray_no}, $strdate, $req->{dispenser};

	print $seperator, "\n";

	printf "Frame - Key: %-15s Name:%-25s  Color:%-10s\n",
		$req->{frame_key}, $req->{frame_desc}, $req->{frame_color};

	print "\n";

	printf "%s\n","Eye   -  Status       Mount     Size   Temple  A meas.  B meas.  E.D.  D.B.L.";

	print $seperator, "\n";

	printf " %-1s      %-11s  %-10s %2d/%2d   %3d     %2.1f     %2.1f    %2.1f   %2.1f\n",
		$req->{pair},
		$req->{status},
		$req->{mount},
		$req->{eye_size},
		$req->{bridge},
		$req->{temple},
		$req->{a_meas},
		$req->{b_meas},
		$req->{ed_meas},
		$req->{dbl_meas};

	print "\n";
	print $seperator, "\n";

	printf "Rx    - Mat: %-15s Type: %03d(%-10s)  Size: %02d  Color: %-12s\n",
		$req->{mat},
		$req->{lens_type} || 0, 
		$req->{l_type},
		$req->{blank_size} || 0,
		$req->{color};

	print "Eye   -    Sph      Cyl    Axis   BC    Add     Seg    Boc     Pd    Npd    Mono\n";
	print $seperator, "\n";

	printf "Right -   %02d.%02d%1s   %02d.%02d%1s   %3d   %+2d   %02d.%02d%1s   %02d.%01d   %02d.%02d  %02d.%01d   %02d.%01d   %02.1f\n\n",
		$req->{r_sph_int},
		$req->{r_sph_frac},
		$req->{r_sph_sign},
		$req->{r_cyl_int},
		$req->{r_cyl_frac},
		$req->{r_cyl_sign},
		$req->{r_axis},
		$req->{r_bc},
	    	$req->{r_add_int},
		$req->{r_add_frac},
		$req->{r_add_sign},
		$req->{r_seg1},
		$req->{r_seg2},
		$req->{r_boc1},
		$req->{r_boc2},
		$req->{r_pd1},
		$req->{r_pd2},
	   	$req->{r_npd1},
		$req->{r_npd2},
		$req->{r_mono};

	printf "Left  -   %02d.%02d%1s   %02d.%02d%1s   %3d   %+2d   %02d.%02d%1s   %02d.%01d   %02d.%02d  %02d.%01d   %02d.%01d   %02.1f\n",
		$req->{l_sph_int},
		$req->{l_sph_frac},
		$req->{l_sph_sign},
		$req->{l_cyl_int},
		$req->{l_cyl_frac},
		$req->{l_cyl_sign},
		$req->{l_axis},
		$req->{l_bc},
	    	$req->{l_add_int},
		$req->{l_add_frac},
		$req->{l_add_sign},
		$req->{l_seg1},
		$req->{l_seg2},
		$req->{l_boc1},
		$req->{l_boc2},
		$req->{l_pd1},
		$req->{l_pd2},
	   	$req->{l_npd1},
		$req->{l_npd2},
		$req->{l_mono};

	print $seperator, "\n";
	print "\n";

	printf"Right prism:  %-15sLeft prism:  %-15sTint: %-2s%% %10s\n",
		$req->{r_prism},
		$req->{l_prism},
		$req->{tint_pct},
		$req->{tint_desc};

	printf "Special Instructions:\n%-75s\n", $req->{spec_inst1};
	printf  "%-74s\n", $req->{spec_inst2};

	printf "%-35s\n\n\n\n\n\n\n\n", $req->{spec_inst3};
	if ($req->{pof}) {
	    printf "    %s %s\n\n",
			  "PATIENTS OWN FRAME", $req->{dress_safety};
	} else {
	    printf "    %s\n\n", $req->{dress_safety};
	}
	
	printf "%s\n", "Misc. Key           Description";

	print $seperator, "\n";
	if ($req->{misc_1} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_1},$req->{misc_1_desc};
	}
	if ($req->{misc_2} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_2},$req->{misc_2_desc};
	}
	if ($req->{misc_3} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_3},$req->{misc_3_desc};
	}
	if ($req->{misc_4} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_4},$req->{misc_4_desc};
	}
	if ($req->{misc_5} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_5},$req->{misc_5_desc};
	}
	if ($req->{misc_6} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_6},$req->{misc_6_desc};
	}
	if ($req->{misc_7} ) {
	    printf "%-15s     %-25s\n",
			  $req->{misc_7},$req->{misc_7_desc};
	}
}

sub mdy {
	my($date) = @_;

	my($y, $m, $d) = split('-', $date);

	return "$m-$d-$y";
}

1;
