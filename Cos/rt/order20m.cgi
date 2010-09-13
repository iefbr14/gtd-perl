#!/usr/bin/perl
#######################################
#
#	name: order.cgi
#	purpose:  OpticalOnline OrderValues.java
#			  and HistoryPanel.java use 
#			  to retrieve an order
#				Works for version 1.5.8.x and above
#
#######################################
use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::Dbh;

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');
my($dateformat) = param('dateformat');

# Check the user account
my($retailer) = sql("SELECT user_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
my($order) = param('order');

# default date format for old versions is %b-%d-%Y (MMM-DD-YYYY)
# optional date formats controlled by a property in server.config are:
# 2=%m-%d-%YYY (MMM-DD-YYYY0; 3=%d-%m-%YYYY (DD-MMM-YYYY)
# formats 2 and 3 use the numeric %m output as an index into
# a language dependent string array and the actual display
# output is turned into an alphabetic, three-character month
if($dateformat==3){
$query = <<"EOF";
SELECT *
,DATE_FORMAT(created_date, "%d-%m-%Y") as date_c
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(promised_date,'%m%d%y') as datePromised
,DATE_FORMAT(promised_date,'%h:%i%p') as timePromised
FROM orders_pending 
WHERE orders_pending_id=?
EOF
}elsif($dateformat==2){
$query = <<"EOF";
SELECT *
,DATE_FORMAT(created_date, "%m-%d-%Y") as date_c
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(promised_date,'%m%d%y') as datePromised
,DATE_FORMAT(promised_date,'%h:%i%p') as timePromised
FROM orders_pending 
WHERE orders_pending_id=?
EOF
}else{
$query = <<"EOF";
SELECT *
,DATE_FORMAT(created_date, "%b-%d-%Y") as date_c
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(promised_date,'%m%d%y') as datePromised
,DATE_FORMAT(promised_date,'%h:%i%p') as timePromised
FROM orders_pending 
WHERE orders_pending_id=?
EOF
}

my($r) = sql($query, $order);

if ( ($r->{fdSource} eq "SUPPLY") && ($r->{cbo_eye} > 0) ) { #&& length($r->{fdEye}) == 0) {
	$r->{fdEye} = $r->{cbo_eye};
	$r->{fdEye} = 52;
}
	
if (($r->{fdSource} eq "SUPPLY") && defined($r->{cbo_bridge}) && ($r->{cbo_bridge} > 0) && length($r->{fdBridge}) == 0) {
	$r->{fdBridge} = $r->{cbo_bridge};
}

$r->{trace_file_size} = length($r->{trace_file_data});
$r->{trace_file_data} = encode_base64($r->{trace_file_data}, '');
$r->{rx_od_near} = $r->{rx_OD_Near_PD};
$r->{rx_os_near} = $r->{rx_OS_Near_PD};
$r->{rx_od_far}  = $r->{rx_OD_Far_PD};
$r->{rx_os_far}  = $r->{rx_OS_Far_PD};

# map the x_deposit value to depost if it exists
my($key, $val, $e);
$r->{deposit} = '';
$r->{lab_invoice} = '';
if (defined ($r->{extra_info})) {
    foreach my $extra (split("\n", $r->{extra_info})) {	

			$extra =~ m/^([^:]*):\s*(.*)/;
			($key, $val) = ($1, $2);
			
			$e->{$key} = $val;
    }
    if (defined $e->{x_deposit}) {
        $r->{deposit} = $e->{x_deposit};
    }
    if (defined $e->{x_use_trace_from}) {
	    $r->{lab_invoice} = $e->{x_use_trace_from};
    }
    if (defined $e->{viewpANG}) {
	    (split(" ", $e->{viewpANG}));
	    $r->{viewpANG_os} = $1;
	    $r->{viewpANG_od} = $2;
    }
    if (defined $e->{cbo_eye}) {
    	$r->{fdEye} = $e->{cbo_eye};
	}
    if (defined $e->{cbo_bridge}) {
    	$r->{fdBridge} = $e->{cbo_bridge};
	}
}

print <<"EOF";
# Version 1.0 history.cgi information
# User: $user 

orders_pending_id:		$r->{orders_pending_id}
last_access:			$r->{last_access}
ip_address:			$r->{ip_address}
ip_name:			$r->{ip_name}
agent_version:			$r->{agent_version}
status:				$r->{status}
created_by:			$r->{created_by}
created_date:			$r->{created_date}
promised_date:			$r->{promised_date}

lab_id:				$r->{lab_id}
user_id:			$r->{user_id}
seq_num:			$r->{seq_num}
store_invoice_num:		$r->{store_invoice_num}

date_c:				$r->{date_c}
dateOrdered:			$r->{dateOrdered}
datePromised:			$r->{datePromised}
timePromised:			$r->{timePromised}

dispenser:			$r->{dispenser}
field_acct_id:			$r->{field_acct_id}
field_client_name:		$r->{field_client_name}
field_client_addr:		$r->{field_client_addr}
combo_orderType:		$r->{combo_orderType}
instText:			$r->{instText}
tray_no:			$r->{tray_no}
redo_order_num:			$r->{redo_order_num}

tracesize:			$r->{trace_file_size}
tracedata:			$r->{trace_file_data}

#### frames
fdSource:			$r->{fdSource}
fs1_vendor:			$r->{fs1_vendor}
fs1_model:			$r->{fs1_model}
fs1_color:			$r->{fs1_color}
fs1_upc:			$r->{fs1_upc}
fp_mounting:			$r->{fp_mounting}
fp_edged:			$r->{fp_edged}
fp_dress:			$r->{fp_dress}

fdEye:				$r->{fdEye}
fdBridge:			$r->{fdBridge}
fdTemple:			$r->{fdTemple}
fdA:				$r->{fdA}
fdB:				$r->{fdB}
fdED:				$r->{fdED}
fdDBL:				$r->{fdDBL}
fdCirc:				$r->{fdCirc}

### Lenses
lens_SV_MF:			$r->{lens_SV_MF}
lens_Pair:			$r->{lens_Pair}
lens_OD_Style:			$r->{lens_OD_Style}
lens_OD_Material:		$r->{lens_OD_Material}
lens_OD_Color:			$r->{lens_OD_Color}
lens_OS_Style:			$r->{lens_OS_Style}
lens_OS_Material:		$r->{lens_OS_Material}
lens_OS_Color:			$r->{lens_OS_Color}

tr_Treatment_code:		$r->{tr_Treatment_code}
tr_Treatment:			$r->{tr_Treatment}
tr_Tinting_code:		$r->{tr_Tinting_code}
tr_Tinting:			$r->{tr_Tinting}
tr_TintColor:			$r->{tr_TintColor}
tr_TintPerCent:			$r->{tr_TintPerCent}
tr_Coating_code:		$r->{tr_Coating_code}
tr_Coating:			$r->{tr_Coating}
tr_AR_code:			$r->{tr_AR_code}
tr_AntiReflective:		$r->{tr_AntiReflective}
tr_Other1_code:			$r->{tr_Other1_code}
tr_Other2_code:			$r->{tr_Other2_code}
tr_Other3_code:			$r->{tr_Other3_code}
tr_Other4_code:			$r->{tr_Other4_code}
tr_Other5_code:			$r->{tr_Other5_code}
tr_Other1:			$r->{tr_Other1}
tr_Other2:			$r->{tr_Other2}
tr_Other3:			$r->{tr_Other3}
tr_Other4:			$r->{tr_Other4}
tr_Other5:			$r->{tr_Other5}

### Rx
rx_OD_Sphere:			$r->{rx_OD_Sphere}
rx_OD_Cylinder:			$r->{rx_OD_Cylinder}
rx_OD_Axis:			$r->{rx_OD_Axis}
rx_OD_Add:			$r->{rx_OD_Add}
rx_OD_Near_PD:			$r->{rx_OD_Near_PD}
rx_OD_Far_PD:			$r->{rx_OD_Far_PD}
rx_OD_Mono_PD:			$r->{rx_OD_Mono_PD}
rx_OD_Prism_Diopters:		$r->{rx_OD_Prism_Diopters}
rx_OD_Prism:			$r->{rx_OD_Prism}
rx_OD_Prism_Angle_Val:		$r->{rx_OD_Prism_Angle_Val}
rx_OD_Prism2_Diopters:		$r->{rx_OD_Prism2_Diopters}
rx_OD_Prism2:			$r->{rx_OD_Prism2}
rx_OD_Diopters:			$r->{rx_OD_Diopters}
rx_OD_Base:			$r->{rx_OD_Base}
rx_OD_Seg_Height:		$r->{rx_OD_Seg_Height}
rx_OD_OC_Height:		$r->{rx_OD_OC_Height}
rx_OD_Special_Base_Curve:	$r->{rx_OD_Special_Base_Curve}
rx_OD_Thickness_Reference:	$r->{rx_OD_Thickness_Reference}
rx_OD_Special_Thickness:	$r->{rx_OD_Special_Thickness}
rx_od_near:			$r->{rx_od_near}
rx_od_far:			$r->{rx_od_far}

rx_OS_Sphere:			$r->{rx_OS_Sphere}
rx_OS_Cylinder:			$r->{rx_OS_Cylinder}
rx_OS_Axis:			$r->{rx_OS_Axis}
rx_OS_Add:			$r->{rx_OS_Add}
rx_OS_Near_PD:			$r->{rx_OS_Near_PD}
rx_OS_Far_PD:			$r->{rx_OS_Far_PD}
rx_OS_Mono_PD:			$r->{rx_OS_Mono_PD}
rx_OS_Prism_Diopters:		$r->{rx_OS_Prism_Diopters}
rx_OS_Prism:			$r->{rx_OS_Prism}
rx_OS_Prism_Angle_Val:		$r->{rx_OS_Prism_Angle_Val}
rx_OS_Prism2_Diopters:		$r->{rx_OS_Prism2_Diopters}
rx_OS_Prism2:			$r->{rx_OS_Prism2}
rx_OS_Diopters:			$r->{rx_OS_Diopters}
rx_OS_Base:			$r->{rx_OS_Base}
rx_OS_Seg_Height:		$r->{rx_OS_Seg_Height}
rx_OS_OC_Height:		$r->{rx_OS_OC_Height}
rx_OS_Special_Base_Curve:	$r->{rx_OS_Special_Base_Curve}
rx_OS_Thickness_Reference:	$r->{rx_OS_Thickness_Reference}
rx_OS_Special_Thickness:	$r->{rx_OS_Special_Thickness}
rx_os_near:			$r->{rx_os_near}
rx_os_far:			$r->{rx_os_far}

### mapping info
lens_OD_StyleCode:		$r->{lens_OD_StyleCode}
lens_OD_MaterCode:		$r->{lens_OD_MaterCode}
lens_OD_ColorCode:		$r->{lens_OD_ColorCode}
lens_OS_StyleCode:		$r->{lens_OS_StyleCode}
lens_OS_MaterCode:		$r->{lens_OS_MaterCode}
lens_OS_ColorCode:		$r->{lens_OS_ColorCode}

patient_info_Name:		$r->{patient_info_Name}
patient_info_Addr:		$r->{patient_info_Addr}
patient_info_Addr2:		$r->{patient_info_Addr2}
patient_info_City:		$r->{patient_info_City}
patient_info_State:		$r->{patient_info_State}
patient_info_Pcode:		$r->{patient_info_Pcode}
patient_info_Hphone:		$r->{patient_info_Hphone}
patient_info_Wphone:		$r->{patient_info_Wphone}
patient_info_Email:		$r->{patient_info_Email}
patient_info_SSN:		$r->{patient_info_SSN}
patient_info_Group:		$r->{patient_info_Group}
patient_info_Plan:		$r->{patient_info_Plan}

ship_name:			$r->{ship_name}
ship_addr1:			$r->{ship_addr1}
ship_addr2:			$r->{ship_addr2}
ship_city:			$r->{ship_city}
ship_state:			$r->{ship_state}
ship_zip:			$r->{ship_zip}
deposit:			$r->{deposit}
cust_po_num:			$r->{cust_po_num}

lab_invoice:		$r->{lab_invoice}
viewpANG_os:		$r->{viewpANG_os}

x_dprovider_name:	$r->{x_dprovider_name}
x_dprovider_today:	$r->{x_dprovider_today}
x_dprovider_medicaidid:	$r->{x_dprovider_medicaidid}
x_dprovider_npi:	$r->{x_dprovider_npi}
x_dprovider_account:	$r->{x_dprovider_account}
x_dprovider_telephone:	$r->{x_dprovider_telephone}
x_dprovider_email:	$r->{x_dprovider_email}
x_dprovider_address1:	$r->{x_dprovider_address1}
x_dprovider_address2:	$r->{x_dprovider_address2}
x_dprovider_city:	$r->{x_dprovider_city}
x_dprovider_state:	$r->{x_dprovider_state}
x_dprovider_zip:		$r->{x_dprovider_zip}
x_dprovider_county:	$r->{x_dprovider_county}
x_pprovider_name:	$r->{x_pprovider_name}
x_pprovider_medicaidid:	$r->{x_pprovider_medicaidid}
x_pprovider_npi:	$r->{x_pprovider_npi}
x_pprovider_scriptdate:	$r->{x_pprovider_scriptdate}
x_pa_lastname:	$r->{x_pa_lastname}
x_pa_firstname:	$r->{x_pa_firstname}
x_pa_medicaidid:	$r->{x_pa_medicaidid}
x_pa_dob:	$r->{x_pa_dob}
x_pa_address:	$r->{x_pa_address}
x_medicaid_lastservice:	$r->{x_medicaid_lastservice}
x_medicaid_id:	$r->{x_medical_recnum}
x_medicaid_recdate:	$r->{x_medicaid_recdate}
x_medicaid_panumber:	$r->{x_medicaid_panumber}
x_medicaid_pareason:	$r->{x_medicaid_pareason}
	
$r->{extra_info}

EOF
