#!/usr/bin/perl
#######################################
#
#	name: putorder.cgi
#	purpose:  OpticalOnline OrderValues.java
#			  uses to upload an order
#
#######################################
use DBI;
use CGI qw/:standard :cgi-lib/;
use MIME::Base64;
use Cos::Dbh;
use utf8;
use encoding "utf-8";

my($Progname) = 'cgi';
my($Version) = '1.0.1';

my($dbh) = new Cos::Dbh;
my($Cgi_log) = 0;	# set to 1 to log all requests to /tmp

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# Check the user account
my($retailer) = sql("SELECT user_id,bizname FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
$vars = Vars;
$vars->{ip_address} = $ENV{'REMOTE_ADDR'};
$vars->{ip_name}    = $ENV{'HTTP_HOST'};

$vars->{created_by}    .= ';' . $Progname;
$vars->{agent_version} .= ';' . $Version;

# ***BUG*** need to set user_id
$vars->{user_id}  ||= $vars->{field_acct_id};
$vars->{seq_num}    = get_next_seq($vars->{user_id});

if ($Cgi_log) {
	open(LOG, ">>/tmp/putorder.log");
	print LOG "#####################################################\n";

	foreach $key (sort keys %ENV) {
		print LOG "# $key\t$ENV{$key}\n";
	}
	foreach $parm (sort keys %$vars) {
		print LOG "$parm\t$vars->{$parm}\n";
	}
}

if (defined $vars->{trace_file_data}) {
	$vars->{trace_file_data} = decode_base64($vars->{trace_file_data});
	$vars->{trace_file_size} = length($vars->{trace_file_data});

} elsif ($vars->{redo_order_num}) {
	my($query) = 'select trace_file_data from orders_pending where orders_pending_id = ?';
	my($ref) = sql($query, $vars->{redo_order_num});

	if (defined $ref->{trace_file_data}) {
		$vars->{trace_file_data} = $ref->{trace_file_data};
		$vars->{trace_file_size} = length($vars->{trace_file_data});
	}
}

#$vars->{status} = 'M';

my($query) = 'insert into orders_pending(created_date';
my(@fields) = qw(
	ip_address ip_name agent_version status created_by 
	field_acct_id field_client_name field_client_addr
	combo_orderType instText fdSource frame_status fs1_vendor 
		
	fs1_model fs1_color fs1_upc fdEye fdBridge fdTemple fdA fdB fdED 
	fdDBL lens_Pair lens_OD_Style lens_OD_Material lens_OD_Color 
	lens_OS_Style lens_OS_Material lens_OS_Color tr_Treatment 
	tr_Tinting tr_TintColor tr_TintPerCent tr_Coating tr_AntiReflective 
	tr_Other1 tr_Other2 tr_Other3 tr_Other4 tr_Other5 
		
	rx_OD_Sphere rx_OD_Cylinder rx_OD_Axis rx_OD_Add rx_OD_Near_PD 
	rx_OD_Far_PD rx_OD_Mono_PD rx_OD_Prism_Diopters rx_OD_Prism 
	rx_OD_Prism_Angle_Val rx_OD_Diopters rx_OD_Base rx_OD_Seg_Height 
	rx_OD_OC_Height rx_OD_Special_Base_Curve 
	rx_OD_Thickness_Reference rx_OD_Special_Thickness 
		
	rx_OS_Sphere rx_OS_Cylinder rx_OS_Axis rx_OS_Add rx_OS_Near_PD 
	rx_OS_Far_PD rx_OS_Mono_PD rx_OS_Prism_Diopters rx_OS_Prism 
	rx_OS_Prism_Angle_Val rx_OS_Diopters rx_OS_Base rx_OS_Seg_Height 
	rx_OS_OC_Height rx_OS_Special_Base_Curve rx_OS_Thickness_Reference 
	rx_OS_Special_Thickness tray_no trace_file_data trace_file_size 
		
	user_id lab_id seq_num 
	lens_OD_StyleCode lens_OD_MaterCode lens_OD_ColorCode 
	lens_OS_StyleCode lens_OS_MaterCode lens_OS_ColorCode 
		
	fdCirc fp_mounting fp_edged fp_dress frame_desc
	rx_OD_Prism2_Diopters rx_OD_Prism2 rx_OS_Prism2_Diopters rx_OS_Prism2 
		
	tr_Other1_code tr_Other2_code tr_Other3_code tr_Other4_code tr_Other5_code 
	tr_AR_code tr_Coating_code tr_Tinting_code 
	redo_order_num tr_Treatment_code lens_SV_MF 

	patient_info_Name patient_info_Addr patient_info_Addr2
	patient_info_City patient_info_State patient_info_Pcode
	patient_info_Hphone patient_info_Wphone patient_info_Email 
	patient_info_SSN patient_info_Group patient_info_Plan
	
	ship_name ship_addr1 ship_addr2 ship_city ship_state ship_zip cust_po_num

	extra_info cust_doctor
);

$vars->{frame_desc} = $vars->{fp_mounting} unless (defined $vars->{frame_desc});

if (defined $vars->{rx_os_far}) {
	$vars->{rx_OS_Far_PD}  = $vars->{rx_os_far};
	$vars->{rx_OS_Near_PD} = $vars->{rx_os_near};
	$vars->{rx_OD_Far_PD}  = $vars->{rx_od_far};
	$vars->{rx_OD_Near_PD} = $vars->{rx_od_near};
}
my $extraInfo = "";
if (defined $vars->{deposit} && $vars->{deposit} ne '') {
	$extraInfo = "x_deposit: $vars->{deposit}\n";
}
$vars->{cust_doctor} = $retailer->{bizname};
if (defined $vars->{cust_doctor} && $vars->{cust_doctor} ne '') {
	$extraInfo .= "dr_name:$vars->{cust_doctor}\n";
}

$vars->{extra_info} = $extraInfo;


foreach $field (@fields) {
#	if ($vars->{$field} eq 'Choose') {
#		$vars->{$field} = '';
#	}
	$query .= ",$field";
	push(@values, $vars->{$field});
}
$query .= ') values(now()' . ',?' x scalar(@fields) . ");";

if ($Cgi_log) {
	print LOG "\n", $query, "\n";
}

print <<"EOF";
#
# Version 1.0 putorder.cgi
#
EOF

&sql($query, @values);
my($info) = sql("select last_insert_id()");
my($order) = $info->{'last_insert_id()'};

print "order: $order\n";

#system("/home/cos/bin/rx-mail-order", '-M', $order);

if ($Cgi_log) {
	print LOG "\n", '-' x 76, "\norder: $order\n";
	close(LOG);
}

# seq_num is used in rdt submitted orders as a counter of orders sent by the retailer, since
# it is reset to 0 every night it is only reflecting the day's current order count.
sub get_next_seq {
	my($user_id) = @_;

	&sql("LOCK TABLES retailer WRITE");
	my($row) = &sql("SELECT seq_num FROM retailer WHERE user_id=?", $user_id);

	&sql("UPDATE retailer SET seq_num = seq_num + 1 WHERE user_id=?", $user_id);
	&sql("UNLOCK TABLES ");
	return $row->{'seq_num'}+1;
}
