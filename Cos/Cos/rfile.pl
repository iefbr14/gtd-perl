use Math::Trig;

# record fields
my(
	$store,
	$patient,
	$date_ord,
	$date_prom,
	$tray_no,
	$invc_no,
	$time_prom,
	$dispenser,

	$eye_dispense,
	$r_sph_int,
	$r_sph_frac,
	$r_sph_sign,
	$l_sph_int,
	$l_sph_frac,
	$l_sph_sign,

	$r_cyl_int,
	$r_cyl_frac,
	$r_cyl_sign,
	$l_cyl_int,
	$l_cyl_frac,
	$l_cyl_sign,

	$r_axis,
	$l_axis,

	$r_add_int,
	$r_add_frac,
	$r_add_sign,
	$l_add_int,
	$l_add_frac,
	$l_add_sign,

	$material_code,
	$style_code,
	$color_code,

	$r_seg1,
	$r_seg2,
	$l_seg1,
	$l_seg2,

	$r_boc1,
	$r_boc2,
	$l_boc1,
	$l_boc2,

	$r_pd1,
	$r_pd2,
	$l_pd1,
	$l_pd2,

	$r_npd1,
	$r_npd2,
	$l_npd1,
	$l_npd2,

	$tint_pct,
	$tint_desc,

	$misc_1,
	$misc_1_desc,

	$misc_2,
	$misc_2_desc,

	$misc_3,
	$misc_3_desc,

	$misc_4,
	$misc_4_desc,

	$misc_5,
	$misc_5_desc,

	$misc_6,
	$misc_6_desc,

	$misc_7,
	$misc_7_desc,

	$comment_1,
	$comment_2,
	$comment_3,

	$frame_key,
	$frame_desc,
	$frame_color,

	$t_status,
	$mount,
	$dress_safety,
	$pof,
	$eye_size,
	$bridge,
	$temple,

	$doctor,
	$termperin,

	$a_meas,
	$b_meas,
	$ed_meas,
	$dbl_meas,

	$r_prism1,
	$r_prism2,
	$l_prism1,
	$l_prism2,

	$r_angle,
	$l_angle,
	$r_curve,
	$l_curve,
);

sub r_convert {
    setPatient(getField_Client_Name());
    setDate_ord(getDateOrdered());
    setDate_prom(getDatePromised());
    setTime_prom(getTimePromised());

	my($tray) = getTrayNo();
	$tray = '' if $tray eq '-';	# 1.4 sets no tray to '-'
	setTray_no($tray);		# this break old opti-workers

    $invc_no = get_store_invoice_num();
    if ($invc_no > 0) {
	setInvc_no(padLeft0($invc_no,SIZEOF_INVC_NO),SIZEOF_INVC_NO);
    } else {
	setInvc_no(padLeft0(LSChars(getOrderNumber(),SIZEOF_INVC_NO),SIZEOF_INVC_NO));
    }

    setR_sph_int ( padLeft0(  intPart(getRx_OD_Sphere()), SIZEOF_R_SPH_INT) );
    setR_sph_frac( padRight0(fracPart(getRx_OD_Sphere()), SIZEOF_R_SPH_FRAC) );
    setR_sph_sign(           signPart(getRx_OD_Sphere()) );
    setL_sph_int ( padLeft0(  intPart(getRx_OS_Sphere()), SIZEOF_L_SPH_INT) );
    setL_sph_frac( padRight0(fracPart(getRx_OS_Sphere()), SIZEOF_L_SPH_FRAC) );
    setL_sph_sign(           signPart(getRx_OS_Sphere()) );

    setR_cyl_int ( padLeft0( intPart (getRx_OD_Cylinder()), SIZEOF_R_CYL_INT) );
    setR_cyl_frac( padRight0(fracPart(getRx_OD_Cylinder()), SIZEOF_R_CYL_FRAC) );
    setR_cyl_sign(           signPart(getRx_OD_Cylinder()) );
    setL_cyl_int ( padLeft0( intPart (getRx_OS_Cylinder()), SIZEOF_L_CYL_INT) );
    setL_cyl_frac( padRight0(fracPart(getRx_OS_Cylinder()), SIZEOF_L_CYL_FRAC) );
    setL_cyl_sign(           signPart(getRx_OS_Cylinder()) );

    setR_axis( padLeft0(getRx_OD_Axis(), SIZEOF_R_AXIS) );
    setL_axis( padLeft0(getRx_OS_Axis(), SIZEOF_L_AXIS) );

    setR_add_int ( padLeft0(  intPart(getRx_OD_Add()), SIZEOF_R_ADD_INT) );
    setR_add_frac( padRight0(fracPart(getRx_OD_Add()), SIZEOF_R_ADD_FRAC) );
    setR_add_sign(           signPart(getRx_OD_Add()) );
    setL_add_int ( padLeft0(  intPart(getRx_OS_Add()), SIZEOF_L_ADD_INT) );
    setL_add_frac( padRight0(fracPart(getRx_OS_Add()), SIZEOF_L_ADD_FRAC) );
    setL_add_sign(           signPart(getRx_OS_Add()) );

    setR_seg1( padLeft0(  intPart(getRx_OD_Seg_Height()), SIZEOF_R_SEG1) );
    setR_seg2( padRight0(fracPart(getRx_OD_Seg_Height()), SIZEOF_R_SEG2) );
    setL_seg1( padLeft0(  intPart(getRx_OS_Seg_Height()), SIZEOF_L_SEG1) );
    setL_seg2( padRight0(fracPart(getRx_OS_Seg_Height()), SIZEOF_L_SEG2) );

    setR_boc1( padLeft0(  intPart(getRx_OD_OC_Height()), SIZEOF_R_BOC1) );
    setR_boc2( padRight0(fracPart(getRx_OD_OC_Height()), SIZEOF_L_BOC2) );
    setL_boc1( padLeft0(  intPart(getRx_OS_OC_Height()), SIZEOF_L_BOC1) );
    setL_boc2( padRight0(fracPart(getRx_OS_OC_Height()), SIZEOF_L_BOC2) );

    setR_pd1( padLeft0(  intPart(getRx_OD_Mono_PD()), SIZEOF_R_PD1) );
    setR_pd2( padRight0(fracPart(getRx_OD_Mono_PD()), SIZEOF_R_PD2) );
    setL_pd1( padLeft0(  intPart(getRx_OS_Mono_PD()), SIZEOF_L_PD1) );
    setL_pd2( padRight0(fracPart(getRx_OS_Mono_PD()), SIZEOF_L_PD2) );

    my($mono) = get('lens_SV_MF');
    if ($mono eq 's' or $mono eq 'm') {	# 1.5 format Near/Far only used.
	my($near,$far);

	$far  = getRx_OD_Far_PD();
	$near = getRx_OD_Near_PD();
	$far = $near if $far eq '' or $far == 0;
	setR_pd1( padLeft0(  intPart($far), SIZEOF_R_PD1) );
	setR_pd2( padRight0(fracPart($far), SIZEOF_R_PD2) );

	setR_npd1( padLeft0(intPart($near), SIZEOF_R_NPD1) );
	setR_npd2( padRight0(fracPart($near), SIZEOF_R_NPD2) );

	$far  = getRx_OS_Far_PD();
	$near = getRx_OS_Near_PD();
	$far = $near if $far eq '' or $far == 0;
	setL_pd1( padLeft0(  intPart($far), SIZEOF_L_PD1) );
	setL_pd2( padRight0(fracPart($far), SIZEOF_L_PD2) );

	setL_npd1( padLeft0(intPart($near), SIZEOF_L_NPD1) );
	setL_npd2( padRight0(fracPart($near), SIZEOF_L_NPD2) );

	setR_mono( 'MON' );
	setL_mono( 'MON' );

    } elsif ($mono eq 'MON' or $mono eq 'BPD') { # extern format.
	my($near);

	$near = getRx_OD_Near_PD();
	setR_npd1( padLeft0(intPart($near), SIZEOF_R_NPD1) );
	setR_npd2( padRight0(fracPart($near), SIZEOF_R_NPD2) );

	$near = getRx_OS_Near_PD();
	setL_npd1( padLeft0(intPart($near), SIZEOF_L_NPD1) );
	setL_npd2( padRight0(fracPart($near), SIZEOF_L_NPD2) );

	setR_mono( $mono );
	setL_mono( $mono );
    } else {					# botched 1.4 foramt
	my($farPD, $nearPD, $monoPD, $diffPD);
	$farPD	= getRx_OD_Far_PD();
	$farPD = 0 if $farPD eq '';

	$nearPD	= getRx_OD_Near_PD();
	$nearPD = 0 if $nearPD eq '';

	$diffPD	= ($farPD - $nearPD)/2.0;

	$monoPD	= map_undef_0(getRx_OD_Mono_PD()) - $diffPD;
	if ( $monoPD < 0.0 ) { $monoPD = 0.0; }
	$monoPD = sprintf("%.1f", $monoPD);
	setR_npd1( padLeft0(intPart($monoPD), SIZEOF_R_NPD1) );
	setR_npd2( padRight0(fracPart($monoPD), SIZEOF_R_NPD2) );

	$monoPD	= map_undef_0(getRx_OS_Mono_PD()) - $diffPD;
	if( $monoPD < 0.0 ) { $monoPD = 0.0; }
	$monoPD = sprintf("%.1f", $monoPD);
	setL_npd1( padLeft0(intPart($monoPD), SIZEOF_L_NPD1) );
	setL_npd2( padRight0(fracPart($monoPD), SIZEOF_L_NPD2) );

	setR_mono( "MON" );
	setL_mono( "MON" );
   }

    setTint_pct( padLeft0(getTr_TintPerCent(), SIZEOF_TINT_PCT) );
    setTint_desc( padLeftBlanks(NoChoose(getTr_TintColor()), SIZEOF_TINT_DESC) );

    setMisc_1( getTr_Other1_Code() );
    setMisc_1_desc( NoChoose(getTr_Other1()) );
    setMisc_2( getTr_Other2_Code() );
    setMisc_2_desc( NoChoose(getTr_Other2()) );
    setMisc_3( getTr_Other3_Code() );
    setMisc_3_desc( NoChoose(getTr_Other3()) );
    setMisc_4( getTr_Treatment_Code() );
    setMisc_4_desc( NoChoose(getTr_Treatment()) );
    setMisc_5( getTr_Tinting_Code() );
    setMisc_5_desc( NoChoose(getTr_Tinting()) );
    setMisc_6( getTr_AntiReflective_Code() );
    setMisc_6_desc( NoChoose(getTr_AntiReflective()) );
    setMisc_7( getTr_Coating_Code() );
    setMisc_7_desc( NoChoose(getTr_Coating()) );

# Instructions go into Comment_1, Comment_2, Comment3
#
	my($instructions) = getInstructions();
	$instructions = padRightBlanks($instructions,
			SIZEOF_COMMENT_1+SIZEOF_COMMENT_2+SIZEOF_COMMENT_3 ); 
    setComment_1(substr($instructions, 0, SIZEOF_COMMENT_1));
    setComment_2(substr($instructions, SIZEOF_COMMENT_1, SIZEOF_COMMENT_1+SIZEOF_COMMENT_2));
    setComment_3(substr($instructions, SIZEOF_COMMENT_1+SIZEOF_COMMENT_2,
			SIZEOF_COMMENT_1+SIZEOF_COMMENT_2+SIZEOF_COMMENT_3));

    setFrame_key( getFs1_upc() );
    if (length(getFs1_vendor()) > 0) {
	setFrame_desc( getFs1_vendor()." ".getFs1_model() );
    } else {
	setFrame_desc( getFs1_model() );
    }
    setFrame_color( getFs1_color() );
    $t_status = 1; # ***BUG*** for ENCLOSED
       if (equalsIgnoreCase(getFdSource(), "TRACE    - POF"))   { $t_status = "4"; }
    elsif (equalsIgnoreCase(getFdSource(), "TRACE    - UNCUT")) { $t_status = "1"; }
    elsif (equalsIgnoreCase(getFdSource(), "TRACE    - STOCK")) { $t_status = "1"; }
    elsif (equalsIgnoreCase(getFdSource(), "NO TRACE - UNCUT")) { $t_status = "5"; }
# new codes
    elsif (equalsIgnoreCase(getFdSource(), "TRACE--POF"))       { $t_status = "4"; }
    elsif (equalsIgnoreCase(getFdSource(), "TRACE--STOCK"))     { $t_status = "4"; }
    elsif (equalsIgnoreCase(getFdSource(), "TRACE--UNCUT"))     { $t_status = "5"; }
    elsif (equalsIgnoreCase(getFdSource(), "TRACE--SUPPLY"))    { $t_status = "1"; }
    elsif (equalsIgnoreCase(getFdSource(), "NO TRACE--POF"))    { $t_status = "5"; }
    elsif (equalsIgnoreCase(getFdSource(), "NO TRACE--STOCK"))  { $t_status = "5"; }
    elsif (equalsIgnoreCase(getFdSource(), "NO TRACE--UNCUT"))  { $t_status = "5"; }
    elsif (equalsIgnoreCase(getFdSource(), "NO TRACE--SUPPLY")) { $t_status = "1"; }
# rd codes
    elsif (equalsIgnoreCase(getFdSource(), "SUPPLY"))           { $t_status = "1"; }
    elsif (equalsIgnoreCase(getFdSource(), "ENCLOSED"))         { $t_status = "2"; }
    elsif (equalsIgnoreCase(getFdSource(), "TO-COME"))          { $t_status = "3"; }
    elsif (equalsIgnoreCase(getFdSource(), "LENSES-ONLY"))      { $t_status = "4"; }
    elsif (equalsIgnoreCase(getFdSource(), "UNCUT"))            { $t_status = "5"; }
# end of new codes
    setMount( getFp_mounting() );
    setDressSafety( getFp_dress() );
    setPOF( getFdSource() );
    setEyeSize( padLeft0(getFdEye(), SIZEOF_EYE_SIZE) );
    setBridge( padLeft0(getFdBridge(), SIZEOF_BRIDGE) );
    setTemple( padLeft0(getFdTemple(), SIZEOF_TEMPLE) );


    setEyeDispense( padLeft0(getLens_Pair(), SIZEOF_EYE_DISPENSE) );

    setDoctor( padLeft0("", SIZEOF_DOCTOR) );
    setTermperin( padLeft0("", SIZEOF_TERMPERIN) );

    setA_meas( padLeft0(intPart(getFdA()),SIZEOF_A_MEAS_INT) .
		 padRight0(fracPart(getFdA()),SIZEOF_A_MEAS_FRAC) );
    setB_meas( padLeft0(intPart(getFdB()),SIZEOF_B_MEAS_INT) .
		 padRight0(fracPart(getFdB()),SIZEOF_B_MEAS_FRAC) );
    setEd_meas( padLeft0(intPart(getFdED()),SIZEOF_ED_MEAS_INT) .
		  padRight0(fracPart(getFdED()),SIZEOF_ED_MEAS_FRAC) );
    setDbl_meas( padLeft0(intPart(getFdDBL()),SIZEOF_DBL_MEAS_INT) .
		   padRight0(fracPart(getFdDBL()),SIZEOF_DBL_MEAS_FRAC) );

	# rdt format can only hold 1 material/style/color code
	# for right eye (1) or both (3) we use the right eye
	my $mcode = getLens_OD_MaterCode();
	my $scode = getLens_OD_StyleCode();
	my $ccode = getLens_OD_ColorCode();
	if (getLens_Pair() == 2) {	# otherwise we have left eye only (2)
		$mcode = getLens_OS_MaterCode();
		$scode = getLens_OS_StyleCode();
		$ccode = getLens_OS_ColorCode();
	}
	setMaterial_code( padLeft0($mcode,SIZEOF_MATERIAL_CODE ) );
	setStyle_code(    padLeft0($scode,SIZEOF_STYLE_CODE ) );
	setColor_code(    padLeft0($ccode,SIZEOF_COLOR_CODE ) );

	# Magic Prism conversions
	#
	my $A; # Prism Amount 1
	my $B; # Prism Amount 2
	my $S1; # Prism Angle 1
	my $S2; # Prism Angle 2
	my($A1, $A2, $B1, $B2, $P1, $P2); # interim variables
	my $P; # Combined Prism Amount
	my $D; # Combined Prism Direction (Angle)
	#
	# Right Eye
	#
	$B = 0.0;
	$S2 = 0.0;
	if( length(getRx_OD_Prism_Diopters()) == 0 ) {
	    setR_prism1( padLeft0("0", SIZEOF_R_PRISM1) ); # Integer part
	    setR_prism2( padLeft0("0", SIZEOF_R_PRISM2) ); # Fractional part
	    setR_angle( padLeft0("0", SIZEOF_R_ANGLE) );

	} else {
		$A = getRx_OD_Prism_Diopters();
		if( getRx_OD_Prism() eq PRISM_DIR_ANGLE ) {
			$S1 = getRx_OD_Prism_Angle_Val();
		} else {
			if( getRx_OD_Prism() eq PRISM_DIR_UP ) {
				$S1 = 90.0;
			} elsif ( getRx_OD_Prism() eq PRISM_DIR_DOWN ) {
				$S1 = 270.0;
			} elsif ( getRx_OD_Prism() eq PRISM_DIR_IN ) {
				$S1 = 0.0;
			} else {
				$S1 = 180.0;
			}
			
			if( length(getRx_OD_Prism2_Diopters()) != 0 ) {
				$B = getRx_OD_Prism2_Diopters();
				if( getRx_OD_Prism2() eq PRISM_DIR_UP ) {
					$S2 = 90.0;
				} elsif ( getRx_OD_Prism2() eq PRISM_DIR_DOWN ) {
					$S2 = 270.0;
				} elsif ( getRx_OD_Prism2() eq PRISM_DIR_IN ) {
					$S2 = 0.0;
				} else {
					$S2 = 180.0;
				}
			}	
		}
		$A1 = $A * cos($S1 * PI/180.0);
		$A2 = $A * sin($S1 * PI/180.0);
		$B1 = $B * cos($S2 * PI/180.0);
		$B2 = $B * sin($S2 * PI/180.0);
		$P1 = $A1 + $B1;
		$P2 = $A2 + $B2;
		$P = sqrt($P1*$P1 + $P2*$P2);
		if ($P == 0) {
			$D = '0';
			$P2_P = 'NaN';
		} else {
			$D = Math::Trig::asin($P2/$P)*180.0/PI;
			$P2_P = $P2/$P;
		}

		# rounding
###		$P = int($P*100+0.5)/100.0; # rounding by 0.005 since prism is ##.##
		$P = sprintf("%.2f", $P);

		if( $D < 0.0 ) {
			if( $P1 < 0.0 ) {
				$D = -180.0 - $D;
			}
			$D = int($D-0.5);
			$D += 360.0;
		}
		else {
			if( $P1 < 0.0 ) {
				$D = 180.0 - $D;
			}
			$D = int($D+0.5);
		}
# printf "D -> %s int:%d 1d:%.1f\n", $D, $D, $D;
	    $P .= '';
	    $D .= '';

# print "OD: A=$A,B=$B,A1=$A1,A2=$A2,B1=$B1,B2=$B2,P1=$P1,P2=$P2,P=$P,P2/P=$P2_P,D=$D\n";
	
	    setR_prism1( padLeft0(intPart($P), SIZEOF_R_PRISM1) ); # Integer part
	    setR_prism2( padLeft0(fracPart($P), SIZEOF_R_PRISM2) ); # Fractional part
	    setR_angle( padLeft0(intPart($D), SIZEOF_R_ANGLE) );
	    if( length(getRx_OD_Prism2_Diopters()) != 0 ) {
		setRx_OD_Prism_Diopters($P);	 	# ***BUG*** Ugly side effect
		setRx_OD_Prism_Angle_Val($D . '.0');	# ***BUG*** .0 is in the D file only
	    }
	}
	
	#
	# Left Eye
	#
	$B = 0.0;
	$S2 = 0.0;
	if( length(getRx_OS_Prism_Diopters()) == 0 ) {
	    setL_prism1( padLeft0("0", SIZEOF_L_PRISM1) ); # Integer part
	    setL_prism2( padLeft0("0", SIZEOF_L_PRISM2) ); # Fractional part
	    setL_angle( padLeft0("0", SIZEOF_L_ANGLE) );

	} else {
		$A = getRx_OS_Prism_Diopters();
		if( getRx_OS_Prism() eq PRISM_DIR_ANGLE ) {
			$S1 = getRx_OS_Prism_Angle_Val();
		} else {
			if( getRx_OS_Prism() eq PRISM_DIR_UP ) {
				$S1 = 90.0;
			} elsif ( getRx_OS_Prism() eq PRISM_DIR_DOWN ) {
				$S1 = 270.0;
			} elsif ( getRx_OS_Prism() eq PRISM_DIR_IN ) {
				$S1 = 180.0;
			} else {
				$S1 = 0.0;
			}
			
			if( length(getRx_OS_Prism2_Diopters()) != 0 ) {
				$B = getRx_OS_Prism2_Diopters();

				if( getRx_OS_Prism2() eq PRISM_DIR_UP ) {
					$S2 = 90.0;
				} elsif ( getRx_OS_Prism2() eq PRISM_DIR_DOWN ) {
					$S2 = 270.0;
				} elsif ( getRx_OS_Prism2() eq PRISM_DIR_IN ) {
					$S2 = 180.0;
				} else {
					$S2 = 0.0;
				}
			}	
		}
		$A1 = $A * cos($S1 * PI/180.0);
		$A2 = $A * sin($S1 * PI/180.0);
		$B1 = $B * cos($S2 * PI/180.0);
		$B2 = $B * sin($S2 * PI/180.0);
		$P1 = $A1 + $B1;
		$P2 = $A2 + $B2;
		$P = sqrt($P1*$P1 + $P2*$P2);
		if ($P == 0) {
			$D = '0';
			$P2_P = 'NaN';
		} else {
			$D = Math::Trig::asin($P2/$P)*180.0/PI;
			$P2_P = $P2/$P;
		}
		# rounding
####		$P = int($P*100+0.5)/100.0;
		$P = sprintf("%.2f", $P);
		if( $D < 0.0 ) {
			if( $P1 < 0.0 ) {
				$D = -180.0 - $D;
			}
			$D = int($D-0.5);
			$D += 360.0;
		}
		else {
			if( $P1 < 0.0 ) {
				$D = 180.0 - $D;
			}
			$D = int($D+0.5);
		}
# printf "D -> %s int:%d 1d:%.1f\n", $D, $D, $D;
	    $P .= '';
	    $D .= '';
# print "OS: A=$A,B=$B,A1=$A1,A2=$A2,B1=$B1,B2=$B2,P1=$P1,P2=$P2,P=$P,P2/P=$P2_P,D=$D\n";
	
	    setL_prism1( padLeft0(intPart($P), SIZEOF_L_PRISM1) ); # Integer part
	    setL_prism2( padLeft0(fracPart($P), SIZEOF_L_PRISM2) ); # Fractional part
	    setL_angle( padLeft0(intPart($D), SIZEOF_L_ANGLE) );
	    if( length(getRx_OS_Prism2_Diopters()) != 0 ) {
		setRx_OS_Prism_Diopters($P);	 	# ***BUG*** Ugly side effect
		setRx_OS_Prism_Angle_Val($D . '.0');	# ***BUG*** .0 is in the D file only
            }
	}

	# Base Curve
    setR_curve( NoChoose(getRx_OD_Special_Base_Curve()) );
    setL_curve( NoChoose(getRx_OS_Special_Base_Curve()) );


}

  # set/get methods

sub getA_meas()		{ return $a_meas; }
sub getB_meas()		{ return $b_meas; }
sub getBridge()		{ return $bridge; }

sub getColor_code()	{ return $color_code; }
sub getComment_1()	{ return $comment_1; }
sub getComment_2()	{ return $comment_2; }
sub getComment_3()	{ return $comment_3; }
sub getDate_ord()	{ $date_ord =~ s/[^\d]//g; return $date_ord; }
sub getDate_prom()	{ $date_prom =~ s/[^\d]//g; return $date_prom; }
sub getDbl_meas()	{ return $dbl_meas; }
sub getDoctor()		{ return $doctor; }
sub getDressSafety()	{ return $dress_safety; }
sub getEd_meas()	{ return $ed_meas; }
sub getEyeDispense()	{ return $eye_dispense; }
sub getEyeSize()	{ return $eye_size; }
sub getFrame_color()	{ return $frame_color; }
sub getFrame_desc()	{ return $frame_desc; }
sub getFrame_key()	{ return $frame_key; }
sub getInvc_no()	{ return $invc_no; }
sub getL_add_frac()	{ return $l_add_frac; }
sub getL_add_int()	{ return $l_add_int; }
sub getL_add_sign()	{ return $l_add_sign; }
sub getL_angle()	{ return $l_angle; }
sub getL_axis()		{ return $l_axis; }
sub getL_boc1()		{ return $l_boc1; }
sub getL_boc2()		{ return $l_boc2; }
sub getL_curve()	{ return $l_curve; }
sub getL_cyl_frac()	{ return $l_cyl_frac; }
sub getL_cyl_int()	{ return $l_cyl_int; }
sub getL_cyl_sign()	{ return $l_cyl_sign; }

sub getL_mono()		{ return $l_mono; }
sub getL_npd1()		{ return $l_npd1; }
sub getL_npd2()		{ return $l_npd2; }
sub getL_pd1()		{ return $l_pd1; }
sub getL_pd2()		{ return $l_pd2; }
sub getL_prism1()	{ return $l_prism1; }
sub getL_prism2()	{ return $l_prism2; }
sub getL_seg1()		{ return $l_seg1; }
sub getL_seg2()		{ return $l_seg2; }
sub getL_sph_frac()	{ return $l_sph_frac; }
sub getL_sph_int()	{ return $l_sph_int; }
sub getL_sph_sign()	{ return $l_sph_sign; }
sub getMaterial_code()	{ return $material_code; }
sub getMisc_1_desc()	{ return $misc_1_desc; }
sub getMisc_1()		{ return $misc_1; }
sub getMisc_2_desc()	{ return $misc_2_desc; }
sub getMisc_2()		{ return $misc_2; }
sub getMisc_3_desc()	{ return $misc_3_desc; }
sub getMisc_3()		{ return $misc_3; }
sub getMisc_4_desc()	{ return $misc_4_desc; }
sub getMisc_4()		{ return $misc_4; }
sub getMisc_5_desc()	{ return $misc_5_desc; }
sub getMisc_5()		{ return $misc_5; }
sub getMisc_6_desc()	{ return $misc_6_desc; }
sub getMisc_6()		{ return $misc_6; }
sub getMisc_7_desc()	{ return $misc_7_desc; }
sub getMisc_7()		{ return $misc_7; }
sub getMount()		{ return $mount; }
sub getPatient()	{ return $patient; }
sub getPOF()		{ return $pof; }
sub getR_add_frac()	{ return $r_add_frac; }
sub getR_add_int()	{ return $r_add_int; }
sub getR_add_sign()	{ return $r_add_sign; }
sub getR_angle()	{ return $r_angle; }
sub getR_axis()		{ return $r_axis; }
sub getR_boc1()		{ return $r_boc1; }
sub getR_boc2()		{ return $r_boc2; }
sub getR_curve()	{ return $r_curve; }
sub getR_cyl_frac()	{ return $r_cyl_frac; }
sub getR_cyl_int()	{ return $r_cyl_int; }
sub getR_cyl_sign()	{ return $r_cyl_sign; }

sub getR_mono()		{ return $r_mono; }
sub getR_npd1()		{ return $r_npd1; }
sub getR_npd2()		{ return $r_npd2; }
sub getR_pd1()		{ return $r_pd1; }
sub getR_pd2()		{ return $r_pd2; }
sub getR_prism1()	{ return $r_prism1; }
sub getR_prism2()	{ return $r_prism2; }
sub getR_seg1()		{ return $r_seg1; }
sub getR_seg2()		{ return $r_seg2; }
sub getR_sph_frac()	{ return $r_sph_frac; }
sub getR_sph_int()	{ return $r_sph_int; }
sub getR_sph_sign()	{ return $r_sph_sign; }

sub getStyle_code()	{ return $style_code; }
sub getTemple()		{ return $temple; }
sub getTermperin()	{ return $termperin; }
sub getTime_prom()	{ return $time_prom; }
sub getTint_desc()	{ return $tint_desc; }
sub getTint_pct()	{ return $tint_pct; }
sub getTray_no()	{ return $tray_no; }

sub setA_meas { my($s) = @_; $a_meas = set($s, SIZEOF_A_MEAS); }
sub setB_meas { my($s) = @_; $b_meas = set($s, SIZEOF_B_MEAS); }
sub setBridge { my($s) = @_; $bridge = set($s, SIZEOF_BRIDGE); }

sub setColor_code { my($s) = @_; $color_code = set($s, SIZEOF_COLOR_CODE); }
sub setComment_1 { my($s) = @_; $comment_1 = set($s, SIZEOF_COMMENT_1); }
sub setComment_2 { my($s) = @_; $comment_2 = set($s, SIZEOF_COMMENT_2); }
sub setComment_3 { my($s) = @_; $comment_3 = set($s, SIZEOF_COMMENT_3); }
sub setDate_ord { my($s) = @_; $date_ord = set($s, SIZEOF_DATE_ORD); }
sub setDate_prom { my($s) = @_; $date_prom = set($s, SIZEOF_DATE_PROM); }
sub setDbl_meas { my($s) = @_; $dbl_meas = set($s, SIZEOF_DBL_MEAS); }
sub setDispenser { my($s) = @_; $dispenser = set($s, SIZEOF_DISPENSER); }
sub setDoctor { my($s) = @_; $doctor = set($s, SIZEOF_DOCTOR); }
sub setDressSafety { my($s) = @_; $dress_safety = set($s, SIZEOF_DRESS_SAFETY); }
sub setEd_meas { my($s) = @_; $ed_meas = set($s, SIZEOF_ED_MEAS); }
sub setEyeDispense { my($s) = @_; $eye_dispense = set($s, SIZEOF_EYE_DISPENSE); }
sub setEyeSize { my($s) = @_; $eye_size = set($s, SIZEOF_EYE_SIZE); }
sub setFrame_color { my($s) = @_; $frame_color = set($s, SIZEOF_FRAME_COLOR); }
sub setFrame_desc { my($s) = @_; $frame_desc = set($s, SIZEOF_FRAME_DESC); }
sub setFrame_key { my($s) = @_; $frame_key = set($s, SIZEOF_FRAME_KEY); }
sub setInvc_no { my($s) = @_; $invc_no = set($s, SIZEOF_INVC_NO); }
sub setL_add_frac { my($s) = @_; $l_add_frac = set($s, SIZEOF_L_ADD_FRAC); }
sub setL_add_int { my($s) = @_; $l_add_int = set($s, SIZEOF_L_ADD_INT); }
sub setL_add_sign { my($s) = @_; $l_add_sign = set($s, SIZEOF_L_ADD_SIGN); }
sub setL_angle { my($s) = @_; $l_angle = set($s, SIZEOF_L_ANGLE); }
sub setL_axis { my($s) = @_; $l_axis = set($s, SIZEOF_L_AXIS); }
sub setL_boc1 { my($s) = @_; $l_boc1 = set($s, SIZEOF_L_BOC1); }
sub setL_boc2 { my($s) = @_; $l_boc2 = set($s, SIZEOF_L_BOC2); }
sub setL_curve { my($s) = @_; $l_curve = set($s, SIZEOF_L_CURVE); }
sub setL_cyl_frac { my($s) = @_; $l_cyl_frac = set($s, SIZEOF_L_CYL_FRAC); }
sub setL_cyl_int { my($s) = @_; $l_cyl_int = set($s, SIZEOF_L_CYL_INT); }
sub setL_cyl_sign { my($s) = @_; $l_cyl_sign = set($s, SIZEOF_L_CYL_SIGN); }

sub setL_mono { my($s) = @_; $l_mono = set($s, SIZEOF_L_MONO); }
sub setL_npd1 { my($s) = @_; $l_npd1 = set($s, SIZEOF_L_NPD1); }
sub setL_npd2 { my($s) = @_; $l_npd2 = set($s, SIZEOF_L_NPD2); }
sub setL_pd1 { my($s) = @_; $l_pd1 = set($s, SIZEOF_L_PD1); }
sub setL_pd2 { my($s) = @_; $l_pd2 = set($s, SIZEOF_L_PD2); }
sub setL_prism1 { my($s) = @_; $l_prism1 = set($s, SIZEOF_L_PRISM1); }
sub setL_prism2 { my($s) = @_; $l_prism2 = set($s, SIZEOF_L_PRISM2); }
sub setL_seg1 { my($s) = @_; $l_seg1 = set($s, SIZEOF_L_SEG1); }
sub setL_seg2 { my($s) = @_; $l_seg2 = set($s, SIZEOF_L_SEG2); }
sub setL_sph_frac { my($s) = @_; $l_sph_frac = set($s, SIZEOF_L_SPH_FRAC); }
sub setL_sph_int { my($s) = @_; $l_sph_int = set($s, SIZEOF_L_SPH_INT); }
sub setL_sph_sign { my($s) = @_; $l_sph_sign = set($s, SIZEOF_L_SPH_SIGN); }
sub setMaterial_code { my($s) = @_; $material_code = set($s, SIZEOF_MATERIAL_CODE); }
sub setMisc_1_desc { my($s) = @_; $misc_1_desc = set($s, SIZEOF_MISC_1_DESC); }
sub setMisc_1 { my($s) = @_; $misc_1 = set($s, SIZEOF_MISC_1); }
sub setMisc_2_desc { my($s) = @_; $misc_2_desc = set($s, SIZEOF_MISC_2_DESC); }
sub setMisc_2 { my($s) = @_; $misc_2 = set($s, SIZEOF_MISC_2); }
sub setMisc_3_desc { my($s) = @_; $misc_3_desc = set($s, SIZEOF_MISC_3_DESC); }
sub setMisc_3 { my($s) = @_; $misc_3 = set($s, SIZEOF_MISC_3); }
sub setMisc_4_desc { my($s) = @_; $misc_4_desc = set($s, SIZEOF_MISC_4_DESC); }
sub setMisc_4 { my($s) = @_; $misc_4 = set($s, SIZEOF_MISC_4); }
sub setMisc_5_desc { my($s) = @_; $misc_5_desc = set($s, SIZEOF_MISC_5_DESC); }
sub setMisc_5 { my($s) = @_; $misc_5 = set($s, SIZEOF_MISC_5); }
sub setMisc_6_desc { my($s) = @_; $misc_6_desc = set($s, SIZEOF_MISC_6_DESC); }
sub setMisc_6 { my($s) = @_; $misc_6 = set($s, SIZEOF_MISC_6); }
sub setMisc_7_desc { my($s) = @_; $misc_7_desc = set($s, SIZEOF_MISC_7_DESC); }
sub setMisc_7 { my($s) = @_; $misc_7 = set($s, SIZEOF_MISC_7); }
sub setMount { my($s) = @_; $mount = set($s, SIZEOF_MOUNT); }
sub setPatient { my($s) = @_; $patient = set($s, SIZEOF_PATIENT); }
sub setPOF { my($s) = @_; $pof = set($s, SIZEOF_POF); }
sub setR_add_frac { my($s) = @_; $r_add_frac = set($s, SIZEOF_R_ADD_FRAC); }
sub setR_add_int { my($s) = @_; $r_add_int = set($s, SIZEOF_R_ADD_INT); }
sub setR_add_sign { my($s) = @_; $r_add_sign = set($s, SIZEOF_R_ADD_SIGN); }
sub setR_angle { my($s) = @_; $r_angle = set($s, SIZEOF_R_ANGLE); }
sub setR_axis { my($s) = @_; $r_axis = set($s, SIZEOF_R_AXIS); }
sub setR_boc1 { my($s) = @_; $r_boc1 = set($s, SIZEOF_R_BOC1); }
sub setR_boc2 { my($s) = @_; $r_boc2 = set($s, SIZEOF_R_BOC2); }
sub setR_curve { my($s) = @_; $r_curve = set($s, SIZEOF_R_CURVE); }
sub setR_cyl_frac { my($s) = @_; $r_cyl_frac = set($s, SIZEOF_R_CYL_FRAC); }
sub setR_cyl_int { my($s) = @_; $r_cyl_int = set($s, SIZEOF_R_CYL_INT); }
sub setR_cyl_sign { my($s) = @_; $r_cyl_sign = set($s, SIZEOF_R_CYL_SIGN); }

sub setR_mono { my($s) = @_; $r_mono = set($s, SIZEOF_R_MONO); }
sub setR_npd1 { my($s) = @_; $r_npd1 = set($s, SIZEOF_R_NPD1); }
sub setR_npd2 { my($s) = @_; $r_npd2 = set($s, SIZEOF_R_NPD2); }
sub setR_pd1 { my($s) = @_; $r_pd1 = set($s, SIZEOF_R_PD1); }
sub setR_pd2 { my($s) = @_; $r_pd2 = set($s, SIZEOF_R_PD2); }
sub setR_prism1 { my($s) = @_; $r_prism1 = set($s, SIZEOF_R_PRISM1); }
sub setR_prism2 { my($s) = @_; $r_prism2 = set($s, SIZEOF_R_PRISM2); }
sub setR_seg1 { my($s) = @_; $r_seg1 = set($s, SIZEOF_R_SEG1); }
sub setR_seg2 { my($s) = @_; $r_seg2 = set($s, SIZEOF_R_SEG2); }
sub setR_sph_frac { my($s) = @_; $r_sph_frac = set($s, SIZEOF_R_SPH_FRAC); }
sub setR_sph_int { my($s) = @_; $r_sph_int = set($s, SIZEOF_R_SPH_INT); }
sub setR_sph_sign { my($s) = @_; $r_sph_sign = set($s, SIZEOF_R_SPH_SIGN); }

sub setStore { my($s) = @_; $store = set($s, SIZEOF_STORE); }
sub setStyle_code { my($s) = @_; $style_code = set($s, SIZEOF_STYLE_CODE); }
sub setTemple { my($s) = @_; $temple = set($s, SIZEOF_TEMPLE); }
sub setTermperin { my($s) = @_; $termperin = set($s, SIZEOF_TERMPERIN); }
sub setTime_prom { my($s) = @_; $time_prom = set($s, SIZEOF_TIME_PROM); }
sub setTint_desc { my($s) = @_; $tint_desc = set($s, SIZEOF_TINT_DESC); }
sub setTint_pct { my($s) = @_; $tint_pct = set($s, SIZEOF_TINT_PCT); }
sub setTray_no { my($s) = @_; $tray_no = set($s, SIZEOF_TRAY_NO); }

sub equalsIgnoreCase { my($a, $b) = @_; return lc($a) eq lc($b); }

sub addToBuffer {# (String s, int dst_position, int length)
	my($s, $off, $len) = @_;

	trace_and_die("set value s is undefined")  unless defined $s;
	# set buffer to left padded with ' ' string.
	if (length($s) > $len) {
		print "Left Trunc: $s\n";
		substr($rBuffer, $off, $len) = substr($s, 0, $len);
	} else {
		substr($rBuffer, $off, $len) = sprintf("%-${len}.${len}s", $s);
	}
}


sub r_write {
	my($file) = @_;

	$rBuffer = " " x RFILE_ACTUAL_SIZE;

	r_convert();

	# put together output buffer

	addToBuffer(getStore(),		OFFSET_STORE,SIZEOF_STORE);
	addToBuffer(getPatient(),	OFFSET_PATIENT,SIZEOF_PATIENT);
	addToBuffer(getDate_ord(),	OFFSET_DATE_ORD,SIZEOF_DATE_ORD);
	addToBuffer(getDate_prom(),	OFFSET_DATE_PROM,SIZEOF_DATE_PROM);
	addToBuffer(getTray_no(),	OFFSET_TRAY_NO,SIZEOF_TRAY_NO);
	addToBuffer(getInvc_no(),	OFFSET_INVC_NO,SIZEOF_INVC_NO);
	addToBuffer(getTime_prom(),	OFFSET_TIME_PROM,SIZEOF_TIME_PROM);
	addToBuffer(get('cust_dispenser'), OFFSET_DISPENSER,SIZEOF_DISPENSER); 

	addToBuffer(getEyeDispense(),	OFFSET_EYE_DISPENSE,SIZEOF_EYE_DISPENSE);
	addToBuffer(getR_sph_int(),	OFFSET_R_SPH_INT,SIZEOF_R_SPH_INT);
	addToBuffer(getR_sph_frac(),	OFFSET_R_SPH_FRAC,SIZEOF_R_SPH_FRAC);
	addToBuffer(getR_sph_sign(),	OFFSET_R_SPH_SIGN,SIZEOF_R_SPH_SIGN);
	addToBuffer(getL_sph_int(),	OFFSET_L_SPH_INT,SIZEOF_L_SPH_INT);
	addToBuffer(getL_sph_frac(),	OFFSET_L_SPH_FRAC,SIZEOF_L_SPH_FRAC);
	addToBuffer(getL_sph_sign(),	OFFSET_L_SPH_SIGN,SIZEOF_L_SPH_SIGN);

	addToBuffer(getR_cyl_int(),	OFFSET_R_CYL_INT,SIZEOF_R_CYL_INT);
	addToBuffer(getR_cyl_frac(),	OFFSET_R_CYL_FRAC,SIZEOF_R_CYL_FRAC);
	addToBuffer(getR_cyl_sign(),	OFFSET_R_CYL_SIGN,SIZEOF_R_CYL_SIGN);
	addToBuffer(getL_cyl_int(),	OFFSET_L_CYL_INT,SIZEOF_L_CYL_INT);
	addToBuffer(getL_cyl_frac(),	OFFSET_L_CYL_FRAC,SIZEOF_L_CYL_FRAC);
	addToBuffer(getL_cyl_sign(),	OFFSET_L_CYL_SIGN,SIZEOF_L_CYL_SIGN);

	addToBuffer(getR_axis(),	OFFSET_R_AXIS,SIZEOF_R_AXIS);
	addToBuffer(getL_axis(),	OFFSET_L_AXIS,SIZEOF_L_AXIS);

	addToBuffer(getR_add_int(),	OFFSET_R_ADD_INT,	SIZEOF_R_ADD_INT);
	addToBuffer(getR_add_frac(),	OFFSET_R_ADD_FRAC,	SIZEOF_R_ADD_FRAC);
	addToBuffer(getR_add_sign(),	OFFSET_R_ADD_SIGN,	SIZEOF_R_ADD_SIGN);
	addToBuffer(getL_add_int(),	OFFSET_L_ADD_INT,	SIZEOF_L_ADD_INT);
	addToBuffer(getL_add_frac(),	OFFSET_L_ADD_FRAC,	SIZEOF_L_ADD_FRAC);
	addToBuffer(getL_add_sign(),	OFFSET_L_ADD_SIGN,	SIZEOF_L_ADD_SIGN);

	addToBuffer(getR_seg1(),	OFFSET_R_SEG1,		SIZEOF_R_SEG1);
	addToBuffer(getR_seg2(),	OFFSET_R_SEG2,		SIZEOF_R_SEG2);
	addToBuffer(getL_seg1(),	OFFSET_L_SEG1,		SIZEOF_L_SEG1);
	addToBuffer(getL_seg2(),	OFFSET_L_SEG2,		SIZEOF_L_SEG2);

	addToBuffer(getR_boc1(),	OFFSET_R_BOC1,		SIZEOF_R_BOC1);
	addToBuffer(getR_boc2(),	OFFSET_R_BOC2,		SIZEOF_R_BOC2);
	addToBuffer(getL_boc1(),	OFFSET_L_BOC1,		SIZEOF_L_BOC1);
	addToBuffer(getL_boc2(),	OFFSET_L_BOC2,		SIZEOF_L_BOC2);

	addToBuffer(getR_pd1(),		OFFSET_R_PD1,		SIZEOF_R_PD1);
	addToBuffer(getR_pd2(),		OFFSET_R_PD2,		SIZEOF_R_PD2);
	addToBuffer(getL_pd1(),		OFFSET_L_PD1,		SIZEOF_L_PD1);
	addToBuffer(getL_pd2(),		OFFSET_L_PD2,		SIZEOF_L_PD2);

	addToBuffer(getR_npd1(),	OFFSET_R_NPD1,		SIZEOF_R_NPD1);
	addToBuffer(getR_npd2(),	OFFSET_R_NPD2,		SIZEOF_R_NPD2);
	addToBuffer(getL_npd1(),	OFFSET_L_NPD1,		SIZEOF_L_NPD1);
	addToBuffer(getL_npd2(),	OFFSET_L_NPD2,		SIZEOF_L_NPD2);

	addToBuffer(getR_mono(),	OFFSET_R_MONO,		SIZEOF_R_MONO);
	addToBuffer(getL_mono(),	OFFSET_L_MONO,		SIZEOF_L_MONO);

	addToBuffer(getTint_pct(),	OFFSET_TINT_PCT,	SIZEOF_TINT_PCT);
	addToBuffer(getTint_desc(),	OFFSET_TINT_DESC,	SIZEOF_TINT_DESC);

	addToBuffer(getMisc_1(),	OFFSET_MISC_1,		SIZEOF_MISC_1);
	addToBuffer(getMisc_1_desc(),	OFFSET_MISC_1_DESC,	SIZEOF_MISC_1_DESC);
	addToBuffer(getMisc_2(),	OFFSET_MISC_2,		SIZEOF_MISC_2);
	addToBuffer(getMisc_2_desc(),	OFFSET_MISC_2_DESC,	SIZEOF_MISC_2_DESC);
	addToBuffer(getMisc_3(),	OFFSET_MISC_3,		SIZEOF_MISC_3);
	addToBuffer(getMisc_3_desc(),	OFFSET_MISC_3_DESC,	SIZEOF_MISC_3_DESC);
	addToBuffer(getMisc_4(),	OFFSET_MISC_4,		SIZEOF_MISC_4);
	addToBuffer(getMisc_4_desc(),	OFFSET_MISC_4_DESC,	SIZEOF_MISC_4_DESC);
	addToBuffer(getMisc_5(),	OFFSET_MISC_5,		SIZEOF_MISC_5);
	addToBuffer(getMisc_5_desc(),	OFFSET_MISC_5_DESC,	SIZEOF_MISC_5_DESC);
	addToBuffer(getMisc_6(),	OFFSET_MISC_6,		SIZEOF_MISC_6);
	addToBuffer(getMisc_6_desc(),	OFFSET_MISC_6_DESC,	SIZEOF_MISC_6_DESC);
	addToBuffer(getMisc_7(),	OFFSET_MISC_7,		SIZEOF_MISC_7);
	addToBuffer(getMisc_7_desc(),	OFFSET_MISC_7_DESC,	SIZEOF_MISC_7_DESC);

	addToBuffer(getR_Enclosed(),	OFFSET_R_ENCL_R,	SIZEOF_R_ENCL_R);
	addToBuffer(getL_Enclosed(),	OFFSET_L_ENCL_R,	SIZEOF_L_ENCL_R);

	addToBuffer(getComment_1(),	OFFSET_COMMENT_1,	SIZEOF_COMMENT_1);
	addToBuffer(getComment_2(),	OFFSET_COMMENT_2,	SIZEOF_COMMENT_2);
	addToBuffer(getComment_3(),	OFFSET_COMMENT_3,	SIZEOF_COMMENT_3);

	addToBuffer(getRedoCode(),	OFFSET_REDO_CODE_R,	SIZEOF_REDO_CODE_R);
	my($circ) = padLeft0(getFdCirc(), SIZEOF_CIRCUMFERENCE);
	addToBuffer($circ,		 OFFSET_CIRCUMFERENCE,	SIZEOF_CIRCUMFERENCE);

	addToBuffer(getFrame_key(),	OFFSET_FRAME_KEY,	SIZEOF_FRAME_KEY);
	addToBuffer(getFrame_desc(),	OFFSET_FRAME_DESC,	SIZEOF_FRAME_DESC);
	addToBuffer(getFrame_color(),	OFFSET_FRAME_COLOR,	SIZEOF_FRAME_COLOR);

	addToBuffer($t_status,		OFFSET_STATUS,		SIZEOF_STATUS);
	addToBuffer(getMount(),		OFFSET_MOUNT,		SIZEOF_MOUNT);
	addToBuffer(getDressSafety(),	OFFSET_DRESS_SAFETY,	SIZEOF_DRESS_SAFETY);
	addToBuffer(getPOF(),		OFFSET_POF,		SIZEOF_POF);
	addToBuffer(getEyeSize(),	OFFSET_EYE_SIZE,	SIZEOF_EYE_SIZE);
	addToBuffer(getBridge(),	OFFSET_BRIDGE,		SIZEOF_BRIDGE);
	addToBuffer(getTemple(),	OFFSET_TEMPLE,		SIZEOF_TEMPLE);

	addToBuffer(getDoctor(),	OFFSET_DOCTOR,		SIZEOF_DOCTOR);
	addToBuffer(getTermperin(),	OFFSET_TERMPERIN,	SIZEOF_TERMPERIN);

	addToBuffer(getA_meas(),	OFFSET_A_MEAS,		SIZEOF_A_MEAS);
	addToBuffer(getB_meas(),	OFFSET_B_MEAS,		SIZEOF_B_MEAS);
	addToBuffer(getEd_meas(),	OFFSET_ED_MEAS,		SIZEOF_ED_MEAS);
	addToBuffer(getDbl_meas(),	OFFSET_DBL_MEAS,	SIZEOF_DBL_MEAS);

	addToBuffer(getMaterial_code(), OFFSET_MATERIAL_CODE,	SIZEOF_MATERIAL_CODE);
	addToBuffer(getStyle_code(),	OFFSET_STYLE_CODE,	SIZEOF_STYLE_CODE);
	addToBuffer(getColor_code(),	OFFSET_COLOR_CODE,	SIZEOF_COLOR_CODE);

	addToBuffer(getR_prism1(),	OFFSET_R_PRISM1,	SIZEOF_R_PRISM1);
	addToBuffer(getR_prism2(),	OFFSET_R_PRISM2,	SIZEOF_R_PRISM2);
	addToBuffer(getL_prism1(),	OFFSET_L_PRISM1,	SIZEOF_L_PRISM1);
	addToBuffer(getL_prism2(),	OFFSET_L_PRISM2,	SIZEOF_L_PRISM2);

	addToBuffer(getR_angle(),	OFFSET_R_ANGLE,	SIZEOF_R_ANGLE);
	addToBuffer(getL_angle(),	OFFSET_L_ANGLE,	SIZEOF_L_ANGLE);

	addToBuffer(getR_curve(),	OFFSET_R_CURVE,	SIZEOF_R_CURVE);
	addToBuffer(getL_curve(),	OFFSET_L_CURVE,	SIZEOF_L_CURVE);


	addToBuffer(get('cust_doctor'),	OFFSET_DOCTOR, SIZEOF_DOCTOR);

	###***BUG**** fw.write(rBuffer,1,RFILE_ACTUAL_SIZE);

	open(F, "> $file\0") or die "Can't create $file ($!)\n";
	print F substr($rBuffer,1).' ' or die "Write failure ($!)\n";
	close(F);

	die unless length($rBuffer) == RFILE_ACTUAL_SIZE;
}

sub map_undef_0 {
	my($v) = @_;

	return 0 unless defined $v;
	return 0 if $v eq '';
	return $v;
}

1;
