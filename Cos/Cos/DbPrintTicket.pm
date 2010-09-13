# $Id: DbPrintTicket.pm,v 1.10 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::DbPrintTicket;

=head1 DESCRIPTION

Needs to be written.

=cut

package Cos::DbPrintTicket;

use strict;
#use warnings;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&PrintTicket);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

use Cos::StoreConfig;

sub print {
	my($req) = @_;

	my($raw_store) = $req->{field_acct_id};

	my $storeid    = getStoreId($raw_store);
	my $store_name = getStoreName($raw_store);

	my($seperator) = "-" x 80;
	my($strdate);

	print "~size 18\n";
 	printf "Order ID: %8s\n", $req->{orders_pending_id};

	print "~size 10\n";
	if ($req->{redo_code}) {
		print $seperator, "\n";

		printf "\n  REDO code(%d)   reason(%s)\n\n",
			$req->{store}, $req->{redo_string};

		print $seperator, "\n";
	}

	print $seperator, "\n";
	printf "Transmission # %03d-%03d         Cust id %6s   %-25s\n",
		substr($raw_store,3,3), $req->{seq_num}, $storeid, $store_name;
	# ***BUG*** substr above is WRONG

	print $seperator, "\n";

	$strdate = mdy($req->{created_date});
	printf "Patient: %-22s Date ordered:  %-10s\n",
		$req->{field_client_name}, $strdate;

	print $seperator, "\n";

	if ($strdate = $req->{promised_date}) {
		$strdate =~ s/(....)(..)(..)(..)(..)(..)/$1-$2-$3 $4-$5/;
	}

	printf "Tray #  %-6s                  Date promised: %-10s\n",
		$req->{tray_no}, $strdate;

	print $seperator, "\n";

	printf "Frame - Key: %-15s Name:%-25s  Color:%-10s\n",
		$req->{fs1_upc}, $req->{fs1_model}, $req->{fs1_color};

	print "\n";

	printf "%s\n","Eye   -  Status       Mount     Size   Temple  A meas.  B meas.  E.D.  D.B.L.";

	print $seperator, "\n";

	printf " %-1s      %-11s  %-10s %2s/%2s   %3s     %2.1f     %2.1f    %2.1f   %2.1f\n",
		$req->{pair} || '',
		$req->{fdSource},
		$req->{fp_mounting},
		$req->{fdEye},
		$req->{fdBridge},
		$req->{fdTemple},
		$req->{fdA} || 0,
		$req->{fdB} || 0,
		$req->{fdED} || 0,
		$req->{fdDBL} || 0;

	print "\n";
	print $seperator, "\n";

	printf "Rx    - Mat: %-15s Type: %03d(%-10s)  Size: %02d  Color: %-12s\n",
		$req->{lens_OD_Material},
		$req->{lens_OD_StyleCode} || 0, 
		$req->{lens_OS_Style},
		$req->{lens_OD_BlankSize} || 0,
		$req->{lens_OD_Color};


	print "Eye   -    Sph      Cyl    Axis   BC    Add     Seg    Boc      Pd      Npd\n";
	print $seperator, "\n";

	my($r_fpd, $r_npd, $l_fpd, $l_npd);

	if ($req->{lens_SV_MF} eq 'MON' or $req->{lens_SV_MF} eq 'BPD') {
		$r_fpd = $req->{rx_OD_Mono_PD};
		$r_npd = $req->{rx_OD_Near_PD};

		$l_fpd = $req->{rx_OS_Mono_PD};
		$l_npd = $req->{rx_OS_Near_PD};
	} else {
		my($diff) = ($req->{rx_OD_Far_PD} - $req->{rx_OD_Near_PD}) / 2;
		$r_fpd = $req->{rx_OD_Mono_PD};
		$r_npd = $req->{rx_OD_Mono_PD} - $diff;

		$l_fpd = $req->{rx_OS_Mono_PD};
		$l_npd = $req->{rx_OS_Mono_PD} - $diff;
	}

	printf "Right -   %6s   %6s   %3s   %2s   %6s   %5s   %5s  %5s   %5s\n\n",
		&ifs($req->{rx_OD_Sphere}),
		&ifs($req->{rx_OD_Cylinder}),
		$req->{rx_OD_Axis},
		&nochoose($req->{rx_OD_Special_Base_Curve}),
	    	&ifs($req->{rx_OD_Add}),
		&ifn($req->{rx_OD_Seg_Height}),
		&ifn($req->{rx_OD_OC_Height}),
		&ifn($r_fpd),
	   	&ifn($r_npd);

	printf "Left  -   %6s   %6s   %3s   %2s   %6s   %5s   %5s  %5s   %5s\n",
		&ifs($req->{rx_OS_Sphere}),
		&ifs($req->{rx_OS_Cylinder}),
		$req->{rx_OS_Axis},
		&nochoose($req->{rx_OS_Special_Base_Curve}),
	    	&ifs($req->{rx_OS_Add}),
		&ifn($req->{rx_OS_Seg_Height}),
		&ifn($req->{rx_OS_OC_Height}),
		&ifn($l_fpd),
	   	&ifn($l_npd);

	print $seperator, "\n";
	print "\n";

	my($l_prism) = 	$req->{rx_OS_Prism_Diopters} . " " .
		        $req->{rx_OS_Prism} . " " .
		        $req->{rx_OS_Prism_Angle_Val};

	my($l_prism2) = $req->{rx_OS_Prism2_Diopters} . " " .
		        $req->{rx_OS_Prism2};

	my($r_prism) = 	$req->{rx_OD_Prism_Diopters} . " " .
		        $req->{rx_OD_Prism} . " " .
		        $req->{rx_OD_Prism_Angle_Val};

	my($r_prism2) = $req->{rx_OD_Prism2_Diopters} . " " .
		        $req->{rx_OD_Prism2};

	$req->{tr_TintPerCent} =~ s/ *\%//;
	printf "Right prism:  %-15s %s\n", $r_prism, $r_prism2;
	printf "Left  prism:  %-15s %s\n", $l_prism, $l_prism2;
	printf "Tint: %-2s %% %10s\n",
		$req->{tr_TintPerCent},
		&nochoose($req->{tr_TintColor});

	my($spec1) = substr($req->{instText},0,75);
	my($spec2) = substr($req->{instText},75,75);
	my($spec3) = substr($req->{instText},150);
	printf "\nSpecial Instructions:\n%s\n%s\n%s\n\n\n\n\n",
		$spec1, $spec2, $spec3;

	if ($req->{pof}) {
	    printf "    %s %s\n\n",
			  "PATIENTS OWN FRAME", $req->{fp_dress};
	} else {
	    printf "    %s\n\n", $req->{fp_dress};
	}
	
	printf "%s\n", "Misc. Key           Description";

	print $seperator, "\n";
	if ($req->{tr_Other1_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Other1_code},$req->{tr_Other1};
	}
	if ($req->{tr_Other2_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Other2_code},$req->{tr_Other2};
	}
	if ($req->{tr_Other3_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Other3_code},$req->{tr_Other3};
	}
	if ($req->{tr_Treatment_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Treatment_code},$req->{tr_Treatment};
	}
	if ($req->{tr_Tinting_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Tinting_code},$req->{tr_Tinting};
	}
	if ($req->{tr_AR_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_AR_code},$req->{tr_AntiReflective};
	}
	if ($req->{tr_Coating_code} ) {
	    printf "%-15s     %-25s\n",
			  $req->{tr_Coating_code},$req->{tr_Coating};
	}
}

sub mdy {
	my($date) = @_;

	$date =~ s/(....)(..)(..).*/$2-$3-$1/;
	return $date;
}

sub ifs {
	my($v) = @_;

	return '' unless defined $v;
	return '' if $v eq '';

	my($sign) = ' ';
	$sign = $1 if $v =~ s/^([+\-])//;
	
	# XX.XX+
	return sprintf("%05.2f", $v) . $sign;
}

sub ifn {
	my($v) = @_;

	# XX.XX
	return '' unless defined $v;
	return '' if $v eq '';

	return sprintf("%05.2f", $v+0.0);
}

sub nochoose {
	my($v) = @_;
	return '' if $v eq 'Choose';
	return $v;
}

1;
