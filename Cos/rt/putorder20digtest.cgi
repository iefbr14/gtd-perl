#!/usr/bin/perl
#######################################
#
#	name: putorder.cgi
#	purpose:  OpticalOnline OrderValues.java
#			  	uses to upload an order
#
#######################################
use DBI;
use Time::Local 'timelocal';
use CGI qw/:standard :cgi-lib/;
use MIME::Base64;
use Cos::Dbh;

my($Progname) = 'cgi';
my($Version) = '2.0';

my($dbh) = new Cos::Dbh;
my($Cgi_log) = 0;	# set to 1 to log all requests to /tmp

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# all these authorizations are incorrectly authenticating against user_id which is an integer field
# the database needs a fix, all Users.U_Username fields need to be copied to retailer.username
# then this changes to validate against username not user_id.
my($retailer) = sql("SELECT user_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);
unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

my($user) = sql("SELECT U_Type FROM Users WHERE U_InfoId=? ", $user);
if ($user->{U_Type} eq "W") {
	#plugging a hole in versions 1.5.7 and 1.5.8 which left enabled
	#the 'Start Over' button on the History Panel for all users
	print "# Auth Failure.\n";
	exit 0;
}

####################################################
$vars = Vars;
$vars->{ip_address} = $ENV{'REMOTE_ADDR'};
$vars->{ip_name}    = $ENV{'HTTP_HOST'};

$vars->{created_by}    .= ';' . $Progname;
$vars->{agent_version} .= ';' . $Version;

$vars->{user_id}  ||= $vars->{field_acct_id};		# ***BUG*** make sure user_id is sent
$vars->{seq_num}    = get_next_seq($vars->{user_id});

if ($Cgi_log) {
	open(LOG, ">>/tmp/putorder20.log");
	print LOG "############################################\n";
	#foreach $key (sort keys %ENV) {
		#print LOG "# $key\t$ENV{$key}\n";
	#}
	foreach $parm (sort keys %$vars) {
		print LOG "$parm\t$vars->{$parm}\n";
	}
}
####################################################

if (defined $vars->{trace_file_data}) {
	$vars->{trace_file_data} = decode_base64($vars->{trace_file_data});
	$vars->{trace_file_size} = length($vars->{trace_file_data});

} elsif ($vars->{redo_order_num}) {
	my($query) = 'SELECT trace_file_data FROM orders_pending WHERE orders_pending_id = ?';
	my($ref) = sql($query, $vars->{redo_order_num});

	if (defined $ref->{trace_file_data}) {
		$vars->{trace_file_data} = $ref->{trace_file_data};
		$vars->{trace_file_size} = length($vars->{trace_file_data});
	}
}

my($query) = 'INSERT INTO orders_pending(created_date';
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
	$extraInfo = "x_deposit:$vars->{deposit}\n";
}
if (defined $vars->{OCHeightQual} && $vars->{OCHeightQual} ne '') {
	$extraInfo .= "x_rx_oc_height_qual:$vars->{OCHeightQual}\n";
}
if (defined $vars->{lab_invoice} && $vars->{lab_invoice} ne '') {
	$extraInfo .= "x_use_trace_from:$vars->{lab_invoice}\n";
}
if (defined $vars->{cust_doctor} && $vars->{cust_doctor} ne '') {
	$extraInfo .= "dr_name:$vars->{cust_doctor}\n";
}
####
if (defined $vars->{x_uncut_by_diam} && $vars->{x_uncut_by_diam} ne '') {
	$extraInfo .= "x_uncut_by_diam:$vars->{x_uncut_by_diam}\n";
}
if (defined $vars->{x_os_uncut_diam} && $vars->{x_os_uncut_diam} ne '') {
	$extraInfo .= "x_os_uncut_diam:$vars->{x_os_uncut_diam}\n";
}
if (defined $vars->{x_od_uncut_diam} && $vars->{x_od_uncut_diam} ne '') {
	$extraInfo .= "x_od_uncut_diam:$vars->{x_od_uncut_diam}\n";
}
####
if (defined $vars->{digitalData} && ($vars->{digitalData} eq "true"  || $vars->{digitalData} eq "Y")) {
	$extraInfo .= "digitalData:$vars->{digitalData}\n";
	
	if (defined $vars->{cllnam_os} && $vars->{cllnam_os} ne '') {
		$extraInfo .= "cllnam_os:$vars->{cllnam_os}\n";
	}	
	if (defined $vars->{cllife_os} && $vars->{cllife_os} ne '') {
		$extraInfo .= "cllife_os:$vars->{cllife_os}\n";
	}
	if (defined $vars->{rvd_os} && $vars->{rvd_os} ne '') {
		$extraInfo .= "rvd_os:$vars->{rvd_os}\n";
	}
	if (defined $vars->{rvd_od} && $vars->{rvd_od} ne '') {
		$extraInfo .= "rvd_od:$vars->{rvd_od}\n";
	}
	if (defined $vars->{bvd_os} && $vars->{bvd_os} ne '') {
		$extraInfo .= "bvd_os:$vars->{bvd_os}\n";
	}
	if (defined $vars->{bvd_od} && $vars->{bvd_od} ne '') {
		$extraInfo .= "bvd_od:$vars->{bvd_od}\n";
	}
	if (defined $vars->{panto_os} && $vars->{panto_os} ne '') {
		$extraInfo .= "panto_os:$vars->{panto_os}\n";
	}
	if (defined $vars->{panto_od} && $vars->{panto_od} ne '') {
		$extraInfo .= "panto_od:$vars->{panto_od}\n";
	}
	if (defined $vars->{ztilt_os} && $vars->{ztilt_os} ne '') {
		$extraInfo .= "ztilt_os:$vars->{ztilt_os}\n";
	}
	if (defined $vars->{ztilt_od} && $vars->{ztilt_od} ne '') {
		$extraInfo .= "ztilt_od:$vars->{ztilt_od}\n";
	}
	if (defined $vars->{viewpDIST_os} && $vars->{viewpDIST_os} ne '') {
		$extraInfo .= "viewpDIST_os:$vars->{viewpDIST_os}\n";
	}
	if (defined $vars->{viewpDIST_od} && $vars->{viewpDIST_od} ne '') {
		$extraInfo .= "viewpDIST_od:$vars->{viewpDIST_od}\n";
	}
	if (defined $vars->{viewpANG_os} && $vars->{viewpANG_os} ne '') {
		$extraInfo .= "viewpANG_os:$vars->{viewpANG_os}\n";
	}
	if (defined $vars->{viewpANG_od} && $vars->{viewpANG_od} ne '') {
		$extraInfo .= "viewpANG_od:$vars->{viewpANG_od}\n";
	}
} else{
		$extraInfo .= "digitalData:N\n";
}
####
if (defined $vars->{x_medicaid_lastservice} && $vars->{x_medicaid_lastservice} ne '') {
	$extraInfo .= "x_medicaid_lastservice:$vars->{x_medicaid_lastservice}\n";
}
if (defined $vars->{x_medical_recnum} && $vars->{x_medical_recnum} ne '') {
	$extraInfo .= "x_medicaid_id:$vars->{x_medical_recnum}\n";
}
if (defined $vars->{x_medicaid_recdate} && $vars->{x_medicaid_recdate} ne '') {
	$extraInfo .= "x_medicaid_recdate:$vars->{x_medicaid_recdate}\n";
}
if (defined $vars->{x_medicaid_panumber} && $vars->{x_medicaid_panumber} ne '') {
	$extraInfo .= "x_medicaid_panumber:$vars->{x_medicaid_panumber}\n";
}
if (defined $vars->{x_medicaid_pareason} && $vars->{x_medicaid_pareason} ne '') {
	$extraInfo .= "x_medicaid_pareason:$vars->{x_medicaid_pareason}\n";
}
if (defined $vars->{x_dprovider_name} && $vars->{x_dprovider_name} ne '') {
	$extraInfo .= "x_dprovider_name:$vars->{x_dprovider_name}\n";
}
if (defined $vars->{x_dprovider_today} && $vars->{x_dprovider_today} ne '') {
	$extraInfo .= "x_dprovider_today:$vars->{x_dprovider_today}\n";
}
if (defined $vars->{x_dprovider_medicaidid} && $vars->{x_dprovider_medicaidid} ne '') {
	$extraInfo .= "x_dprovider_medicaidid:$vars->{x_dprovider_medicaidid}\n";
}
if (defined $vars->{x_dprovider_npi} && $vars->{x_dprovider_npi} ne '') {
	$extraInfo .= "x_dprovider_npi:$vars->{x_dprovider_npi}\n";
}
if (defined $vars->{x_dprovider_account} && $vars->{x_dprovider_account} ne '') {
	$extraInfo .= "x_dprovider_account:$vars->{x_dprovider_account}\n";
}
if (defined $vars->{x_dprovider_telephone} && $vars->{x_dprovider_telephone} ne '') {
	$extraInfo .= "x_dprovider_telephone:$vars->{x_dprovider_telephone}\n";
}
if (defined $vars->{x_dprovider_email} && $vars->{x_dprovider_email} ne '') {
	$extraInfo .= "x_dprovider_email:$vars->{x_dprovider_email}\n";
}
if (defined $vars->{x_dprovider_address1} && $vars->{x_dprovider_address1} ne '') {
	$extraInfo .= "x_dprovider_address1:$vars->{x_dprovider_address1}\n";
}
if (defined $vars->{x_dprovider_address2} && $vars->{x_dprovider_address2} ne '') {
	$extraInfo .= "x_dprovider_address2:$vars->{x_dprovider_address2}\n";
}
if (defined $vars->{x_dprovider_city} && $vars->{x_dprovider_city} ne '') {
	$extraInfo .= "x_dprovider_city:$vars->{x_dprovider_city}\n";
}
if (defined $vars->{x_dprovider_state} && $vars->{x_dprovider_state} ne '') {
	$extraInfo .= "x_dprovider_state:$vars->{x_dprovider_state}\n";
}
if (defined $vars->{x_dprovider_zip} && $vars->{x_dprovider_zip} ne '') {
	$extraInfo .= "x_dprovider_zip:$vars->{x_dprovider_zip}\n";
}
if (defined $vars->{x_dprovider_county} && $vars->{x_dprovider_county} ne '') {
	$extraInfo .= "x_dprovider_county:$vars->{x_dprovider_county}\n";
}
if (defined $vars->{x_pprovider_name} && $vars->{x_pprovider_name} ne '') {
	$extraInfo .= "x_pprovider_name:$vars->{x_pprovider_name}\n";
}
if (defined $vars->{x_pprovider_medicaidid} && $vars->{x_pprovider_medicaidid} ne '') {
	$extraInfo .= "x_pprovider_medicaidid:$vars->{x_pprovider_medicaidid}\n";
}
if (defined $vars->{x_pprovider_npi} && $vars->{x_pprovider_npi} ne '') {
	$extraInfo .= "x_pprovider_npi:$vars->{x_pprovider_npi}\n";
}
if (defined $vars->{x_pprovider_scriptdate} && $vars->{x_pprovider_scriptdate} ne '') {
	$extraInfo .= "x_pprovider_scriptdate:$vars->{x_pprovider_scriptdate}\n";
}
if (defined $vars->{x_pa_lastname} && $vars->{x_pa_lastname} ne '') {
	$extraInfo .= "x_pa_lastname:$vars->{x_pa_lastname}\n";
}
if (defined $vars->{x_pa_firstname} && $vars->{x_pa_firstname} ne '') {
	$extraInfo .= "x_pa_firstname:$vars->{x_pa_firstname}\n";
}
if (defined $vars->{x_pa_medicaidid} && $vars->{x_pa_medicaidid} ne '') {
	$extraInfo .= "x_pa_medicaidid:$vars->{x_pa_medicaidid}\n";
}
if (defined $vars->{x_pa_dob} && $vars->{x_pa_dob} ne '') {
	$extraInfo .= "x_pa_dob:$vars->{x_pa_dob}\n";
}
if (defined $vars->{x_pa_address} && $vars->{x_pa_address} ne '') {
	$extraInfo .= "x_pa_address:$vars->{x_pa_address}\n";
}
if (defined $vars->{x_medicaid_data_present} && $vars->{x_medicaid_data_present} ne '') {
	$extraInfo .= "x_medicaid_data_present:$vars->{x_medicaid_data_present}\n";
}
if (defined $vars->{cbo_eye} && $vars->{cbo_eye} ne '') {
	$extraInfo .= "cbo_eye:$vars->{cbo_eye}\n";
}
if (defined $vars->{cbo_bridge} && $vars->{cbo_bridge} ne '') {
	$extraInfo .= "cbo_bridge:$vars->{cbo_bridge}\n";
}
if (defined $vars->{x_paying_agent_id} && $vars->{x_paying_agent_id} ne '') {
	$extraInfo .= "x_paying_agent_id:$vars->{x_paying_agent_id}\n";
}

$vars->{extra_info} = $extraInfo;

foreach $field (@fields) {
	$query .= ",$field";
	push(@values, $vars->{$field});
}
$query .= ') values(now()' . ',?' x scalar(@fields) . ");";

unless (&handle_per_click($vars->{user_id},$vars->{lab_id})) {
	print "\norder:0\n";
	exit();
}

print <<"EOF";
#
# Version 2.0 putorder.cgi
#
EOF

&sql($query, @values);		# do the INSERT INTO
my($info) = sql("SELECT last_insert_id()");
my($order) = $info->{'last_insert_id()'};
print "order: $order\n";

if ($Cgi_log) {
	print LOG "\n", $query, "\n";
	print LOG "\norder: $order\n";
	print LOG "############################################\n";
	close(LOG);
}

#####################################################
#
#	subroutine: get_next_seq
#
#  seq_num is used in rdt submitted orders as a counter of orders sent
#  by the retailer. it is reset to 0 every night. it is only reflecting the day's
#  current order count.
#
#####################################################
sub get_next_seq {
	my($user_id) = @_;

	&sql("LOCK TABLES retailer WRITE");
	my($row) = &sql("SELECT seq_num FROM retailer WHERE user_id=?", $user_id);

	&sql("UPDATE retailer SET seq_num = seq_num + 1 WHERE user_id=?", $user_id);
	&sql("UNLOCK TABLES ");
	return $row->{'seq_num'}+1;
}

#####################################################
#
#	subroutine: handle_per_click
#  purpose: handle the per click business
#
#####################################################
sub handle_per_click {

	my($user_id, $lab_id) = @_;
	my $click_query;
	# if per_click is 0 then we are not counting clicks
	$click_query = "SELECT unix_timestamp(per_click) FROM lab_customer_id WHERE user_id=$user_id AND lab_id=$lab_id";
	$sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
	$sth->execute or die "Can't execute: $click_query. Reason: $!";
	my ($start_time) = $sth->fetchrow_array;
	
	if ($start_time eq 0) {
		return -1;
	}
	# we are counting clicks
	else  {
		# the latest per_click  record for this user_id and lab_id will have '0000-00-00 00:00:00'
		# in the per_click_Stop field and the same per_click_Start as the lab_customer_id record
		$click_query =	"SELECT count, MONTH(per_click_Start) as month_start ".
								"FROM per_click_history WHERE ".
								"user_id=$user_id AND lab_id=$lab_id AND ".
								"unix_timestamp(per_click_Start) >= $start_time AND ".
								"per_click_Stop = '0000-00-00 00:00:00'";

	    $sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
	    $sth->execute or die "Can't execute: $click_query. Reason: $!";
	    my($current_count, $start_month) = $sth->fetchrow_array;
	    my $cur_month = (localtime(time))[4] + 1;
		# if we are still in the same month
		if ($cur_month == $start_month) {
			$current_count++;
			$click_query = "UPDATE per_click_history SET count =  $current_count ".
								"WHERE user_id=$user_id AND lab_id=$lab_id AND ".
								"unix_timestamp(per_click_Start) = $start_time AND ".
								"unix_timestamp(per_click_Stop) = 0 ";
    		$sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
    		$sth->execute or die "Can't execute: $click_query. Reason: $!";
    		$clickref = $sth->fetchrow_hashref;
    	}
    	# else the month has rolled over so
    	else {
         	# update the lab_customer_id record, set per_click = first day of the current_month
         	my $cur_year = (localtime(time))[5] + 1900;
         	$click_query =	"UPDATE lab_customer_id SET per_click = '$cur_year-$cur_month-01 00:00:00' ".
									"WHERE user_id = $user_id AND lab_id = $lab_id";
    		$sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
    		$sth->execute or die "Can't execute: $click_query. Reason: $!";

			# signal last month's counter as closed by setting the per_click_Stop date as the end of last_month
			my $stop_month = ($cur_month-1)==0 ? '12' : $cur_month-1;
			my $stop_year = ($stop_month == 12) ? $cur_year-1 : $cur_year; 
			my $last_day = &lastDay($stop_month);
			$click_query =	"UPDATE per_click_history SET per_click_Stop = '$stop_year-$stop_month-$last_day 23:59:59' ".
									"WHERE user_id=$user_id AND lab_id=$lab_id AND ".
									"unix_timestamp(per_click_Start) >= $start_time AND ".
									"per_click_Stop = '0000-00-00 00:00:00'";
			$sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
			$sth->execute  or die "Can't execute: $click_query. Reason: $!";
			# create a new per_click record, per_click_Start is the first of the current_month
			$click_query =	"INSERT INTO per_click_history SET user_id = $user_id, lab_id = $lab_id, count = 1, ".
									"per_click_Start = '$cur_year-$cur_month-01 00:00:00', per_click_Stop = 0";
    		$sth = $dbh->prepare ($click_query) or die "Can't prepare: $click_query. Reason: $!";
    		$sth->execute                 or die "Can't execute: $click_query. Reason: $!";
    	}
	}
	return 1;
}

##################################################
#
#	subroutine:  lastDay
#  what is the last day of the given month (1-12)
#
##################################################
sub lastDay {
	my $month = shift @_;
	if ($month == '2') {return '28';}
	my $anytime = timelocal(0, 0, 0, 1, ($month-1), ($year));
	return ((localtime($anytime+(30*86400)))[3] == '1') ? '30': '31';
}
