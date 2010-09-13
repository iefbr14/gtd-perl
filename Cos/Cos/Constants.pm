
# $Id: Constants.pm,v 1.6 2004/10/12 17:35:00 drew Exp $
# $Source: /var/cvsroot/cos/cos/Cos/Constants.pm,v $

use constant PRISM_DIR_UP               => "Up";
use constant PRISM_DIR_DOWN             => "Down";
use constant PRISM_DIR_IN               => "In";
use constant PRISM_DIR_OUT              => "Out";
use constant PRISM_DIR_ANGLE            => "Angle";

# for "D file" sizes
use constant  SIZEOF_SPEC_INST1 =>		75;
use constant  SIZEOF_SPEC_INST2 =>		75;
use constant  SIZEOF_R_PRISM =>			15;
use constant  SIZEOF_L_PRISM =>			15;
use constant  SIZEOF_R_TYPE =>			10;
use constant  SIZEOF_L_TYPE =>			10;
use constant  SIZEOF_SIZE =>			2;
use constant  SIZEOF_R_BC =>			2;
use constant  SIZEOF_L_BC =>			2;
use constant  SIZEOF_R_ADD =>			5;
use constant  SIZEOF_L_ADD =>			5;

use constant  SIZEOF_MAT =>			15;
use constant  SIZEOF_COLOR =>			12;
use constant  SIZEOF_SPEC_INST3 =>		35;

use constant  SIZEOF_R_ENCL =>			1;
use constant  SIZEOF_L_ENCL =>			1;
use constant  SIZEOF_REDO_CODE =>		3;
use constant  SIZEOF_REDO_LIT =>		35;

# D File
# first 2 fields same as R File
#use constant  OFFSET_STORE =>			1;
#use constant  OFFSET_INVC_NO =>		4;
use constant  OFFSET_SPEC_INST1 =>		8;
use constant  OFFSET_SPEC_INST2 =>		83;
use constant  OFFSET_R_PRISM =>			158;
use constant  OFFSET_L_PRISM =>			173;
use constant  OFFSET_R_TYPE =>			188;
use constant  OFFSET_L_TYPE =>			198;
use constant  OFFSET_SIZE =>			208;

use constant  OFFSET_R_BC =>			210;
use constant  OFFSET_L_BC =>			212;

use constant  OFFSET_R_ADD =>			214;
use constant  OFFSET_L_ADD =>			219;

use constant  OFFSET_MAT =>			224;
use constant  OFFSET_COLOR =>			239;

use constant  OFFSET_SPEC_INST3 =>		251;

use constant  OFFSET_R_ENCL =>			286;
use constant  OFFSET_L_ENCL =>			287;
use constant  OFFSET_REDO_CODE =>		288;
use constant  OFFSET_REDO_LIT =>		391;


# for "R" file sizes
use constant  SIZEOF_STORE =>			3;
use constant  SIZEOF_PATIENT =>			22;
use constant  SIZEOF_DATE_ORD =>		6;
use constant  SIZEOF_DATE_PROM =>		6;
use constant  SIZEOF_TRAY_NO =>			5;
use constant  SIZEOF_INVC_NO =>			4;
use constant  SIZEOF_TIME_PROM =>		6;
use constant  SIZEOF_DISPENSER =>		4;
use constant  SIZEOF_EYE_DISPENSE =>		1; # 1=R,2=L,3=Both
use constant  SIZEOF_R_SPH_INT =>		2;
use constant  SIZEOF_R_SPH_FRAC =>		2;
use constant  SIZEOF_R_SPH_SIGN =>		1;
use constant  SIZEOF_L_SPH_INT =>		2;
use constant  SIZEOF_L_SPH_FRAC =>		2;
use constant  SIZEOF_L_SPH_SIGN =>		1;
use constant  SIZEOF_R_CYL_INT =>		2;
use constant  SIZEOF_R_CYL_FRAC =>		2;
use constant  SIZEOF_R_CYL_SIGN =>		1;
use constant  SIZEOF_L_CYL_INT =>		2;
use constant  SIZEOF_L_CYL_FRAC =>		2;
use constant  SIZEOF_L_CYL_SIGN =>		1;
use constant  SIZEOF_R_AXIS =>			3;
use constant  SIZEOF_L_AXIS =>			3;
use constant  SIZEOF_R_ADD_INT =>		2;
use constant  SIZEOF_R_ADD_FRAC =>		2;
use constant  SIZEOF_R_ADD_SIGN =>		2;
use constant  SIZEOF_L_ADD_INT =>		2;
use constant  SIZEOF_L_ADD_FRAC =>		2;
use constant  SIZEOF_L_ADD_SIGN =>		2;
use constant  SIZEOF_R_SEG1 =>			2;
use constant  SIZEOF_R_SEG2 =>			1;
use constant  SIZEOF_L_SEG1 =>			2;
use constant  SIZEOF_L_SEG2 =>			1;
use constant  SIZEOF_R_BOC1 =>			2;
use constant  SIZEOF_R_BOC2 =>			2;
use constant  SIZEOF_L_BOC1 =>			2;
use constant  SIZEOF_L_BOC2 =>			2;
use constant  SIZEOF_R_PD1 =>			2;
use constant  SIZEOF_R_PD2 =>			1;
use constant  SIZEOF_L_PD1 =>			2;
use constant  SIZEOF_L_PD2 =>			1;
use constant  SIZEOF_R_NPD1 =>			2;
use constant  SIZEOF_R_NPD2 =>			1;
use constant  SIZEOF_L_NPD1 =>			2;
use constant  SIZEOF_L_NPD2 =>			1;
use constant  SIZEOF_R_MONO =>			3;
use constant  SIZEOF_R_MONO_INT =>		2;
use constant  SIZEOF_R_MONO_FRAC =>		1;
use constant  SIZEOF_L_MONO =>			3;
use constant  SIZEOF_L_MONO_INT =>		2;
use constant  SIZEOF_L_MONO_FRAC =>		1;
use constant  SIZEOF_TINT_PCT =>		2;
use constant  SIZEOF_TINT_DESC =>		10;
use constant  SIZEOF_MISC_1 =>			15;
use constant  SIZEOF_MISC_1_DESC =>		25;
use constant  SIZEOF_MISC_2 =>			15;
use constant  SIZEOF_MISC_2_DESC =>		25;
use constant  SIZEOF_MISC_3 =>			15;
use constant  SIZEOF_MISC_3_DESC =>		25;
use constant  SIZEOF_MISC_4 =>			15;
use constant  SIZEOF_MISC_4_DESC =>		25;
use constant  SIZEOF_MISC_5 =>			15;
use constant  SIZEOF_MISC_5_DESC =>		25;
use constant  SIZEOF_MISC_6 =>			15;
use constant  SIZEOF_MISC_6_DESC =>		25;
use constant  SIZEOF_MISC_7 =>			15;
use constant  SIZEOF_MISC_7_DESC =>		25;

use constant  SIZEOF_R_ENCL_R =>		1;
use constant  SIZEOF_L_ENCL_R =>		1;
use constant  SIZEOF_COMMENT_1 =>		30;
use constant  SIZEOF_COMMENT_2 =>		30;
use constant  SIZEOF_COMMENT_3 =>		30;
use constant  SIZEOF_REDO_CODE_R =>		3;
use constant  SIZEOF_CIRCUMFERENCE =>		5;

use constant  SIZEOF_FILLER =>			4;
use constant  SIZEOF_SPECIFY_BASE =>		1;

use constant  SIZEOF_FRAME_KEY =>		15;
use constant  SIZEOF_FRAME_DESC =>		25;
use constant  SIZEOF_FRAME_COLOR =>		10;
use constant  SIZEOF_STATUS =>			1;
use constant  SIZEOF_MOUNT =>			10;
use constant  SIZEOF_DRESS_SAFETY =>		6;
use constant  SIZEOF_POF =>			3;
use constant  SIZEOF_EYE_SIZE =>		2;
use constant  SIZEOF_BRIDGE =>			2;
use constant  SIZEOF_TEMPLE =>			3;
use constant  SIZEOF_DOCTOR =>			3;
use constant  SIZEOF_TERMPERIN =>		2;
use constant  SIZEOF_A_MEAS =>			3;
use constant  SIZEOF_A_MEAS_INT =>		2;
use constant  SIZEOF_A_MEAS_FRAC =>		1;
use constant  SIZEOF_B_MEAS =>			3;
use constant  SIZEOF_B_MEAS_INT =>		2;
use constant  SIZEOF_B_MEAS_FRAC =>		1;
use constant  SIZEOF_ED_MEAS =>			3;
use constant  SIZEOF_ED_MEAS_INT =>		2;
use constant  SIZEOF_ED_MEAS_FRAC =>		1;
use constant  SIZEOF_DBL_MEAS =>		3;
use constant  SIZEOF_DBL_MEAS_INT =>		2;
use constant  SIZEOF_DBL_MEAS_FRAC =>		1;
use constant  SIZEOF_MATERIAL_CODE =>		2;
use constant  SIZEOF_STYLE_CODE =>		3;
use constant  SIZEOF_COLOR_CODE =>		2;

use constant  SIZEOF_R_PRISM1 =>		2;
use constant  SIZEOF_R_PRISM2 =>		2;
use constant  SIZEOF_L_PRISM1 =>		2;
use constant  SIZEOF_L_PRISM2 =>		2;

use constant  SIZEOF_R_ANGLE =>			3;
use constant  SIZEOF_L_ANGLE =>			3;

use constant  SIZEOF_R_CURVE =>			2;
use constant  SIZEOF_L_CURVE =>			2;

# T file sizes
use constant  SIZEOF_TDATA =>			8192;

#
# offsets
#

# R File
use constant  OFFSET_STORE =>			1;
use constant  OFFSET_INVC_NO =>			4;
use constant  OFFSET_FRAME_KEY =>		8;

use constant  OFFSET_A_MEAS =>			23;
use constant  OFFSET_B_MEAS =>			26;
use constant  OFFSET_ED_MEAS =>			29;
use constant  OFFSET_DBL_MEAS =>		32;

use constant  OFFSET_MATERIAL_CODE =>		35;
use constant  OFFSET_STYLE_CODE =>		37;
use constant  OFFSET_COLOR_CODE =>		40;
use constant  OFFSET_EYE_DISPENSE =>		42;

use constant  OFFSET_R_SPH_INT =>		43;
use constant  OFFSET_R_SPH_FRAC =>		45;
use constant  OFFSET_R_SPH_SIGN =>		47;
use constant  OFFSET_L_SPH_INT =>		48;
use constant  OFFSET_L_SPH_FRAC =>		50;
use constant  OFFSET_L_SPH_SIGN =>		52;

use constant  OFFSET_R_CYL_INT =>		53;
use constant  OFFSET_R_CYL_FRAC =>		55;
use constant  OFFSET_R_CYL_SIGN =>		57;
use constant  OFFSET_L_CYL_INT =>		58;
use constant  OFFSET_L_CYL_FRAC =>		60;
use constant  OFFSET_L_CYL_SIGN =>		62;

use constant  OFFSET_R_AXIS =>			63;
use constant  OFFSET_L_AXIS =>			66;

use constant  OFFSET_R_ADD_INT =>		69;
use constant  OFFSET_R_ADD_FRAC =>		71;
use constant  OFFSET_R_ADD_SIGN =>		73;
use constant  OFFSET_L_ADD_INT =>		74;
use constant  OFFSET_L_ADD_FRAC =>		76;
use constant  OFFSET_L_ADD_SIGN =>		78;

use constant  OFFSET_R_SEG1 =>			79;
use constant  OFFSET_R_SEG2 =>			81;
use constant  OFFSET_L_SEG1 =>			82;
use constant  OFFSET_L_SEG2 =>			84;

use constant  OFFSET_R_BOC1 =>			85;
use constant  OFFSET_R_BOC2 =>			87;
use constant  OFFSET_L_BOC1 =>			89;
use constant  OFFSET_L_BOC2 =>			91;

use constant  OFFSET_R_PD1 =>			93;
use constant  OFFSET_R_PD2 =>			95;
use constant  OFFSET_L_PD1 =>			96;
use constant  OFFSET_L_PD2 =>			98;

use constant  OFFSET_R_NPD1 =>			99;
use constant  OFFSET_R_NPD2 =>			101;
use constant  OFFSET_L_NPD1 =>			102;
use constant  OFFSET_L_NPD2 =>			104;

use constant  OFFSET_R_MONO =>			105;
use constant  OFFSET_L_MONO =>			108;

use constant  OFFSET_MISC_1 =>			111;
use constant  OFFSET_MISC_1_DESC =>		126;
use constant  OFFSET_MISC_2 =>			151;
use constant  OFFSET_MISC_2_DESC =>		166;
use constant  OFFSET_MISC_3 =>			191;
use constant  OFFSET_MISC_3_DESC =>		206;
use constant  OFFSET_MISC_4 =>			231;
use constant  OFFSET_MISC_4_DESC =>		246;
use constant  OFFSET_MISC_5 =>			271;
use constant  OFFSET_MISC_5_DESC =>		286;
use constant  OFFSET_MISC_6 =>			311;
use constant  OFFSET_MISC_6_DESC =>		326;
use constant  OFFSET_MISC_7 =>			351;
use constant  OFFSET_MISC_7_DESC =>		366;

use constant  OFFSET_R_ENCL_R =>		391;
use constant  OFFSET_L_ENCL_R =>		392;
use constant  OFFSET_COMMENT_1 =>		393;
use constant  OFFSET_COMMENT_2 =>		423;
use constant  OFFSET_COMMENT_3 =>		453;
use constant  OFFSET_REDO_CODE_R =>		483;
use constant  OFFSET_CIRCUMFERENCE =>		486;

use constant  OFFSET_FILLER =>			491;
use constant  OFFSET_SPECIFY_BASE =>		495;

use constant  OFFSET_TIME_PROM =>		496;
use constant  OFFSET_DRESS_SAFETY =>		502;
use constant  OFFSET_POF =>			508;

use constant  OFFSET_FRAME_DESC =>		511; #510;
use constant  OFFSET_FRAME_COLOR =>		536; #535;
use constant  OFFSET_STATUS =>			546;
use constant  OFFSET_MOUNT =>			547;

use constant  OFFSET_PATIENT =>			557;
use constant  OFFSET_TRAY_NO =>			587;
use constant  OFFSET_DATE_ORD =>		592;
use constant  OFFSET_DATE_PROM =>		598;
use constant  OFFSET_DISPENSER =>		604;

use constant  OFFSET_TEMPLE =>			610;
use constant  OFFSET_EYE_SIZE =>		613;
use constant  OFFSET_BRIDGE =>			615;
use constant  OFFSET_DOCTOR =>			617;
use constant  OFFSET_TERMPERIN =>		620;

use constant  OFFSET_TINT_PCT =>		622;
use constant  OFFSET_TINT_DESC =>		624;

use constant  OFFSET_R_PRISM1 =>		634; #633;
use constant  OFFSET_R_PRISM2 =>		636; #635;
use constant  OFFSET_L_PRISM1 =>		638; #637;
use constant  OFFSET_L_PRISM2 =>		640; #639;

use constant  OFFSET_R_ANGLE =>			642;
use constant  OFFSET_L_ANGLE =>			645;

use constant  OFFSET_R_CURVE =>			648;
use constant  OFFSET_L_CURVE =>			650;

use constant  PI => 3.14159265358979;

#
# packed file size
#
use constant  DFILE_BUFFER_SIZE =>		400;
use constant  RFILE_BUFFER_SIZE =>		700;
use constant  DFILE_ACTUAL_SIZE =>		329;
use constant  RFILE_ACTUAL_SIZE =>		654;

# private set routine which checks for null strings
sub set {
	my($s, $size) = @_;

	$s = '' unless defined $s;
	if (length($s) > $size) {
		my($ltrunc) = substr($s, 0, $size);

#		trace_and_die("truncate [$s] to $size = [$ltrunc]\n");

		return $ltrunc;
	}
	return substr($s, 0, $size);
}

sub padLeft0      { return padLeft(@_, '0'); }
sub padLeftBlanks { return padLeft(@_, ' '); }
sub padRight0      { return padRight(@_, '0'); }
sub padRightBlanks { return padRight(@_, ' '); }

#  Pad left with char ( len = desired length)
sub padLeft {		# ( String s, int len, char c) {
	my($s, $len, $c) = @_;

	$s = '' unless defined $s;
	while (length($s) < $len) {
		$s = $c . $s;
	}
	return $s;
}

#  Pad right with char ( len = desired length)
sub padRight {		# ( String s, int len, char c) {
	my($s, $len, $c) = @_;

	$s = '' unless defined $s;
	while (length($s) < $len) {
		$s .= $c;
	}
	return $s;
}

sub  intPart {		# return just the integer part of the number
	my ($s) = @_;

	return '' unless defined $s;
	if ($s =~ m/^[-+]?(\d+)/) {
		return $1;
	}
	return '';
}

sub fracPart {
	my($s) = @_;

	return '' unless defined $s;
	if ($s =~ m/^([-+]?\d*)\.(\d+)/) {
		return $2;
	}
	return '';
}

sub signPart {
	my($s) = @_;

	return '' if length($s) == 0;
	if ($s =~ m/^([-+])/) {
		return $1;
	}
	return '+';
}


sub NoChoose {
	my($s) = @_;

	return '' if $s eq 'Choose';
	return $s;
}

sub NoChooseNumber {
	my($s) = @_;

	return '00' if $s eq 'Choose';
	return '00' if $s eq '';
	return $s;
}


sub LSChars { # ( String s, int len) {
	my($s, $len) = @_;
	trace_and_die("LSChars s is undefined") unless defined $s;

	# pad s to correct length
	if (length($s) < $len) {
		return sprintf("%-${len}s", $s);
	}

	# trucate on the left to correct length
	return substr($s, length($s)-$len, $len);
}

sub trace_and_die {
	print "******* @_\n";
	for ($i=0 ; ; ++$i) {
		($package, $file, $line) = caller($i);
		last unless defined $package;

		print "+$line $file: $package\n";
	}

#	exit (1);
}


1;
