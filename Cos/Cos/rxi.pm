#!/usr/bin/perl -w

=head1 NAME

 use Cos::rxi

=head1 SYNOPIS

used to generate rxi files

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

=head1 SEE ALSO

=cut

package Cos::rxi;

use strict;

use Getopt::Std;
use DBI;
use Cos::Constants;
use Cos::Dbh;
use Math::Trig;

BEGIN {
        use Exporter   ();
        use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

        # set the version for version checking
        $VERSION     = 1.00;
        # if using RCS/CVS, this may be preferred
        $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

        @ISA         = qw(Exporter);
        @EXPORT      = qw(generate_rxi);
        %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

        # your exported package globals go here,
        # as well as any optionally exported functions
        @EXPORT_OK   = qw();
}
use vars @EXPORT_OK;


########################################################
#	create the rxi and oma files for an Innovations order
########################################################
sub generate_rxi {
	my($dir, $aOrder) = @_;
	
	my($FSC_FDM,$TRC);
	my $orderId  = $aOrder->{orders_pending_id};
	my $userId = $aOrder->{field_acct_id};
	my $labId  = $aOrder->{lab_id};
	my($trace) = $aOrder->{trace_file_data};
	my($base) = $dir.$aOrder->{field_acct_id}.'-'.$aOrder->{orders_pending_id}.'.';
	print "generate_rxi is Processing Order # $orderId, lab: $labId, user: $userId, base: $base\n";

	if (defined($trace) && length($trace) != 0) {
		t_write($base, $aOrder);
		$FSC_FDM = "FSC 1\n";
		$TRC = "TRC " . $aOrder->{field_acct_id} . '-' . $aOrder->{orders_pending_id}."\n";
	} else {
		$FSC_FDM = "FSC 2\nFDM $aOrder->{fdA} $aOrder->{fdB} $aOrder->{fdED} 225.00 $aOrder->{fdDBL}\n";
		$TRC = "TRC \n";
	}

	my($rxifile) = $base.'$RX';
	open(FH, "> $base".'$RX'."\0") or die "Can't create $base ($!)\n";
	print FH "ACT " . $aOrder->{field_acct_id}."\n";
	print FH "RXN " . $aOrder->{orders_pending_id}."\n";
	print FH $TRC;
	print FH "PTN " . $aOrder->{field_client_name}."\n";
	if ($aOrder->{lens_Pair} == "1") {
		print FH "LNS  0 1\n";
	} elsif ($aOrder->{lens_Pair} == "2") {
		print FH "LNS  1 0\n";
	} else {
		print FH "LNS  1 1\n";
	}
	my $lensAliasValue =  lensAlias($aOrder->{lens_OD_MaterCode},
									 $aOrder->{lens_OD_StyleCode},
									 $aOrder->{lens_OD_ColorCode},
									 $aOrder->{lens_OS_MaterCode},
									 $aOrder->{lens_OS_StyleCode},
									 $aOrder->{lens_OS_ColorCode})."\n";
	print FH "LAS $lensAliasValue";
	print FH "DBL " . $aOrder->{fdDBL}."\n";
	print FH $FSC_FDM;								# diameter orders will send 6 and a UBS
	my $frameDesc = $aOrder->{frame_desc} || "0";
	if ($frameDesc =~ /(\d+)$/ ) {
		print FH "FTP $1\n";
	} else {
		print FH "FTP 0\n";
	}
	print FH "SPH " . $aOrder->{rx_OD_Sphere} . '  ' . $aOrder->{rx_OS_Sphere}."\n";
	print_if(\*FH, 'CYL ', $aOrder->{rx_OD_Cylinder}, $aOrder->{rx_OS_Cylinder});
	print_if(\*FH, 'AXS ', $aOrder->{rx_OD_Axis}, $aOrder->{rx_OS_Axis});
	print_if(\*FH, 'ADD ', $aOrder->{rx_OD_Add}, $aOrder->{rx_OS_Add});
	if (uc($aOrder->{lens_SV_MF})eq'S') {
		if (defined($aOrder->{rx_OD_Far_PD}) && defined($aOrder->{rx_OS_Far_PD})) {
			print_if(\*FH, 'FPD ', $aOrder->{rx_OD_Far_PD}, $aOrder->{rx_OS_Far_PD});
		} else {
			print_if(\*FH, 'FPD ', $aOrder->{rx_OD_Near_PD}, $aOrder->{rx_OS_Near_PD});
		}
	} else {
		print_if(\*FH, 'FPD ', $aOrder->{rx_OD_Far_PD}, $aOrder->{rx_OS_Far_PD});
		print_if(\*FH, 'NPD ', $aOrder->{rx_OD_Near_PD}, $aOrder->{rx_OS_Near_PD});
	}
	print_if(\*FH, 'SHT ', $aOrder->{rx_OD_Seg_Height}, $aOrder->{rx_OS_Seg_Height});
	print_if(\*FH, 'OCH ', $aOrder->{rx_OD_OC_Height}, $aOrder->{rx_OS_OC_Height});
	print_if(\*FH, 'BCV ', $aOrder->{rx_OD_Special_Base_Curve}, $aOrder->{rx_OS_Special_Base_Curve});
	if ( length($aOrder->{rx_OD_Special_Thickness}) > 0
		|| length($aOrder->{rx_OS_Special_Thickness}) > 0) {
		my $temp1 = length($aOrder->{rx_OD_Special_Thickness}) > 0 
									? $aOrder->{rx_OD_Special_Thickness}
									: '0.00';
		my $temp2 = length($aOrder->{rx_OS_Special_Thickness}) > 0 
									? $aOrder->{rx_OS_Special_Thickness}
									: '0.00';
		if ($aOrder->{rx_OD_Thickness_Reference} eq 'Edge') {
			print FH 'EDG ' . $temp1 . '  ' . $temp2."\n";
		} else {
			print FH 'CTH ' . $temp1 . '  ' . $temp2."\n";
		}
	}
	if (length($aOrder->{rx_OD_Prism_Diopters}) ne 0  
			|| length($aOrder->{rx_OS_Prism_Diopters}) ne 0) {
		my @array1 = ($aOrder->{rx_OD_Prism_Diopters}, 
															$aOrder->{rx_OD_Prism}, 
															$aOrder->{rx_OD_Prism_Angle_Val},
															$aOrder->{rx_OD_Prism2_Diopters},
															$aOrder->{rx_OD_Prism2});

		my @array2 = ($aOrder->{rx_OS_Prism_Diopters},
															$aOrder->{rx_OS_Prism},
															$aOrder->{rx_OS_Prism_Angle_Val},
															$aOrder->{rx_OS_Prism2_Diopters},
															$aOrder->{rx_OS_Prism2});
		# if values are specified as Angles, convert them to direction
		if ($array1[1] eq 'Angle') {convertPrismData(0, \@array1);}
		if ($array2[1] eq 'Angle') {convertPrismData(1, \@array2);} 
		
		my $ODP1Val = $array1[0];
		my $ODP1Dir = $array1[1];
		my $ODP2Val = $array1[3];
		my $ODP2Dir = $array1[4];
		my $OSP1Val = $array2[0];
		my $OSP1Dir = $array2[1];
		my $OSP2Val = $array2[3];
		my $OSP2Dir = $array2[4];
		# Innovations only expresses prism as IN or UP
		# reverse anthing that is OUT or DOWN
		if ($ODP1Dir eq "OUT" || $ODP1Dir eq "DOWN") {
			if (length($ODP1Val) != 0) {$ODP1Val = '-' . $ODP1Val;}
			if ($ODP1Dir eq "OUT") {
				$ODP1Dir = "IN";
			} else {
				$ODP1Dir = "UP";
			}
		}
		if ($ODP2Dir eq "OUT" || $ODP2Dir eq "DOWN") {
			if (length($ODP2Val) != 0) {$ODP2Val = '-' . $ODP2Val;}
			if ($ODP2Dir eq "OUT") {
				$ODP2Dir = "IN";
			} else {
				$ODP2Dir = "UP";
			}
		}
		if ($OSP1Dir eq "OUT" || $OSP1Dir eq "DOWN") {
			if (length($OSP1Val) != 0) {$OSP1Val = '-' . $OSP1Val;}
			if ($OSP1Dir eq "OUT") {
				$OSP1Dir = "IN";
			} else {
				$OSP1Dir = "UP";
			}
		}
		if ($OSP2Dir eq "OUT" || $OSP2Dir eq "DOWN") {
			if (length($OSP2Val) != 0) {$OSP2Val = '-' . $OSP2Val;}
			if ($OSP2Dir eq "OUT") {
				$OSP2Dir = "IN";
			} else {
				$OSP2Dir = "UP";
			}
		}
		my $PIN_String;
		my $PUP_String;
		if (length($ODP1Val) > 0) {
			if ($ODP1Dir eq "IN") {
				$PIN_String = $ODP1Val;
				$PUP_String = (length($ODP2Val) > 0) ? $ODP2Val : "  0.00";
			} else { #UP 
				$PUP_String = $ODP1Val;
				$PIN_String = (length($ODP2Val) > 0) ? $ODP2Val : "  0.00";
			}
		} else {
			$PIN_String = "  0.00";
			$PUP_String = "  0.00";
		}
		if (length($OSP1Val) > 0) {
			if ($OSP1Dir eq "IN") {
				$PIN_String .= (" " . $OSP1Val);
				$PUP_String .= (length($OSP2Val) > 0) ? ("  " . $OSP2Val) : "  0.00";
			} else { 
				$PUP_String .= (" " . $OSP1Val);
				$PIN_String .= (length($OSP2Val) > 0) ? ("  " . $OSP2Val) : "  0.00";
			}
		} else {
			$PIN_String .= " 0.00";
			$PUP_String .= " 0.00";
		}
		print FH "PIN " . $PIN_String."\n";
		print FH "PUP " . $PUP_String."\n";
	}
	if ((($aOrder->{tr_Tinting} || "0") ne "0") ||
		(($aOrder->{tr_TintColor} || "0") ne "0") ||
		(($aOrder->{tr_TintPerCent} || "0") ne "0")) {
			print FH "SPT " . $aOrder->{tr_Tinting} . " " . $aOrder->{tr_TintColor} . " " . $aOrder->{tr_TintPerCent}."\n";
	}
	if ((($aOrder->{tr_Coating} || "0") ne "0") ||
		(($aOrder->{tr_AntiReflective} || "0") ne "0")) {
			print FH "SPC " . $aOrder->{tr_Coating} . " " . $aOrder->{tr_AntiReflective}."\n";
	}
	if ((($aOrder->{tr_Treatment} || "0") ne "0") ||
		(($aOrder->{tr_Other1} || "0") ne "0") ||
		(($aOrder->{tr_Other2} || "0") ne "0") ||
		(($aOrder->{tr_Other3} || "0") ne "0") ||
		(($aOrder->{tr_Other4} || "0") ne "0")) {
			print FH "SPX " . $aOrder->{tr_Treatment} . " " . $aOrder->{tr_Other1}
								 . " " . $aOrder->{tr_Other2} . " " . $aOrder->{tr_Other3}
								 . " " . $aOrder->{tr_Other4} . "\n";
	}
	print FH "\$\$\$";
	close(FH);
	print "RXI file: $rxifile\n";
	writemanifest($base.'$MF', $aOrder);
	
	return $base;
}

########################################################
#	writemanifest
########################################################
sub writemanifest {
	my ($file, $aOrder) = @_;
	my $trace = $aOrder->{trace_file_data};
	
	open(FH, "> $file\0") or die "Can't create manifest file $file ($!)\n";
	print FH "[General]\n";
	print FH "Account=". $aOrder->{field_acct_id}."\n";
	print FH "RxNum=" . $aOrder->{orders_pending_id}."\n";
	if (defined($trace) && length($trace) != 0) { 
		print FH "HasTrace=1\n\n";
	} else {
		print FH "HasTrace=0\n\n";
	}
	print FH "[Files]\n";
	print FH "Job=" . $aOrder->{field_acct_id}.'-'.$aOrder->{orders_pending_id}.'.$RX'."\n";
	if (defined($trace) && length($trace) != 0) {
		if ($aOrder->{trace_file_data} =~ /JOB=/) {
			print FH "Trace=" . $aOrder->{field_acct_id}.'-'.$aOrder->{orders_pending_id}.'.$OM';
		} elsif ($aOrder->{trace_file_data} =~ /JOB /) {
			print FH "Trace=" . $aOrder->{field_acct_id}.'-'.$aOrder->{orders_pending_id}.'.$FT';
		}
	} else {
		print FH "Trace=";
	}
	close(FH);
	print "Manifest file: $file\n";
	
	return;
}



########################################################
#	trim utility
########################################################
sub trim {
  my $string = shift;
  $string  ||= 0;
  for ($string) {
    s/^\s+//;
    s/\s+$//;
  }
  return $string;
}


########################################################
#	create the lens alias value
########################################################
sub lensAlias {
	my($mcodeL, $scodeL, $ccodeL, $mcodeR, $scodeR, $ccodeR) = @_;
	return lpad($mcodeL,3).lpad($scodeL,5).lpad($ccodeL,5).', '.lpad($mcodeR,3).lpad($scodeR,5).lpad($ccodeR,5);
}


########################################################
#	print if there are values
########################################################
sub print_if {
	my($FH, $orderKey, $odVal, $osVal) = map($_ || 0, @_[0 .. 3]);
	if (abs $odVal > 0.00 || abs $osVal > 0.00) {
		print $FH $orderKey . '  ' . $odVal . '  ' . $osVal . "\n";
	}
} 


########################################################
#	convert prism angle to its vertical and horizontal components
########################################################
sub convertPrismData {
	my($lr) = $_[0];
	my($q2q3,$q1q4);
	
	if ($lr == 0) {	# OD setup
		$q2q3 = "OUT";
		$q1q4 = "IN";
	} else {			# OS setup
		$q2q3 = "IN";
		$q1q4 = "OUT";
	}
	my $vertical_component = round($_[1]->[0] * sin($_[1]->[2] * PI/180.0) * 100.0) / 100.0;
	my $horizontal_component = round($_[1]->[0] * cos($_[1]->[2] * PI/180.0) * 100.0) / 100.0;
	$_[1]->[0] = abs($vertical_component);
	$_[1]->[1] = (($vertical_component < 0)  ? "DOWN" : "UP");
	$_[1]->[3] = abs($horizontal_component);
	$_[1]->[4] = (($horizontal_component < 0) ? $q2q3 : $q1q4);
	return;
}


########################################################
#	pad value with leading zeros
########################################################
sub lpad {
	my($v, $pad) = @_;

	return sprintf("%0${pad}d", $v);
}


########################################################
#	write the OMA trace into a file
########################################################
sub t_write {
	my($file, $aOrder) = @_;
	my($trace) = $aOrder->{trace_file_data};
	my(@filebasename);
	@filebasename = split (/\./,$file);
	
	if ($trace =~ /JOB=/) {	#this must be an OMA file
		#$trace =~ s/JOB=.*/RMT="$filebasename[0]"/;
		$trace =~ s/JOB=.*/RMT="$filebasename[0]"/;
		#open(F, "> $file\0") or die "Can't create trace-file $file ($!)\n";
		open(F, "> $file\$OM\0") or die "Can't create trace-file $file\$OM ($!)\n";
		print F $trace;
		close(F);
		#make a comment that this was done
		print "Trace file: $file\$OM\n";
	} elsif ($trace =~ /JOB /)  {	#this must be an FT file
		open(F, "> $file\$FT\0") or die "Can't create trace-file $file\$FT ($!)\n";
		#print F "RMT $filebasename[0]";
		print F "RMT $filebasename[0]\n";
		print F $trace;
		close(F);
		#make a comment that this was done
		print "Trace file: $file\$FT\n";
	}
}

1;
########################################################
