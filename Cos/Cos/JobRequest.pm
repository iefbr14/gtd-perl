# $Id: JobRequest.pm,v 1.6 2005/03/29 21:56:33 drew Exp $
# $Source $
#
=head1 USAGE

 use Cos::JobRequest;

 $id = function(arg);

=head1 DESCRIPTION

Needs to be written

=cut

package Cos::JobRequest;

use strict;
#use warnings;

use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

my $req;
my ($d_isr, $d_off);
my ($r_isr, $r_off);

my $dateBias = 1;

sub list {
	my($dir) = @_;

	my %jobs;
        my @list = <$dir/*>;

	my($file);
	foreach $file (@list) {
	# 010019l0.01d
	# dddddXXd.dd
		$file =~ s=.*/==;
		if ($file =~ /^(\d+-\d+:\d\d\d\d\d..\d\.\d\d)/) {
			$jobs{"$dir/$1"}++;
			#print "Adding rdt Job: $1\n";
		}
		if ($file =~ /^(\d\d\d\d\d..\d\.\d\d)/) {
			$jobs{"$dir/$1"}++;
			#print "Adding rdt Job: $1\n";
		}

		if ($file =~ /\.rx$/) {
			$jobs{"$dir/$file"}++;
			#print "Adding rx Job: $1\n";
		}
	}

	return sort keys %jobs;
}



sub readfile {
	my($f, $len) = @_;
	my($buf) = '';

	open(F, "< $f\0") or die "Can't open $f ($!)\n";
	if (sysread(F, $buf, $len) != $len) {
		die "Can't read $len bytes from $f ($!)\n";
	}
	return $buf;
}

sub dbcopy {
	my($fld, $len) = @_;
	my($val);

	$val = substr($d_isr, $d_off, $len);
	$d_off += $len;

	return if $fld =~ /^_/;

	$val =~ s/^ *//;
	$val =~ s/ *$//;

	$req->{$fld} = $val;
}

sub rbcopy {
	my($fld, $len) = @_;
	my($val);

	$val = substr($r_isr, $r_off, $len);
	$r_off += $len;

	return if $fld =~ /^_/;

	$val =~ s/^ *//;
	$val =~ s/ *$//;

	$req->{$fld} = $val;
}

sub fix_fld {
	my($fld) = @_;

	my($sign) = $req->{"${fld}_sign"};
	$sign = '' unless defined $sign;
	$req->{$fld} = $sign . 
		       $req->{"${fld}_int"}  . "." .
		       $req->{"${fld}_frac"};

#	delete $req->{"${fld}_sign"};
#	delete $req->{"${fld}_int"};
#	delete $req->{"${fld}_frac"};
}

sub fix_date {
	my($fld) = @_;

	$req->{$fld} =~ m/^(\d\d)(\d\d)(\d\d)/;
	my($m, $d, $y) = ($1,$2,$3);

	$req->{$fld} = (2000+$y) . '-' . $m . '-' . $d;
}

sub fix_time {
	my($fld) = @_;
#print "fix_time($fld) $req->{$fld}\n";
	$req->{$fld} =~ m/^(\d\d):(\d\d)(.)/;
	my($h, $m, $am) = ($1,$2,$3);

	if (lc($am) eq 'p') {
		$h += 12;
	}
	$req->{$fld} = sprintf("%02d:%02d:00", $h, $m);
}

sub load {
	my($file) = @_;

	my($lab, $cust, $month, $day, $seq) = unmapname($file);

	#print "$file-> $lab $cust  $month $day $seq\n";

	$req = {};

	$req->{seq_no} = $seq;
	$req->{lab_no} = $lab;
	$req->{raw_store} = $cust;
	$req->{file_date} = "$month-$day";


	$d_isr = readfile($file . 'd', 329); $d_off = 0;
	$r_isr = readfile($file . 'r', 654); $r_off = 0;

	my($t_size) = -s ($file . 't');
	$req->{trace_file_size} = $t_size;
	if ($t_size) {
		my($t_isr) = readfile($file . 't', $t_size); 
		$req->{trace_file_data} = $t_isr;
	}

	dbcopy( "store",		  3);
	dbcopy( "invc_no",		  4);
	dbcopy( "spec_inst1",		 75);
	dbcopy( "spec_inst2",		 75);
	dbcopy( "r_prism_amt",		  5);
	dbcopy( "r_prism_dir",	    	  5);
	dbcopy( "r_prism_ang",		  5);
	dbcopy( "l_prism_amt",		  5);
	dbcopy( "l_prism_dir",		  5);
	dbcopy( "l_prism_ang",		  5);
	dbcopy( "r_type",		 10);
	dbcopy( "l_type",		 10);
	dbcopy( "blank_size",		  2);
	dbcopy( "r_bc",			  2);
	dbcopy( "l_bc",			  2);
	dbcopy( "_r_add",		  4);
	dbcopy( "_r_add_sign",		  1);
	dbcopy( "_l_add",		  4);
	dbcopy( "_l_add_sign",		  1);
	dbcopy( "mat",			 15);
	dbcopy( "color",		 12);
	dbcopy( "spec_inst3",		 35);
	dbcopy( "r_enclosed",		  1);
	dbcopy( "l_enclosed",		  1);
	dbcopy( "_redo_code",		  3);
	dbcopy( "redo_lit",		 35);
	dbcopy( "_filler",		  1);


	rbcopy( "store",		 3);
	rbcopy( "invc_no",		 4);
	rbcopy( "frame_key",		 15);
	rbcopy( "a_meas",		 3);
	rbcopy( "b_meas",		 3);
	rbcopy( "ed_meas",		 3);
	rbcopy( "dbl_meas",		 3);
	rbcopy( "material",		 2);
	rbcopy( "lens_type",		 3);
	rbcopy( "lens_color",		 2);
	rbcopy( "eye",			 1);
	rbcopy( "r_sph_int",		 2);
	rbcopy( "r_sph_frac",		 2);
	rbcopy( "r_sph_sign",		 1);	fix_fld('r_sph');
	rbcopy( "l_sph_int",		 2);
	rbcopy( "l_sph_frac",		 2);
	rbcopy( "l_sph_sign",		 1);	fix_fld('l_sph');
	rbcopy( "r_cyl_int",		 2);
	rbcopy( "r_cyl_frac",		 2);
	rbcopy( "r_cyl_sign",		 1);	fix_fld('r_cyl');
	rbcopy( "l_cyl_int",		 2);
	rbcopy( "l_cyl_frac",		 2);
	rbcopy( "l_cyl_sign",		 1);	fix_fld('l_cyl');
	rbcopy( "r_axis",		 3);
	rbcopy( "l_axis",		 3);
	rbcopy( "r_add_int",		 2);
	rbcopy( "r_add_frac",		 2);
	rbcopy( "r_add_sign",		 1);	fix_fld('r_add');
	rbcopy( "l_add_int",		 2);
	rbcopy( "l_add_frac",		 2);
	rbcopy( "l_add_sign",		 1);	fix_fld('l_add');
	rbcopy( "r_seg_int",		 2);
	rbcopy( "r_seg_frac",		 1);	fix_fld('r_seg');
	rbcopy( "l_seg_int",		 2);	
	rbcopy( "l_seg_frac",		 1);	fix_fld('l_seg');
	rbcopy( "r_boc_int",		 2);
	rbcopy( "r_boc_frac",		 2);	fix_fld('r_boc');
	rbcopy( "l_boc_int",		 2);
	rbcopy( "l_boc_frac",		 2);	fix_fld('l_boc');
	rbcopy( "r_pd_int",		 2);
	rbcopy( "r_pd_frac",		 1);	fix_fld('r_pd');
	rbcopy( "l_pd_int",		 2);
	rbcopy( "l_pd_frac",		 1);	fix_fld('l_pd');
	rbcopy( "r_npd_int",		 2);
	rbcopy( "r_npd_frac",		 1);	fix_fld('r_npd');
	rbcopy( "l_npd_int",		 2);
	rbcopy( "l_npd_frac",		 1);	fix_fld('l_npd');
	rbcopy( "r_mono",		 3);
	rbcopy( "l_mono",		 3);
	rbcopy( "misc_1",		 15);
	rbcopy( "misc_1_desc",		 25);
	rbcopy( "misc_2",		 15);
	rbcopy( "misc_2_desc",		 25);
	rbcopy( "misc_3",		 15);
	rbcopy( "misc_3_desc",		 25);
	rbcopy( "misc_4",		 15);
	rbcopy( "misc_4_desc",		 25);
	rbcopy( "misc_5",		 15);
	rbcopy( "misc_5_desc",		 25);
	rbcopy( "misc_6",		 15);
	rbcopy( "misc_6_desc",		 25);
	rbcopy( "misc_7",		 15);
	rbcopy( "misc_7_desc",		 25);
	rbcopy( "l_enclosed",		 1);
	rbcopy( "r_enclosed",		 1);
	rbcopy( "comment_1",		 30);
	rbcopy( "comment_2",		 30);
	rbcopy( "comment_3",		 30);
	rbcopy( "redo_code",		 3);
	rbcopy( "circumferance",	 5);
	rbcopy( "_filler",		 4);
#	rbcopy( "_filler",		 9);
#	rbcopy( "_filler",		 104);
	rbcopy( "specify_base",		 1);
	rbcopy( "time_prom",		 6);	fix_time('time_prom');
	rbcopy( "dress_safety",		 6);
	rbcopy( "pof",			 3);
	rbcopy( "frame_desc",		 25);
	rbcopy( "frame_color",		 10);
	rbcopy( "status",		 1);
	rbcopy( "mount",		 10);
	rbcopy( "patient",		 28);
	rbcopy( "l_finish",		 1);
	rbcopy( "r_finish",		 1);
	rbcopy( "tray_no",		 5);
	rbcopy( "date_ord",		 6 );	fix_date('date_ord');
	rbcopy( "date_prom",		 6 );	fix_date('date_prom');
	rbcopy( "dispenser",		 4);
	rbcopy( "vert_dec",		 2 );
	rbcopy( "temple",		 3 );
	rbcopy( "eye_size",		 2);
	rbcopy( "bridge",		 2);
	rbcopy( "doctor",		 3);
	rbcopy( "termperin",		 2);
	rbcopy( "tint_pct",		 2);
	rbcopy( "tint_desc",		 10);
	rbcopy( "r_prism1",		 2);
	rbcopy( "r_prism2",		 2);
	rbcopy( "l_prism1",		 2);
	rbcopy( "l_prism2",		 2);
	rbcopy( "r_angle",		 3);
	rbcopy( "l_angle",		 3);
	rbcopy( "r_curve",		 2);
	rbcopy( "l_curve",		 2);
	rbcopy( "_filler",		 1);

	$req->{date_prom} .= ' ' . $req->{time_prom};
	$req->{comments} = sprintf("%-30s%-30s%s", 
		$req->{comment_1},
		$req->{comment_2},
		$req->{comment_3});

#	if ($req->{eye_buffer)
#		if( eye_buffer[0] == '1' ) pair = "R";
#		if( eye_buffer[0] == '2' ) pair = "L";
#		if( eye_buffer[0] == '3' ) pair = "B";

	$req->{pair} = substr("RLB", $req->{eye}-1, 1);

#### leading '+' ok in perl
#		if( r_bc_buffer[0] == '+' ) r_bc_buffer[0] = '0';
#		if( l_bc_buffer[0] == '+' ) l_bc_buffer[0] = '0';
#

		$req->{r_prism} = 
			$req->{r_prism_amt} . " " .
		        $req->{r_prism_dir} . " " .
		        $req->{r_prism_ang};

		$req->{l_prism} = 
			$req->{l_prism_amt} . " " .
		        $req->{l_prism_dir} . " " .
		        $req->{l_prism_ang};

		$req->{tray_no} ||= 0;

		my %Status = (
			'1' => "SUPPLY",
			'2' => "ENCLOSED",
			'3' => "TO-COME",
			'4' => "LENSES-ONLY",
			'5' => "UNCUT",
		);
		$req->{status} = $Status{$req->{status}} || 'UNKNOWN';

	return $req;
}

sub dump {
	my($req) = @_;
	my($key);

	foreach $key (sort keys %$req) {
		print "$key: $req->{$key}\n";
	}
}

sub create {
}

sub unmapname {
	my($name) = @_;

	my($lab, $cust, $sublab, $user, $month, $day, $s1, $s2);
	my($seq);

	$name =~ s=.*\/==;

#                                            month  day
#                          lab   user   --  cust |  |  s1    s2
	unless ($name =~ /^(\d+)-(\d+):(..)(...)(.)(.)(.)\.(..)/) {
#                          1     2     3   4    5  6  7     8
		die "Can't map name: $name";
	}

	($lab, $user, $sublab, $cust, $month, $day, $s1,$s2) 
		= ($1,$2, $3,$4, $5,$6, $7,$8);

	$month = index('123456789ABC', uc($month)) + 1;
	$day   = index('123456789ABCDEFGHIJKLMNOPQRSTUV', uc($day)) + 1;

	check_valid_cust($lab, $user, $cust);

	return ($lab, $user, $month, $day, $s1 . $s2);
}

sub check_valid_cust {
        my($lab, $user, $cust) = @_;
        my($dbh) = Cos::Dbh::new();
        my($ref);

#        print <<"EOF";
#**************** update  lab_customer_id set customer_id = $cust
#**************** where lab_id = $lab and user_id = $user and customer_id = 0;
#EOF

        my($sth) = $dbh->prepare(<<"EOF");
update  lab_customer_id set customer_id = ?
where lab_id = ? and user_id = ? and customer_id = 0
EOF

        $sth->execute($cust, $lab, $user);
}


# old shell encoder:
#
#	FILES=`find . -name '[0-9][0-9]*.[rR]'`
#	
#	if [ "x" != "x$FILES" ]
#	then
#	   for fnam in [0-9][0-9]*.[rR]
#	   do
#	      onam=`expr substr $fnam 1 12`
#	      lab=`expr substr $fnam 1 2`
#	      cust=`expr substr $fnam 3 3`
#	      month=`expr substr $fnam 6 2`
#	      day=`expr substr $fnam 8 2`
#	      seq_p1=`expr substr $fnam 10 1`
#	      seq_p2=`expr substr $fnam 11 2`
#	
#	    newnam="$lab$cust$emonth$eday$seq_p1.$seq_p2"
#	    mv $onam.[Rr] $newnam"r"
#	    if [ -f $onam".D" -o -f $onam".d" ]
#	    then
#	        mv $onam.[Dd] $newnam"d"
#	    fi
#	    if [ -f $onam".T" -o -f $onam".t" ]
#	    then
#	        mv $onam.[Tt] $newnam"t"
#	    fi
#	  done;
#	fi


1;
