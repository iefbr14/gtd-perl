#!/usr/bin/perl
# $Id: vision.pm,v 1.3 2006/04/13 18:15:48 drew Exp $
# $Source $
#
=head1 USAGE

 use Cos::std;

=item  new - creates a new order undefined record
=item  docutate - does internal consistency checking for orders
=item  viserate - check that all of the new record's fields have be set
=item  validate - check that all of the new record's values are reasonable
=item  dump - dumps to stdout the record
=item  load - loads a record from the database
=item  save - saves a record to the database

=head1 DESCRIPTION

Used to manage orders

=head1 BUGS

This should have been called Cos::order

=cut


package Cos::vision;

use strict;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&vision_parse &vision_gen);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw(&vision_debug);
}
use vars @EXPORT_OK;

use XML::Smart;
use Data::UUID;
use Text::CSV;
use POSIX qw(strftime);

my($Debug) = 0;
my(%Global);
my($Base_id);
my($Base_cnt);
my($Uuid) = new Data::UUID;

my($Store);	load_store();

my($Color_map)    = load_map('colours', 1, 3);
my($Material_map) = load_map('materials', 1, 3);
my($Lens_map)     = load_map('lenstype', 1, 4);

my $Sid = '.2';		# testing: sub id normal
#my $Sid = '';		# production, empty

my(%Vendor) = (
	'+SubmitterId'	=>	'VWLOBLAWS',
	'+Login'	=>	'loblaws',
	'+Password'	=>	'lawslob',
	'+OrderType'	=>	'SP',

	'+VersionNum'	=>	'2.01',

	'+diameter_od_c' =>	70,
	'+diameter_od_p' =>	70,

	'+diameter_os_c' =>	70,
	'+diameter_os_p' =>	70,
	
	'+CbsId'	=>	'1614',		# Prod
#	'+CbsId'	=>	'1478',		# Test
);

sub vision_init {
	%Global = ();

	$Vendor{'+SubmittedDate'} = strftime("%Y-%02m-%02dT%T", localtime());

	$Base_id = '';
	$Base_cnt = 0;
}

sub vision_debug {
	$Debug = shift @_;
}

sub vision_parse {
	my($file) = @_;

	vision_init();

	my($cmd, @arg, $base);

	my($xml) = XML::Smart->new($file);
	my($ref) = {};

	print $xml->dump_tree();

	open(M, "< /home/visionweb/etc/vision.cfg") or die;
	while (<M>) {
		next if /^\s*$/;
		next if /^\s*#/;

		chomp;
		print "M: $_\n" if $Debug;

		($cmd, @arg) = split(' ');

		if ($cmd eq 'base') {
			my $node = shift @arg;

			$Base_id = $node;

			$base = walk($xml, $node);
			next;
		}
		if ($cmd eq 'map') {
			my $to   = shift @arg;
			my $from = shift @arg;

			remember($ref, $to, $from, $base->{$from});
			next;
		}

		if ($cmd eq 'var') {
			var_map($base, @arg);
			next;
		}

		die "Unknown command $cmd\n";
	}
	close(M);

	return $ref;
}

sub vision_gen {
	my($ref) = @_;

	my($xml) = undef;
	eval {
		$xml = vision_gen_real($ref);
	};
	if ($@) {
		warn "Failure lab $ref->{lab_num} order: $ref->{order_id} ($@)\n";
		return undef;
	}
	return $xml;
}

sub vision_gen_real {
	my($ref) = @_;

	vision_init();

	my($cmd, @arg, $base);

	my($xml) = XML::Smart->new();


	$ref->{'+SubmitterOrderId'} = $ref->{lab_num} . '-'
				    . $ref->{cust_num} . '-'
				    . $ref->{order_id} . $Sid;
	$ref->{'+SupplierId'}       = supplier_id($ref);

	# MAGIC Lawblows
	if ($ref->{lab_num} == 137) {
		$ref->{'+VersionNum'}  = '2.05';

	}

	$ref->{'+CbsId'}            = cbsid($ref);
	$ref->{'+SubmitterGuid'}    = $Uuid->create_str();
	$ref->{'+Type'}             = jobtype($ref);

	$ref->{'+Redo'}             = redo_type($ref);
	$ref->{'+Redo_eye_count'}   = redo_eye_count($ref);

	$ref->{'date_ordered'} = fix_date($ref->{'date_ordered'});

	opps($ref, 'rx_od_add', '+00.00', '');
	opps($ref, 'rx_os_add', '+00.00', '');

	opps($ref, 'rx_od_prism', '0.00', '');
	opps($ref, 'rx_os_prism', '0.00', '');

	opps($ref, 'rx_od_seg_height', '00.0', '');
	opps($ref, 'rx_os_seg_height', '00.0', '');

	my($name) = $ref->{patient_name};
	$name = '' unless defined $name;

	my($first, $last) = ('', '');

	if ($name =~ /^(.*), (.*)$/) {
		($last, $first) = ($1, $2);

	} elsif ($name =~ /^(.*) (.*)$/) {
		($first, $last) = ($1, $2);

	} else {
		$last = $name;
		$first = '';
	}
	if ($last eq '') {
		$last = 'ZzzUnknown';
	}

	$ref->{'+first'} = $first;
	$ref->{'+last'} = $last;

	$ref->{'+frame_dbl'} = $ref->{'frame_dbl'} / 2;

	# Convert from CTR or SFY to "center"
	# Note - only populate rx_od_thickness if "Value" = CTR or SFY

	my($thick) = $ref->{'rx_os_thickness'};
print "# os thick: $thick\n";
	if ($thick eq 'CTR' or $thick eq 'SFY') {
		$ref->{'+rx_os_thickness'} = $thick;
		$ref->{'+rx_os_thickref'} = 'center';
	}
	$thick = $ref->{'rx_od_thickness'};
print "# od thick: $thick\n";
	if ($thick eq 'CTR' or $thick eq 'SFY') {
		$ref->{'+rx_od_thickness'} = $thick;
		$ref->{'+rx_od_thickref'} = 'center';
	}

	my $od_matt = sprintf("%03d", $ref->{'lens_od_material_code'});
	my $os_matt = sprintf("%03d", $ref->{'lens_os_material_code'});

	my $od_style = sprintf("%05d", $ref->{'lens_od_style_code'});
	my $os_style = sprintf("%05d", $ref->{'lens_os_style_code'});

	my $od_color = sprintf("%05d", $ref->{'lens_od_color_code'});
	my $os_color = sprintf("%05d", $ref->{'lens_os_color_code'});

	if (!defined $Lens_map->{$od_style}) {
		die "OD map for style: $od_style not defined\n";
	}
	if (!defined $Lens_map->{$os_style}) {
		die "OS map for style: $os_style not defined\n";
	}
	$ref->{'+vw_od_lens'} = $Lens_map->{$od_style};
	$ref->{'+vw_os_lens'} = $Lens_map->{$os_style};


	$ref->{'+cc_od_material'} = "$od_matt-$od_color";
	$ref->{'+cc_os_material'} = "$os_matt-$os_color";

	$ref->{'+vw_od_material'} = substr($Material_map->{$od_matt}
		. '-' . $Color_map->{$od_color},0,18);
	$ref->{'+vw_os_material'} = substr($Material_map->{$os_matt}
		. '-' . $Color_map->{$os_color}, 0, 18);

#	$ref-.{'+rx_od_prism_dir') = 
#	$ref-.{'+rx_os_prism_dir') = 

	$ref->{'+frame_type'} = 1;

	$ref->{'+frame_dbl'} = sprintf("%.2f", $ref->{frame_dbl} / 2);

	my($supress) = 0;
	open(M, "< /home/visionweb/etc/vision.cfg") or die;
	while (<M>) {
		next if /^\s*$/;
		next if /^\s*#/;

		chomp;
		print "M: $_\n" if $Debug;

		($cmd, @arg) = split(' ');

		if ($cmd eq 'base') {
			$supress = 0;

			my $node = shift @arg;
			if (@arg) {
				my $skey = shift @arg;
				if (!defined $ref->{$skey} 
				||  $ref->{$skey} eq '') {
					print "*: supressed by $skey\n";
					$supress = 1;
					next;
				}
			}

			$base = walk($xml, $node);
			next;
		}
		# generating here, from and to are reversed from vision parse
		if ($cmd eq 'map') {
			next if $supress;

			my $from   = shift @arg;
			my $to    = shift @arg;

			next if $from =~ /^\./;
unless (defined $base) {
	print "Can't find base for $to, $from)\n";
	next;
}

			set_xml($base, $to, $ref, $from);
			next;
		}

		if ($cmd eq 'var') {
			var_set($base, @arg);
			next;
		}

		die "Unknown command $cmd\n";
	}
	close(M);

	return $xml;
}

sub walk {
	my($xml, $set) = @_;
	my(@set) = ('ORDER_MSG', split('/', $set));

	my($node) = $xml->base();
	foreach $set (@set) {
		if ($set =~ m/\$/) {
			$node = $Global{$set};
		} else {
			$node=$node->{$set};
		}
		print "Walk: $set", $node->[0], "\n" if $Debug > 2;
	}

	return $node;
}


sub var_map {
	my($base, $global, $key, $val) = @_;

print "gm:$global, key:$key, val:$val\n";
	my($i, $var);

	for ($i=0 ;;++$i) {
		$var = $base->[$i];

		last unless defined $var->{$key};
		last if $var->{$key} eq '';

		if ($var->{$key} eq $val) {
			print "Global $global $key = $val == $i\n";
			$Global{$global} = $var;
			return;
		}
	}
}

sub var_set {
	my($base, $global, $key, $val) = @_;

print "gs:$global, key:$key, val:$val\n";
	my($i, $var);

	$Global{$global} = $var;

#	for ($i=0 ;;++$i) {
#		$var = $base->[$i];
#
#		last unless defined $var;
#	}
	$i = $Base_cnt++;

	print "Createing $i\n";
	$base->[$i]->{$key} = $val;

	$Global{$global} = $base->[$i];
	print "Global $global $key = $val == $i\n";
}

sub remember {
	my($ref, $to, $from, $val) = @_;

	$val = '' unless defined $val;
	print "MAP: $to = $from: $val\n";

	return if $to eq '-';

	if ($to eq '+') {
		$to = '+' . $from;
	}

	$ref->{$to} = $val;
}

sub set_xml {
	my($xml, $to, $ref, $from) = @_;

	return if $from eq '-';

	$from =~ s/^=//;

	if ($from eq '+') {
		$from = $to;
		$from = '+' . $from;
	}

	my($val) = $ref->{$from};

	if (!defined $val && defined $Vendor{$from}) {
		$val = $Vendor{$from};

	} elsif (!defined $val) {
		print "S: $to <- $from not defined\n";
		return;
	}

	print "S: $to <- $from = $val\n";

#	$xml->set_attr($to) = $val;
	$xml->{$to} = $val;
}

sub cc_id {
	my($lab, $cust) = @_;

	return $cust if length($cust) == 6;
	return sprintf("%03d%03d", $lab, $cust);
}

# lab number (3208)
sub supplier_id {
	my($ref) = @_;
	my($id) = cc_id($ref->{lab_num}, $ref->{cust_num});

	die "$id has no mapping" unless $Store->{$id};
	return $Store->{$id}[0];
}

# store number (23184)
sub cbsid {
	my($ref) = @_;
	my($id) = cc_id($ref->{lab_num}, $ref->{cust_num});

	die "$id has no mapping" unless $Store->{$id};
	return $Store->{$id}[1];
}

sub nn {
	my($v) = @_;

	return 0 unless defined $v;
	return $v;
}

sub fix_date {
	my(@l) = split('\D', $_[0]);

	return sprintf("%04d-%02d-%02dT%02d:%02d:%02d", 
		nn($l[0]), nn($l[1]), nn($l[2]),
		nn($l[3]), nn($l[4]), nn($l[5]));
}

# frame_status:
#	UNCUT
#	SUPPLIED
#	ENCLOSED
#	LENSES ONLY
#	TO COME
sub jobtype {
	my($ref) = @_;

	my($dress) = $ref->{frame_dress};
	my($frame_status) = $ref->{frame_status};
	my($frame_edge) = $ref->{frame_edge};

	# encode frame_dress = [0,1]
	$ref->{'+frame_dress'} = '0';
	if ($dress eq 'SAFETY') {
		$ref->{'+frame_dress'} = '1';
		return 'SPA';		# Safety Package
	}

	if ($frame_status eq 'UNCUT') {
		if ($ref->{frame_ed}) {
			return 'FUN';		# fast uncut with ED
		}
		return 'UNC';		# uncut
	}

	if ($frame_status eq 'TO COME') {
		return 'FTC';		# frame to come
	}

	if ($frame_status eq 'LENSES ONLY') {
		return 'RED';		# Remote Edging Lenses only
	}

	if ($frame_status eq 'SUPPLIED') {
		if ($frame_edge eq 'EDGED') {
			return 'ESF';	# Edged Supply Frame
		} else {
			return 'USF';	# Uncut Supply Frame
		}
	}


	#return 'PAC';		# Frame Packages
	return 'TBP';		# Supply Frame
}

sub redo_type {
	my($ref) = @_;

	my($redo) = $ref->{redo_invoice_num};
	$redo = '' unless defined $redo;

	return 'New' if $redo eq '';
	return 'Redo';
#	return 'Resubmit';
}

sub redo_eye_count {
	my($ref) = @_;

	my($rx_eye) = $ref->{rx_eye};

	return 'R' if $rx_eye == 1;
	return 'L' if $rx_eye == 2;
	return 'B';
}

sub load_map {
	my($map, $fid, $tid) = @_;

	$fid--;	# arrays are 0 based.
	$tid--;

	my($ref) = {};
	my(@fields);
	my($csv) = new Text::CSV;

	my($f) = "/home/visionweb/etc/$map.csv";
	open(F, "< $f") or die "Can't load $f ($!)\n";

	while (<F>) {
                chomp;
                                                                                
                next if /^#/;
                                                                                
                next unless $csv->parse($_);

		@fields = $csv->fields();
		if (defined $ref->{$fields[$fid]}) {
			warn "Duplicate field +$. $map.csv: $fields[$fid]\n";
			next;
		}
		$ref->{$fields[$fid]} = $fields[$tid];
	}
	close(F);

	return $ref;
}

sub load_store {
	my($ref) = {};
	my(@fields);
	my($csv) = new Text::CSV;

	my($clab, $cstore, $vlab, $vstore, $name);
	my($f) = "/home/visionweb/etc/store.csv";
	open(F, "< $f") or die "Can't load $f ($!)\n";

	my($id);
	while (<F>) {
                chomp;
                                                                                
                next if /^#/;
                                                                                
                next unless $csv->parse($_);

		($clab, $cstore, $vlab, $vstore, $name) = $csv->fields();
		$id = cc_id($clab, $cstore);
	
		$Store->{$id} = [$vlab, $vstore, $name];
	}
	close(F);

	return $ref;
}

sub opps {
	my($ref, $fld, $val, $newval) = @_;

	if ($ref->{$fld} eq $val) {
		$ref->{$fld} = $newval
	}
}

1;
