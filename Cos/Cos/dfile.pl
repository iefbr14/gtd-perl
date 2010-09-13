
@ISA = ( 'Cos::Values' );

my($dBuffer);

my(
	$spec_inst1,	# new char[SIZEOF_SPEC_INST1];
	$spec_inst2,	# new char[SIZEOF_SPEC_INST2];
	$l_prism,	# new char[SIZEOF_L_PRISM];
	$r_type,	# new char[SIZEOF_R_TYPE];
	$l_type,	# new char[SIZEOF_L_TYPE];
	$r_bc,		# new char[SIZEOF_R_BC];
	$l_bc,		# new char[SIZEOF_L_BC];
	$mat,		# new char[SIZEOF_MAT];
	$color,	 	# new char[SIZEOF_COLOR];
	$spec_inst3,	# new char[SIZEOF_SPEC_INST3];
);

sub  getColor		{ return $color; }
sub  getL_bc		{ return $l_bc; }
sub  getL_Type		{ return $l_type; }
sub  getMat		{ return $mat; }
sub  getR_bc		{ return $r_bc; }
sub  getR_Type		{ return $r_type; }
sub  getSpec_inst1	{ return $spec_inst1; }
sub  getSpec_inst2	{ return $spec_inst2; }
sub  getSpec_inst3	{ return $spec_inst3; }

sub  setColor        { $color		= set($_[0], SIZEOF_COLOR); }
sub  setL_bc         { $l_bc		= set($_[0], SIZEOF_L_BC); }
sub  setL_Type       { $l_type		= set($_[0], SIZEOF_L_TYPE); }
sub  setMat          { $mat		= set($_[0], SIZEOF_MAT); }
sub  setR_bc         { $r_bc		= set($_[0], SIZEOF_R_BC); }
sub  setR_prism      { $r_prism		= set($_[0], SIZEOF_R_PRISM); }
sub  setR_Type       { $r_type		= set($_[0], SIZEOF_R_TYPE); }

sub d_set {
	my($s, $off, $len) = @_;

	trace_and_die("d_set s is undefined") unless defined $s;
	substr($dBuffer, $off, $len) = sprintf("%-${len}.${len}s", $s);
#print "D $off.$len = [$s]->[", sprintf("%-${len}.${len}s", $s), "]\n";
}

sub d_write {
	my($file) = @_;

	$dBuffer = " " x (DFILE_ACTUAL_SIZE+1);

	d_convert();
	d_set(getStore(),	OFFSET_STORE,SIZEOF_STORE);
	d_set(getInvc_no(),	OFFSET_INVC_NO,SIZEOF_INVC_NO);

	my($r_add) = padLeft0(intPart (getRx_OD_Add()), SIZEOF_R_ADD_INT)
	           . padRight0(fracPart(getRx_OD_Add()), SIZEOF_R_ADD_FRAC)
	           . signPart(getRx_OD_Add());
	my($l_add) = padLeft0(intPart (getRx_OS_Add()), SIZEOF_L_ADD_INT)
                   . padRight0(fracPart(getRx_OS_Add()), SIZEOF_L_ADD_FRAC)
    		   . signPart(getRx_OS_Add());

	my($size) = padRightBlanks(get('lens_OD_BlankSize'), SIZEOF_SIZE);

	d_set($spec_inst1,	OFFSET_SPEC_INST1,	SIZEOF_SPEC_INST1);
	d_set($spec_inst2,	OFFSET_SPEC_INST2,	SIZEOF_SPEC_INST2);
	d_set($spec_inst3,	OFFSET_SPEC_INST3,	SIZEOF_SPEC_INST3);

	d_set($r_prism,		OFFSET_R_PRISM,		SIZEOF_R_PRISM);
	d_set($l_prism,		OFFSET_L_PRISM,		SIZEOF_L_PRISM);
	d_set($r_type,		OFFSET_R_TYPE,		SIZEOF_R_TYPE);
	d_set($l_type,		OFFSET_L_TYPE,		SIZEOF_L_TYPE);
	d_set($size,		OFFSET_SIZE,		SIZEOF_SIZE);

	d_set($r_bc,		OFFSET_R_BC,		SIZEOF_R_BC);
	d_set($l_bc,		OFFSET_L_BC,		SIZEOF_L_BC);

	d_set($mat,		OFFSET_MAT,		SIZEOF_MAT);
	d_set($color,		OFFSET_COLOR,		SIZEOF_COLOR);

	d_set($r_add,		OFFSET_R_ADD,		SIZEOF_R_ADD);
	d_set($l_add,		OFFSET_L_ADD,		SIZEOF_L_ADD);

	open(F, "> $file\0") or die "Can't create $file ($!)\n";
	print F substr($dBuffer,1,DFILE_ACTUAL_SIZE) or die "Write failure ($!)\n";
	close(F);

	trace_and_die("d_file size incorrect") unless length($dBuffer) == DFILE_ACTUAL_SIZE+1;
}

sub notempty {
	my($v) = @_;

	return 0 if $v eq '';
	return $v;
}

sub d_convert {
	# record fields

	$r_type = undef;
	$l_type = undef;
	$r_bc = undef;
	$l_bc = undef;
	$mat = undef;
	$color = undef;

	my $instructions = getInstructions() .
			( ' ' x (SIZEOF_SPEC_INST1+SIZEOF_SPEC_INST2+SIZEOF_SPEC_INST3 )); 

	$spec_inst1 = substr($instructions, 0, SIZEOF_SPEC_INST1);
	$spec_inst2 = substr($instructions, SIZEOF_SPEC_INST1, SIZEOF_SPEC_INST1+SIZEOF_SPEC_INST2);
	$spec_inst3 = substr($instructions, 
			SIZEOF_SPEC_INST1+SIZEOF_SPEC_INST2,
			SIZEOF_SPEC_INST1+SIZEOF_SPEC_INST2+SIZEOF_SPEC_INST3);

    if( length(getRx_OD_Prism2_Diopters()) != 0 ) {
        $r_prism = sprintf("%5.2f", notempty(getRx_OD_Prism_Diopters())) .
	        "Angle" .
	        padLeftBlanks(getRx_OD_Prism_Angle_Val(),5);
    } else {
        $r_prism = sprintf("%5.2f", notempty(getRx_OD_Prism_Diopters())) .
	        padRightBlanks(getRx_OD_Prism(), 5) .
	        padLeftBlanks(getRx_OD_Prism_Angle_Val(),5);
    }

    if( length(getRx_OS_Prism2_Diopters()) != 0 ) {
        $l_prism = sprintf("%5.2f", notempty(getRx_OS_Prism_Diopters())) .
	        "Angle" .
	        padLeftBlanks(getRx_OS_Prism_Angle_Val(),5);
    } else {
        $l_prism = sprintf("%5.2f", notempty(getRx_OS_Prism_Diopters())) .
	        padRightBlanks(getRx_OS_Prism(), 5) .
	        padLeftBlanks(getRx_OS_Prism_Angle_Val(), 5);
    }

    setR_Type(getLens_OD_Style());
    setL_Type(getLens_OS_Style());

    if( length(getLens_OD_Material()) == 0 ) {
	setMat(getLens_OS_Material());
    } else {
	setMat(getLens_OD_Material());
    }
	
    if( length(getLens_OD_Color()) == 0 ) {
	    setColor(getLens_OS_Color());
    } else {
	    setColor(getLens_OD_Color());
    }
	
    setR_bc(NoChooseNumber(getRx_OD_Special_Base_Curve()));
    setL_bc(NoChooseNumber(getRx_OS_Special_Base_Curve()));
}

1;
