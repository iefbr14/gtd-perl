# $Id: std.pm,v 1.22 2006/06/13 15:59:26 drew Exp $
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


package Cos::std;

use strict;
#use warnings;

use Cos::Dbh;

use utf8;
use encoding 'utf8';
use Text::Unidecode;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.22 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&load &load_utf8 &dump &ascii);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;


## Db field name,	Order field name/value,		
#last_access,		NULL,		# last_access
#ip_address,		UNDEF,		# ip_address
#ip_name,		UNDEF,		# ip_name
#status,			'E',	# status (E=external order)
#field_acct_id,		acct_id'"",		# field_account_id
#field_client_addr,	UNDEF,		# field_client_addr
#combo_orderType,	UNDEF,		# combo_orderType
#lens_Pair,		UNDEF,		# lens_Pair
#trace_file_data,	NULL,		# trace_file_data
#trace_file_size,	0,		# trace_file_size
#user_id,		user_id,		# user_id

# these fields are fillable by the order

# OD -> right
# OS -> left

#	External Conical Name		Database Field Name
my $ord_tab_hash = {
	'file_version' =>		'-',
	'order_items' =>		'-',
	'agent_name' =>			'created_by',
	'agent_version' =>		'agent_version',
	'invoice_num' =>		'lab_invoice_num',
	'lab_num' =>			'lab_id',
	'status' =>			'status',
	'order_id' =>			'orders_pending_id',

	'patient_name' =>		'field_client_name',
	'cust_num' =>			'field_acct_id',
	'cust_seq_num' =>		'cust_seq_num',
	'customer_tray_num' =>		'tray_no',
	'customer_po_num' =>		'cust_po_num',

	'rx_eye' =>			'lens_Pair',

	'instructions' =>		'instText',
	'date_ordered' =>		'created_date',
	'date_promised' =>		'promised_date',

	'frame_source' =>		'fdSource',
	'frame_vendor' =>		'fs1_vendor',
	'frame_model' =>		'fs1_model',
	'frame_color' =>		'fs1_color',
	'frame_upc' =>			'fs1_upc',
	'frame_eye' =>			'fdEye',
	'frame_bridge' =>		'fdBridge',
	'frame_temple' =>		'fdTemple',
	'frame_a' =>			'fdA',
	'frame_b' =>			'fdB',
	'frame_ed' =>			'fdED',
	'frame_dbl' =>			'fdDBL',
	'frame_circ' =>			'fdCirc', 
	'frame_rad_angle' =>		'frame_rad_angle',
	'frame_status' =>		'frame_status',
	'frame_tracing' =>		'frame_tracing',
	'frame_long_rad' =>		'frame_long_rad',
	'frame_shape' =>		'frame_shape',
	'frame_mounting' =>		'fp_mounting',
	'frame_dress' =>		'fp_dress',
	'frame_desc' =>			'frame_desc',
	'frame_edge' =>			'fp_edged',

	'lens_od_color_code' =>		'lens_OD_ColorCode',
	'lens_od_color_desc' =>		'lens_OD_Color',
	'lens_od_material_code' =>	'lens_OD_MaterCode',
	'lens_od_material_desc' =>	'lens_OD_Material',
	'lens_od_stock_or_sf' =>	'lens_od_st_sf',
	'lens_od_style_code' =>		'lens_OD_StyleCode',
	'lens_od_style_desc' =>		'lens_OD_Style',
	'lens_od_vendor_code' =>	'lens_OD_VendorCode',
	'lens_od_vendor_desc' =>	'lens_OD_Vendor',

	'lens_os_color_code' =>		'lens_OS_ColorCode',
	'lens_os_color_desc' =>		'lens_OS_Color',
	'lens_os_material_code' =>	'lens_OS_MaterCode',
	'lens_os_material_desc' =>	'lens_OS_Material',
	'lens_os_stock_or_sf' =>	'lens_os_st_sf',
	'lens_os_style_code' =>		'lens_OS_StyleCode',
	'lens_os_style_desc' =>		'lens_OS_Style',
	'lens_os_vendor_code' =>	'lens_OS_VendorCode',
	'lens_os_vendor_desc' =>	'lens_OS_Vendor',

	'lens_ar_desc' =>		'tr_AntiReflective',
	'lens_coating_desc' =>		'tr_Coating',
	'lens_tint_color' =>		'tr_TintColor',
	'lens_tinting' =>		'tr_Tinting',
	'lens_tint_percent' =>		'tr_TintPercent',
	'lens_treatment' =>		'tr_Treatment',

	'lens_sv_mf' =>			'lens_SV_MF',

#	'lens_other1_desc' =>		'tr_Other1',
#	'lens_other2_desc' =>		'tr_Other2',
#	'lens_other3_desc' =>		'tr_Other3',
#	'lens_other4_desc' =>		'tr_Other4',
#	'lens_other5_desc' =>		'tr_Other5',

	'rx_od_sphere' =>		'rx_OD_Sphere',
	'rx_od_cylinder' =>		'rx_OD_Cylinder',
	'rx_od_axis' =>			'rx_OD_Axis',
	'rx_od_add' =>			'rx_OD_Add',
	'rx_od_near' =>			'rx_OD_Near_PD',
	'rx_od_far' =>			'rx_OD_Far_PD',
	'rx_od_mono' =>			'rx_OD_Mono_PD',

	'rx_od_prism' =>		'rx_OD_Prism_Diopters',
	'rx_od_prism_dir' =>		'rx_OD_Prism',
	'rx_od_prism_angle' =>		'rx_OD_Prism_Angle_Val',

	'rx_od_prism2' =>		'rx_OD_Prism2_Diopters',
	'rx_od_prism2_dir' =>		'rx_OD_Prism2',
	'rx_od_prism2_angle' =>		'?',

	'rx_od_so_diopters' =>		'rx_OD_Diopters',
	'rx_od_so_base' =>		'rx_OD_Base',
	'rx_od_so_reading_drop' =>	'-',
	'rx_od_seg_height' =>		'rx_OD_Seg_Height',
	'rx_od_oc_height' =>		'rx_OD_OC_Height',
	'rx_od_sbc' =>			'rx_OD_Special_Base_Curve',
	'rx_od_thickness_reference' =>	'rx_OD_Thickness_Reference',
	'rx_od_thickness' =>		'rx_OD_Special_Thickness',

	'rx_os_sphere' =>		'rx_OS_Sphere',
	'rx_os_cylinder' =>		'rx_OS_Cylinder',
	'rx_os_axis' =>			'rx_OS_Axis',
	'rx_os_add' =>			'rx_OS_Add',
	'rx_os_near' =>			'rx_OS_Near_PD',
	'rx_os_far' =>			'rx_OS_Far_PD',
	'rx_os_mono' =>			'rx_OS_Mono_PD',

	'rx_os_prism' =>		'rx_OS_Prism_Diopters',
	'rx_os_prism_dir' =>		'rx_OS_Prism',
	'rx_os_prism_angle' =>		'rx_OS_Prism_Angle_Val',

	'rx_os_prism2' =>		'rx_OS_Prism2_Diopters',
	'rx_os_prism2_dir' =>		'rx_OS_Prism2',
	'rx_os_prism2_angle' =>		'rx_OS_Prism2_Angle',

	'rx_os_so_diopters' =>		'rx_OS_Diopters',
	'rx_os_so_base' =>		'rx_OS_Base',
	'rx_os_so_reading_drop' =>	'-',
	'rx_os_seg_height' =>		'rx_OS_Seg_Height',
	'rx_os_oc_height' =>		'rx_OS_OC_Height',
	'rx_os_sbc' =>			'rx_OS_Special_Base_Curve',
	'rx_os_thickness_reference' =>	'rx_OS_Thickness_Reference',
	'rx_os_thickness' =>		'rx_OS_Special_Thickness',

	'ship_name' =>			'ship_name',
	'ship_state' =>			'ship_state',
	'ship_addr1' =>			'ship_addr1',
	'ship_addr2' =>			'ship_addr2',
	'ship_zip' =>			'ship_zip',
	'ship_city' =>			'ship_city',
	'ship_country' =>		'ship_country',
	'ship_via' =>			'ship_via',

	'trace_value' =>		'trace_file_data',
	'trace_size' =>			'trace_file_size',
	'trace_file' =>			'-',

	'order_price_list' =>		'price_list',

	'instructions_1' =>		'+',	# extra info (mapped into hash ref by 
	'instructions_2' =>		'+',	# extract_info();
	'instructions_3' =>		'+',
	'instructions_4' =>		'+',
	'instructions_5' =>		'+',

	'x_lab_comment_1' =>		'+',
	'x_lab_comment_2' =>		'+',
	'x_lab_comment_3' =>		'+',
	'x_lab_comment_4' =>		'+',
	'x_lab_comment_5' =>		'+',
	'x_lab_comment_6' =>		'+',
	'x_lab_comment_7' =>		'+',
	'x_lab_comment_8' =>		'+',
	'x_lab_comment_9' =>		'+',

	'lens_od_sku' =>		'+',
	'lens_os_sku' =>		'+',

# ***BUG*** figure out the real mappings.
	'frame_circ_changed' =>		'?',
	'frame_od_side_shield' =>	'?',
	'frame_os_side_shield' =>	'?',


	'lab_seq_num' =>		'?',
	'lab_status_code' =>		'?',
	'lab_status_desc' =>		'?',
	'lab_tray' =>			'?',
	'redo_invoice_num' =>		'?',

#	'dr_name' =>			'cust_doctor',

#	'dr_name' =>			'doctor_name',
#	'dr_addr1'  =>			'doctor_addr1',
#	'dr_addr2' =>			'doctor_addr2',
#	'dr_city' =>			'doctor_city',
#	'dr_state' =>			'doctor_state',
#	'dr_zip' =>			'doctor_zip',

#	'patient_name' =>		'patient_info_Name',
	'patient_addr1' =>		'patient_info_Addr',
	'patient_addr2' =>		'patient_info_Addr2',
	'patient_city' =>		'patient_info_City',
	'patient_state' =>		'patient_info_State',
	'patient_zip' =>		'patient_info_Pcode',

	'patient_home_phone' =>		'patient_info_Hphone',
	'patient_work_phone' =>		'patient_info_Wphone',
	'patient_email' =>		'patient_info_Email',
	'patient_ssn' =>		'patient_info_SSN',
	'patient_group' =>		'patient_info_Group',
	'patient_plan' =>		'patient_info_Plan',
};

my @DirSet  = 
my @DirSet2 = qw(UP DOWN IN OUT);

my $Manditory = {
	# Field Identifier		[ Check Type Args... ],
	'order_id' =>			[ 'N', 'R', 1,  999_999_999_999 ],
	'order_items' =>		[ 'N', 'H', ],

	'lab_num' =>			[ 'Y', 'R', 1,  999 ],
	'cust_num' =>			[ 'Y', 'R', 1,  999_999_999 ],
	'cust_seq_num' =>		[ 'Y', 'R', 0,  999 ],

	'lab_seq_num' =>		[ 'N', 'R', 1,  999_999_999 ],
	'lab_status_code' =>		[ 'N', 'S', 8],
	'lab_status_desc' =>		[ 'N', 'S', 32 ],

	'lab_tray' =>			[ 'N', 'R', 0,  999_999_999 ],

	'order_price_list' =>		[ 'N', 'r', 0,  999_999_999 ],

	'status' =>			[ 'Y', 'S', qw(C N Z d) ],

	# Frame Info
	'frame_source' =>		[ 'N', 'r', 0,  0 ],
	'frame_status' =>		[ 'N', 'r', 0,  0 ],
	'frame_tracing' =>		[ 'N', 'r', 0,  0 ],

	'frame_eye' =>			[ 'N', 'R',  15,  70 ],
	'frame_bridge' =>		[ 'N', 'R',   5,  30 ],
	'frame_temple' =>		[ 'N', 'R', 100, 180 ],
	'frame_a' =>			[ 'N', 'R',  25,  70 ],
	'frame_b' =>			[ 'N', 'R',  18,  70 ],
	'frame_ed' =>			[ 'N', 'R',  30,  80 ],
	'frame_dbl' =>			[ 'N', 'R',   0,  30 ],
	'frame_circ' =>			[ 'N', 'R',  50, 200 ],

	'frame_vendor' =>		[ 'U', 'r', 0,  0 ],
	'frame_model' =>		[ 'U', 'r', 0,  0 ],
	'frame_color' =>		[ 'U', 'r', 0,  0 ],
	'frame_upc' =>			[ 'U', 'r', 0,  0 ],

	'frame_mounting' =>		[ 'U', 'S', qw(STANDARD METAL RIMLESS HALFEYE DRILLED FACET)],
	'frame_edge' =>			[ 'U', 'S', qw(EDGED UNCUT) ],
	'frame_dress' =>		[ 'U', 'S', qw(DRESS SAFETY) ],
	'frame_desc' =>			[ 'N', 'T', 0, 64 ],

	'frame_long_rad' =>		[ 'U', 'R',   0,  99.9 ],
	'frame_rad_angle' =>		[ 'U', 'R',   0, 360 ],
	'frame_shape' =>		[ 'U', 'r', 0,  0 ],
	'frame_circ_changed' =>		[ 'U', 'r', 0,  0 ],

	'frame_od_side_shield' =>	[ 'U', 'r', 0,  0 ],
	'frame_os_side_shield' =>	[ 'U', 'r', 0,  0 ],

	# Lens info
	'lens_od_stock_or_sf' =>	[ 'U', 'r', 0,  0 ],

	'lens_od_color_code' =>		[ 'U', 'r', 0,  0 ],
	'lens_od_color_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_od_material_code' =>	[ 'U', 'r', 0,  0 ],
	'lens_od_material_desc' =>	[ 'U', 'r', 0,  0 ],
	'lens_od_stock_or_sf' =>	[ 'U', 'r', 0,  0 ],
	'lens_od_style_code' =>		[ 'U', 'r', 0,  0 ],
	'lens_od_style_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_od_vendor_code' =>	[ 'U', 'r', 0,  0 ],
	'lens_od_vendor_desc' =>	[ 'U', 'r', 0,  0 ],

	'lens_os_color_code' =>		[ 'U', 'r', 0,  0 ],
	'lens_os_color_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_os_material_code' =>	[ 'U', 'r', 0,  0 ],
	'lens_os_material_desc' =>	[ 'U', 'r', 0,  0 ],
	'lens_os_stock_or_sf' =>	[ 'U', 'r', 0,  0 ],
	'lens_os_style_code' =>		[ 'U', 'r', 0,  0 ],
	'lens_os_style_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_os_vendor_code' =>	[ 'U', 'r', 0,  0 ],
	'lens_os_vendor_desc' =>	[ 'U', 'r', 0,  0 ],

	'lens_od_sku' =>		[ 'N', 'r', 0,  0 ],
	'lens_os_sku' =>		[ 'N', 'r', 0,  0 ],

	'lens_sv_mf' =>			[ 'U', 'S', qw(MON BPD S M s m)],

	'lens_ar_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_coating_desc' =>		[ 'U', 'r', 0,  0 ],
	'lens_tint_color' =>		[ 'U', 'r', 0,  0 ],
	'lens_tinting' =>		[ 'U', 'r', 0,  0 ],
	'lens_tint_percent' =>		[ 'U', 'r', 0,  0 ],
	'lens_treatment' =>		[ 'U', 'r', 0,  0 ],

#	'lens_other1_desc' =>		[ 'U', 'r', 0,  0 ],
#	'lens_other2_desc' =>		[ 'U', 'r', 0,  0 ],
#	'lens_other3_desc' =>		[ 'U', 'r', 0,  0 ],
#	'lens_other4_desc' =>		[ 'U', 'r', 0,  0 ],
#	'lens_other5_desc' =>		[ 'U', 'r', 0,  0 ],

	# Rx info
	'rx_eye' =>			[ 'Y', 'R', 1,  6 ],

		# Right
	'rx_od_sphere' =>		[ 'Y', 'R', -99.75,  99.75 ],
	'rx_od_cylinder' =>		[ 'N', 'R', -25.00,  25.00 ],
	'rx_od_axis' =>			[ 'N', 'R', 0,  180 ],
	'rx_od_add' =>			[ 'Y', 'R', 0.5,  25.00 ],

	'rx_od_far' =>			[ 'Y', 'R', 30,  80 ],
	'rx_od_near' =>			[ 'Y', 'R',  0,  80 ],
	'rx_od_mono' =>			[ 'Y', 'R', 15,  40 ],

	'rx_od_seg_height' =>		[ 'Y', 'R', 7,  35 ],
	'rx_od_oc_height' =>		[ 'N', 'R', 0,  15 ],
	'rx_od_sbc' =>			[ 'N', 'R', -5.00,  30 ],
	'rx_od_thickness' =>		[ 'N', 'R', 0,  8 ],
	'rx_od_thickness_reference' =>	[ 'N', 'S', 'Edge', 'Center' ],

	'rx_od_prism' =>		[ 'N', 'R', 0,  30 ],
	'rx_od_prism_dir' =>		[ 'N', 'S', qw(UP DOWN IN OUT ANGLE) ],
	'rx_od_prism_angle' =>		[ 'N', 'R', 0,  360 ],
	'rx_od_prism2' =>		[ 'N', 'R', 0,  30 ],
	'rx_od_prism2_dir' =>		[ 'N', 'S', qw(UP DOWN IN OUT) ],
	'rx_od_prism2_angle' =>		[ 'N', 'R', 0,  360 ],

	'rx_od_so_diopters' =>		[ 'N', 'R', 0,  30 ],
	'rx_od_so_base' =>		[ 'N', 'S', qw(UP DOWN) ],
	'rx_od_so_reading_drop' =>	[ 'N', 'R', 0,  30 ],

		# Left
	'rx_os_sphere' =>		[ 'Y', 'R', -99.75,  99.75 ],
	'rx_os_cylinder' =>		[ 'N', 'R', -25.00,  25.00 ],
	'rx_os_axis' =>			[ 'N', 'R', 0,  180 ],
	'rx_os_add' =>			[ 'Y', 'R', 0.5,  25.00 ],

	'rx_os_far' =>			[ 'Y', 'R', 30,  80 ],
	'rx_os_near' =>			[ 'Y', 'R',  0,  80 ],
	'rx_os_mono' =>			[ 'Y', 'R', 15,  40 ],

	'rx_os_seg_height' =>		[ 'Y', 'R', 7,  35 ],
	'rx_os_oc_height' =>		[ 'N', 'R', 0,  15 ],
	'rx_os_sbc' =>			[ 'N', 'R', -5.00,  30 ],
	'rx_os_thickness' =>		[ 'N', 'R', 0,  8 ],
	'rx_os_thickness_reference' =>	[ 'N', 'S', 'Edge', 'Center' ],

	'rx_os_prism' =>		[ 'N', 'R', 0,  30 ],
	'rx_os_prism_dir' =>		[ 'N', 'S', qw(UP DOWN IN OUT ANGLE) ],
	'rx_os_prism_angle' =>		[ 'N', 'R', 0,  360 ],
	'rx_os_prism2' =>		[ 'N', 'R', 0,  30 ],
	'rx_os_prism2_dir' =>		[ 'N', 'S', qw(UP DOWN IN OUT) ],
	'rx_os_prism2_angle' =>		[ 'N', 'R', 0,  360 ],

	'rx_os_so_diopters' =>		[ 'N', 'R', 0,  30 ],
	'rx_os_so_base' =>		[ 'N', 'S', qw(UP DOWN) ],
	'rx_os_so_reading_drop' =>	[ 'N', 'R', 0,  30 ],

	# Shipping Instructions
	'ship_name' =>			[ 'N', 't', 0,  0 ],
	'ship_addr1' =>			[ 'N', 't', 0,  0 ],
	'ship_addr2' =>			[ 'N', 't', 0,  0 ],
	'ship_city' =>			[ 'N', 't', 0,  0 ],
	'ship_state' =>			[ 'N', 't', 0,  0 ],
	'ship_zip' =>			[ 'N', 't', 0,  0 ],
	'ship_country' =>		[ 'N', 't', 0,  0 ],
	'ship_via' =>			[ 'N', 't', 0,  0 ],

	# Order Items
#	'sku' =>			[ 'N', 'r', 0,  0 ],
#	'item_source' =>		[ 'N', 'r', 0,  0 ],
#	'item_description' =>		[ 'N', 'r', 0,  0 ],
#	'item_value' =>			[ 'N', 'r', 0,  0 ],
#	'item_quantity' =>		[ 'N', 'r', 0,  0 ],
#	'item_side' =>			[ 'N', 'r', 0,  0 ],

	# Misc
	'instructions' =>		[ 'N', 't', 0,  0 ],
	'instructions_1' =>		[ 'N', 't', 0,  0 ],
	'instructions_2' =>		[ 'N', 't', 0,  0 ],
	'instructions_3' =>		[ 'N', 't', 0,  0 ],
	'instructions_4' =>		[ 'N', 't', 0,  0 ],
	'instructions_5' =>		[ 'N', 't', 0,  0 ],

	'x_lab_comment_1' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_2' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_3' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_4' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_5' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_6' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_7' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_8' =>		[ 'N', 't', 0,  0 ],
	'x_lab_comment_9' =>		[ 'N', 't', 0,  0 ],

	'customer_tray_num' =>		[ 'N', 'r', 0,  0 ],
	'customer_po_num' =>		[ 'N', 'r', 0,  0 ],

	'redo_invoice_num' =>		[ 'N', 'r', 0,  0 ],
	'invoice_num' =>		[ 'N', 'r', 0,  0 ],
	'date_ordered' =>		[ 'N', 'D', ],
	'date_promised' =>		[ 'N', 'D', ],

	'agent_name' =>			[ 'Y', 'r', 0,  0 ],
	'agent_version' =>		[ 'Y', 'r', 0,  0 ],
	'file_version' =>		[ 'Y', 'r', 0,  0 ],

	'trace_value' =>		[ 'N', 'r', 0,  0 ],
	'trace_size' =>			[ 'N', 'r', 0,  0 ],
	'trace_file' =>			[ 'N', 'r', 0,  0 ],

#	'dr_name' =>			[ 'N', 'T', 0,  255 ],
#	'dr_addr1'  =>			[ 'N', 'T', 0,  255 ],
#	'dr_addr2' =>			[ 'N', 'T', 0,  255 ],
#	'dr_city' =>			[ 'N', 'T', 0,  255 ],
#	'dr_state' =>			[ 'N', 'T', 0,  255 ],
#	'dr_zip' =>			[ 'N', 'T', 0,  255 ],

	'patient_name' =>		[ 'Y', 'T', 0,  40 ],
	'patient_addr1' =>		[ 'N', 'T', 0,  255 ],
	'patient_addr2' =>		[ 'N', 'T', 0,  255 ],
	'patient_city' =>		[ 'N', 'T', 0,  255 ],
	'patient_state' =>		[ 'N', 'T', 0,  255 ],
	'patient_zip' =>		[ 'N', 'T', 0,  255 ],

	'patient_home_phone' =>		[ 'N', 'T', 0,  255 ],
	'patient_work_phone' =>		[ 'N', 'T', 0,  255 ],
	'patient_email' =>		[ 'N', 'T', 0,  255 ],
	'patient_ssn' =>		[ 'N', 'T', 0,  255 ],
	'patient_group' =>		[ 'N', 'T', 0,  255 ],
	'patient_plan' =>		[ 'N', 'T', 0,  255 ],

};


my(@Items_list) = (
	# Order Items
	'sku' =>			[ 'N', 'r', 0,  0 ],
	'item_source' =>		[ 'N', 'r', 0,  0 ],
	'item_description' =>		[ 'N', 'r', 0,  0 ],
	'item_value' =>			[ 'N', 'r', 0,  0 ],
	'item_quantity' =>		[ 'N', 'r', 0,  0 ],
	'item_side' =>			[ 'N', 'r', 0,  0 ],
);

my(%Obsolete) = (
	'tr_Tinting'        => '-',
        'tr_Tinting_code'   => 'TINT',

        'tr_TintPercent'    => '-',
        'tr_TintColor'      => '-',

        'tr_AR_code'        => 'COAT',
        'tr_Coating_code'   => 'COAT',
        'tr_Treatment_code' => 'MISC',
        'tr_Other1_code'    => 'MISC',
        'tr_Other2_code'    => 'MISC',
        'tr_Other3_code'    => 'MISC',
        'tr_Other4_code'    => 'MISC',
        'tr_Other5_code'    => 'MISC',

        'tr_AntiReflective' => '-',	# not 'tr_AR'
        'tr_Coating'        => '-',
        'tr_Treatment'      => '-',
        'tr_Other1'         => '-',
        'tr_Other2'         => '-',
        'tr_Other3'         => '-',
        'tr_Other4'         => '-',
        'tr_Other5'         => '-',
);

#       lens_OD_VendorCode    
#       lens_OS_VendorCode    
#       lens_OD_StyleCode
#       lens_OD_MaterCode     
#       lens_OD_ColorCode     
#       lens_OS_StyleCode     
#       lens_OS_MaterCode     
#       lens_OS_ColorCode     



my($db_tab_hash) = reverse %$ord_tab_hash;
my($Bogus) = '? - not - set - correctly -?';

sub new {
	my($ref);

	foreach my $key (keys %$ord_tab_hash) {
		$ref->{$key} = $Bogus;
	}
	bless $ref;
	return $ref;
}

sub docutate {
	foreach my $key (sort keys %$ord_tab_hash) {
		unless (defined $Manditory->{$key}) {
			print "*** Undfined mapping $key (Not in Manditory)\n";
			next;
		}
	}

	foreach my $key (sort keys %$Manditory) {
		unless (defined $ord_tab_hash->{$key}) {
			print "*** Undefined mapping Manditory $key\n";
			next;
		}
	}
}

&docutate;

sub viserate {
	my($ref) = @_;

	foreach my $key (sort keys %$ref) {
		unless (defined $ref->{$key}) {
			print "*** Undfined val $key\n";
			next;
		}
		next if $key =~ /^x_/;
		next if $key eq 'item_count';
		next if $key eq 'item_list';

		unless (defined $ord_tab_hash->{$key}) {
			print "*** Invalid key $key: $ref->{$key}\n";
			next;
		}
		if ($ref->{$key} eq $Bogus) {
			print "*** Invalid val $key: $ref->{$key}\n";
			next;
		}
		# type check all values;
		# range check all values
	}

	if (defined $ref->{item_count} or defined $ref->{item_list}) {
		my($i) = 0;
		my($cnt) = $ref->{item_count};
		my($items) = $ref->{item_list};

		foreach my $item ( @$items) {
			++$i;
		}
		if ($i != $cnt) {
			print "*** Item count $cnt != counted items $i\n";
		}
	}
}

sub validate {
	my($ref) = @_;
	my($check, $manditory, $type, @args);

	foreach my $key (sort keys %$Manditory) {
		next if $key =~ /^x_/;

		$check = $Manditory->{$key};

		($manditory, $type, @args)= @$check;
		die "Bad key $key" unless defined $type;
		if ($check eq 'Y') {
			check_defined($ref, $key);
		}
	
		if ($type eq 'T') {
			check_text($ref, $key, @args);
		} elsif ($type eq 'S') {
			check_set($ref, $key, @args);

		} elsif ($type eq 'R') {
			check_range($ref, $key, @args);

		} elsif ($type eq 'D') {
			check_date($ref, $key);

		} elsif ($type eq 'H') {
			# ignore hash
		}
	}
}

sub check_manditory {
	my($ref) = shift @_;
	my($key) = shift @_;
	my($val) = $ref->{$key};

	return if $val ne '';

	warn "***Error $key not allowed to be empty\n";
}

sub check_date {
	my($ref) = shift @_;
	my($key) = shift @_;
	my($val) = $ref->{$key};

	return unless defined $val;
	return if $val eq '';

	return if $val =~ /^\d\d\d\d-\d\d-\d\d$/;
	return if $val =~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/;
	return if $val =~ /^\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d$/;

	warn "***Error $key Invalid value:  $val (bad date)\n";
}

sub check_text {
	my($ref) = shift @_;
	my($key) = shift @_;

	my($min) = shift @_;
	my($max) = shift @_;

	my($val) = $ref->{$key};

	return unless defined $val;
	return if $val eq '';

	if (length($val) < $min) {
		warn "***Error $key Value '$val' too short (min: $min)\n";
		return 0;
	}
	if (length($val) > $max) {
		warn "***Error $key Value '$val' too long (max: $max)\n";
		return 0;
	}
	return 1;
}


sub check_set {
	my($ref) = shift @_;
	my($key) = shift @_;
	my($val) = $ref->{$key};

	return unless defined $val;
	return if $val eq '';

	foreach my $valid (@_) {
		return if $val eq $valid;
	}
	warn "***Error $key Invalid value:  $val (not in set @_)\n";
}

sub check_range {
	my($ref) = shift @_;
	my($key) = shift @_;
	my($val) = $ref->{$key};

	my($lower, $upper, $incr) = @_;

	return unless defined $val;
	return if $val eq '';

	if ($val !~ /^[-+]*\d+(\.\d*)?$/) {
		warn "***Error $key Invalid value:  $val not numeric\n";
		return 0;
	}
	if ($val < $lower) {
		warn "***Error $key Invalid value:  $val < $lower\n";
		return 0;
	}
	if ($val > $upper) {
		warn "***Error $key Invalid value:  $val > $upper\n";
		return 0;
	}

	if (defined $incr) {
		# check fraction :-(
	}
	return 1;
}

sub dump {
	my($ref) = @_;
	foreach my $key (sort keys %$ref) {
		print "$key: $ref->{$key}\n";
	}
}

sub load {
	my($ref) = load_utf8(@_);

	require  Encode;

	my($val);
	foreach my $key (keys %$ref) {
		next if $key eq 'item_list';

		$val = $ref->{$key};
		Encode::_utf8_on($val);
		$ref->{$key} = unidecode($val);
	}

	my($item_count) = $ref->{item_count};
	my($items) = $ref->{item_list};
	my($i, $item);
	for ($i=0; $i < $item_count; ++$i) {
		$item = $items->[$i];
		foreach my $key (keys %$item) {
			$item->{$key} = ascii($item->{$key});
		}
	}
	return $ref;
}

sub ascii {
	my($val) = @_;

	Encode::_utf8_on($val);
	return unidecode($val);
}


sub load_utf8 {
	my($order_id) = @_;
	my($db) = sql('select * from orders_pending where orders_pending_id = ?', $order_id);

	return undef unless defined $db;

	my($job, $fld, $val);
	my $Map = $ord_tab_hash;

	my($items);
	my($item_count) = 0;

	my($dbh) = Cos::Dbh::new;
	my($sth);

        my $query = "select * from order_items where order_number = ? ";
        if( !($sth = $dbh->prepare($query)) ) {
                print LOG   "Can't prepare $query: Reason $!";
                return;
        } elsif ( !$sth->execute($order_id) ) {
                print LOG   "Can't execute $query: Reason $!";
                return;
        }
        my($ref);
        while($ref = $sth->fetchrow_hashref){
		$items->[$item_count] = { %$ref };
		++$item_count;
        }

	my($labno) = $db->{lab_no};
        my($sku, $desc, $misc, $source, $skudkey);

        # now handle the Obsolete keys
	if ($item_count == 0) {
            foreach my $field (sort keys %Obsolete) {
		next if $Obsolete{$field} eq '-';

                next unless defined $db->{$field};
                next if $db->{$field} eq '';

                $misc = '';
                $sku = $db->{$field};
                $skudkey = $field;
                if ($skudkey =~ s/_code$//) {
			$skudkey = 'tr_AntiReflective' if $skudkey eq 'tr_AR';

                        $desc = $db->{$skudkey};
			delete $db->{$skudkey};

                        $desc = get_desc($dbh, $sku, $labno) if $desc eq '';
                } else {
                        $desc = get_desc($dbh, $sku, $labno);
                }
                $source  = $Obsolete{$field};
                if ($field eq 'tr_Tinting_code') {
                        $misc = $db->{'tr_TintColor'} . ','
                              . $db->{'tr_TintPerCent'};

			delete $db->{tr_TintColor};
			delete $db->{tr_TintPerCent};
                }
		delete $db->{$field};

		$items->[$item_count] = {
			'sku'			=> $sku,
			'item_description'	=> $desc,
			'item_side'		=> 'NONE',
			'item_quantity'		=> 1,
			'item_value'		=> $misc,
			'item_source'		=> $source,
		};
		++$item_count;
	    }
	} 

        $sth->finish;

	foreach my $key (keys %$Map) {
		next if $Obsolete{$Map->{$key}};

		$fld = $Map->{$key} || '';

		next if $fld eq '';
		next if $fld eq '-';

		$val = $db->{$fld};

		if($fld =~ /lens_Pair/){
			$key = 'rx_eye';

			$val = 1 if $val =~ /R/;	# right
			$val = 2 if $val =~ /L/;	# left
			$val = 3 if $val =~ /B/;	# both
			$val = 6 if $val =~ /T/;	# trace only

			$job->{rx_key} = $val;
		}

		if($key eq 'date_ordered' or $key eq 'date_promised') {	
			$val =~ s/[^\d]//g;
			my($yr,$mo,$da,$hr,$min,$sec) =
				 $val =~ /(....)(..)(..)(..)(..)(..)/;
			$val = "$yr-$mo-$da-$hr-$min-$sec";
		}

		$job->{$key} = $val;
	}

	fix_near_far($job, $db);

	# data clean up after we have loaded the data.
	# rdt was buggered in loading data from cos-mail
	if ($job->{agent_name} eq 'cos-mail'
	&&  $job->{frame_a} >= 100) {
		$job->{frame_a}   =~ s/(\d)$/.$1/;
		$job->{frame_b}   =~ s/(\d)$/.$1/;
		$job->{frame_dbl} =~ s/(\d)$/.$1/;
		$job->{frame_ed}  =~ s/(\d)$/.$1/;
	}


	$job->{item_count} = $item_count;
	$job->{item_list} = $items;

	extract_info($job, $db);

	$job->{order_id} = $order_id;

	if ($job->{agent_name} =~ /^oo/) {
		fix_misc_mounting($job);
	}

	delete $job->{frame_desc} unless $job->{frame_desc};

	bless $job;
	return $job;
}

sub save {
	my($job,$do_save) = @_;
	my($key, $fld, $val, $map, @name, @vals, $sql);
	my($sth);

$| = 1;

	my($i) = 0;
	my $Map = $ord_tab_hash;

	my($extra) = '';
	foreach $key (sort keys %$job) {
		if ($key =~ /^x_/) {
			$extra .= "$key:$job->{$key}\n";
print "Extra: $key $job->{$key}\n";
		}
	}

	foreach $key (sort keys %$Map) {
		next if $key eq 'orders_id';
		next if $key =~ /^\+/;

		$fld = $Map->{$key} || '';

		if ($fld eq '') {
			die "Invalid mapping for $key\n";
		}
		next if $fld eq '-';

		if (defined $job->{$key}) {
			$val = $job->{$key};
		} else {
			$val = '';
		}

		if ($fld eq '+') {
			next unless $val;
			$extra .= "$key:$job->{$key}\n";
print "Extra: $key $job->{$key}\n";
			next;
		}

		if ($fld eq '?') {
			next if $val eq '';

			die "Bogus mapping for $key would loose value $val\n";
		}

		push(@name, $fld);
		push(@vals, $val);

		# for print purposes only
		# next;
		if ($fld eq 'trace_file_data') {
			$val = '*** Binary ***' if $val ne '';
		}
print "key undefined\n" unless defined $key;
print "fld undefined $key\n" unless defined $fld;
print "val undefined $key\n" unless defined $val;
		printf "%3d %-25s %-25s %s\n", ++$i, $fld, $key, $val;
	}
	push(@name, 'extra_info');
	push(@vals, $extra);

	return undef unless $do_save;

	my($dbh) = Cos::Dbh::new();

	$sql = 'insert into orders_pending ( '
		. join(',', @name)
		. ' ) values ( ?'
		. ',?' x (scalar(@name)-1) . ')';
#print "$sql\n";
	$sth = $dbh->prepare($sql);
	$sth->execute(@vals);

	#=============================================
	# get the order id we just inserted.
	#=============================================

	my($query) = "select last_insert_id()";
        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute()               or die "Can't execute: $query. Reason: $!";

	my($ref) = $sth->fetchrow_hashref();
	my($order) = $ref->{'last_insert_id()'};

	print "order: $order\n";

	#=============================================
	# get the order id we just inserted.
	#=============================================
	
	$query = <<'EOF';
insert into order_items (
	order_number, sku, item_description, item_part_rx,
	item_side, item_quantity, item_value, item_source)
values (?,?,?,?, ?,?,?,?)
EOF
        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";

	my($item_count) = $job->{item_count};
	return $order unless defined $item_count;

	my($sku, $desc, $partrx, $side, $quant, $value, $src);
	my($items) = $job->{item_list};

	for ($i=0; $i < $item_count; ++$i) {
                $sku    = nnull($items->[$i]{'sku'});
                $desc   = nnull($items->[$i]{'item_description'});
                $partrx = nnull($items->[$i]{'item_part_rx'});
                $side   = nnull($items->[$i]{'item_side'});
                $quant  = nnull($items->[$i]{'item_quantity'});
                $value  = nnull($items->[$i]{'item_value'});
                $src    = nnull($items->[$i]{'item_source'});

		$partrx ||= 'Y';

print "Item: $i, $sku, '$desc', $partrx, $side, $quant, $value, $src\n";
		$sth->execute(
			$order, "$sku", $desc, $partrx,
			$side, $quant, "$value", $src
		) or die "Can't execute: $query. Reason: $!";
	}

	return $order;
}

sub nnull {
	my($v) = @_;

	return $v if defined $v;;

	return '';
}

sub dump_order {
	my $job = shift;
	my $orderid = $job->{order_id};

	my $agent = $job->{'agent_name'};
	print "agent:$agent:\n";

	my $custno = $job->{'cust_num'};
	my $custseq = $orderid;
	my $labno  = $job->{'lab_num'};

	my $trace_size  = $job->{'trace_size'};
	my $trace_data  = $job->{'trace_value'};

	my $rxname    = "orders/$custno-$labno-$custseq.rx";
	my $tracename = "orders/$custno-$labno-$custseq.tr";

	open  RX,"> $rxname" or die "Can't create $rxname ($!)\n";
	print RX "file_version:1.0\n";
	print RX "start_order\n";
	print RX "order_id:$orderid\n";				delete $job->{'order_id'};
	print RX "agent_name:$job->{'agent_name'}\n";		delete $job->{'agent_name'};
	print RX "agent_version:$job->{'agent_version'}\n";	delete $job->{'agent_version'};
	print RX "lab_num:$job->{'lab_num'}\n";			delete $job->{'lab_num'};
	print RX "cust_num:$job->{'cust_num'}\n";		delete $job->{'cust_num'};

	print "output to $rxname\n";

	my($key, $value);
	foreach $key (sort keys %$job) {
		$value = $job->{$key};
		next if $key eq 'item_list';
		next if $key eq 'item_count';
		next if $key eq 'trace_value';

		next unless defined $value;

		if($key =~ /extra_info/){
			print RX "$value"; #NOTE the extra info stuff has a triling newline
			next
		}

		print RX "$key:$value\n";
	};

	my($items) = $job->{item_list};
	my($item_count) = $job->{item_count};
	my($item, $i);

	for ($i=0; $i < $item_count; ++$i) {
		$item = $items->[$i];

		unless (defined($items->[$i]{item_part_rx})) {
			$items->[$i]{item_part_rx} = 'Y';
		}

		print RX "item_start\n";
		while ( ($key,$value) = each %$item ){
			if( $key =~/order_number/ ) { next };
			if( defined($value) ) { print RX "$key:$value\n"; }
		};
		print RX "item_end\n";
	}

	if(defined($trace_data) && ( length($trace_data) > 0)) {
		open TR,">$tracename";
		print TR $trace_data;
		close TR;
	print RX "trace_file:$tracename\n";
	} else { 
		$tracename = "";
	}

	print RX "end_order\n";
	close RX;
	return ($rxname,$tracename)
}

sub dump_order_buggy {
	my $ref = shift;
	my $sth;
	my $basedir = '.';
my @delfilelist;
my $filename;
my $lab_id;
my $agent;
my $custno;
my $custseq;
my $labno;
my $trace_size;
my $trace_data;
my $key;
my $value;
my $yr;
my $mo;
my $da;
my $hr;
my $min;
my $tag;

	my(%myrow) = %$ref;

	my $orderid = $myrow{'orders_pending_id'};

	open(LOG, ">log");

#	create the file cust#-custseq#-labid.rx
#
	$agent = $myrow{'created_by'};
	print LOG "agent = :$agent:\n";
	if ( ($agent eq "oo") || ($agent eq "oo-agent") ) {
		$custno = $myrow{'user_id'};
		$custseq = $myrow{'orders_pending_id'};
		$labno  = $myrow{'lab_id'};
	} else {
	print LOG "not oo\n";
		$custno = $myrow{'field_acct_id'};
	print LOG "$custno oo\n";
		$custseq = $myrow{'cust_seq_num'};
		$labno  = $myrow{'lab_id'};
	}
	$trace_size  = $myrow{'trace_file_size'};
	$trace_data  = $myrow{'trace_file_data'};
	my $rxname    = "$basedir/$custno-$labno-$custseq.rx";
	my $tracename = "$basedir/$custno-$labno-$custseq.tr";
	open RX,">$rxname";
	print RX "file_version:1.0\n";
	print RX "start_order\n";
	print RX "agent_name:$myrow{'created_by'}\n"; delete $myrow{'created_by'};
	print RX "agent_version:$myrow{'agent_version'}\n";  delete $myrow{'created_by'};
	print RX "lab_id:$myrow{'lab_id'}\n";  delete $myrow{'lab_id'};
	print RX "cust_num:$myrow{'field_acct_id'}\n";  delete $myrow{'field_acct_id'};

	print LOG "output to $rxname\n";
	foreach $key (sort keys %myrow) {
		$value = $myrow{$key};
		if($key =~/extra_info/){
			print RX "$value"; #NOTE the extra info stuff has a triling newline
			next
		}
		if(defined($value)) {
			#	&& ( $tag = $ord_hash_key{$key})){
			$tag = $key;
			print RX "$tag:$value\n";
		}
	};

if (0) {	
	my $query = "select * from order_items where order_number = $orderid ";
	my($dbh) = Cos::Dbh::new;
	if( !($sth = $dbh->prepare($query)) ) {
		print LOG   "Can't prepare $query: Reason $!";
		return;
	} elsif ( !$sth->execute ) {
		print LOG   "Can't execute $query: Reason $!";
		return;
	}
	while($ref = $sth->fetchrow_hashref){
		%myrow = %$ref;
		print RX "item_start\n";
		while ( ($key,$value) = each %myrow ){
			if( $key =~/order_number/ ) { next };
			if( defined($value) ) { print RX "$key:$value\n"; }
		};
		print RX "item_end\n";
	}
	$sth->finish;
	if(defined($trace_data) && ( length($trace_data) > 0)) {
		open TR,">$tracename";
		print TR $trace_data;
		close TR;
	print RX "trace_file:$tracename\n";
	} else { 
		$tracename = "";
	}
}

	close RX;
	return ($rxname,$tracename)
}


sub dump_rx_trace {
	my($ref) = @_;

	my $custno  = $ref->{cust_num};
	my $labno   = $ref->{lab_num};
	my $custseq = $ref->{order_id};

	my $rxname = "orders/$custno-$labno-$custseq.rx";
	my $txname = "orders/$custno-$labno-$custseq.tr";

	my($trace) = trace_value($ref);
	if ($trace) {
		open TX, ">$txname" or die "Can't create $txname ($!)\n";
		print TX $trace;
		close(TX);
	}

#	print "output to $rxname\n" if $Debug;

	open  RX,"> $rxname" or die "Can't create $rxname ($!)\n";
	href(\*RX, $ref, 0);
	close(RX);
}

sub href {
	my($RX, $job, $trace) = @_;

	my $orderid = $job->{order_id};

	my $agent = $job->{'agent_name'};
	print "agent:$agent:\n";

	my $custno = $job->{'cust_num'};
	my $custseq = $orderid;
	my $labno  = $job->{'lab_num'};

	my $trace_size  = $job->{'trace_size'};
	my $trace_data  = $job->{'trace_value'};
	my $trace_file  = $job->{'trace_file'};

	print $RX "file_version:1.0\n";
	print $RX "start_order\n";
	print $RX "order_id:$orderid\n";			delete $job->{'order_id'};
	print $RX "agent_name:$job->{'agent_name'}\n";		delete $job->{'agent_name'};
	print $RX "agent_version:$job->{'agent_version'}\n";	delete $job->{'agent_version'};
	print $RX "lab_num:$job->{'lab_num'}\n";		delete $job->{'lab_num'};
	print $RX "cust_num:$job->{'cust_num'}\n";		delete $job->{'cust_num'};

	my($key, $value);
	foreach $key (sort keys %$job) {
		$value = $job->{$key};
		next if $key eq 'item_list';
		next if $key eq 'item_count';
		next if $key eq 'trace_value';

		if($key =~ /extra_info/){
			print $RX "$value"; #NOTE the extra info stuff has a triling newline
			next
		}

		next unless defined $value;
		print $RX "$key:$value\n";
	};

	my($items) = $job->{item_list};
	my($item_count) = $job->{item_count};
	my($item, $i);

	for ($i=0; $i < $item_count; ++$i) {
		$item = $items->[$i];

		unless (defined($items->[$i]{item_part_rx})) {
			$items->[$i]{item_part_rx} = 'Y';
		}

		print $RX "item_start\n";
		while ( ($key,$value) = each %$item ){
			if( $key =~/order_number/ ) { next };
			if( defined($value) ) { print $RX "$key:$value\n"; }
		};
		print $RX "item_end\n";
	}

#	if(defined($trace_data) && ( length($trace_data) > 0)) {
#		open TR,">$tracename";
#		print TR $trace_data;
#		close TR;
#	print RX "trace_file:$tracename\n";
#	} else { 
#		$tracename = "";
#	}

	print $RX "end_order\n";
}

sub get_desc {
        my($dbh, $sku, $lab) = @_;
        my($sth, $query);
        $query = "select description from treatments_data where stock_num = ? and lab_id = ?";
        if( !($sth = $dbh->prepare($query)) ) {
                print LOG   "Can't prepare $query: Reason $!";
                return;
        } elsif ( !$sth->execute($sku, $lab)) {
                print LOG   "Can't execute $query: Reason $!";
                return;
        }
        my($ref);
        if ($ref = $sth->fetchrow_hashref()) {
                return $ref->{description};
        }
        if ( !$sth->execute($sku, 1)) {
                print LOG   "Can't execute $query: Reason $!";
                return;
        }
        if ($ref = $sth->fetchrow_hashref()) {
                return $ref->{description};
        }
        return '';
}

sub read {
	my($FP) = @_;
	my($ref, $tag, $value);
	my($item_count) = 0;
	my($in_item) = 0;

	# before start of an order.
	while(<$FP>){
		next if /^\s*$/;
		next if /^\s*#/;
		return undef if /^\cZ/;		# dos ^Z

		if( /^file_version:/ ) {
			#print $_ if $Debug;
			next;
		};

		if ( /^start_order/ ) {
			last;
		}

		die "Unknown data at $. $_\n";
		return undef;
	}
	return undef unless defined $_; 

	# found start_order
	while(<$FP>){
		next if /^\s*$/;
		next if /^\s*#/;

		if( /^end_order/ ) {
			$ref->{'item_count'} = $item_count;
			return $ref;
		}

		if( /^item_start/ ) {
			die "bogus item_start at $.\n" if $in_item;
			$in_item = 1;
			next;
		}

		if( /^item_end/ ) {
			die "bogus item_end at $.\n" unless $in_item;
			$in_item = 0;
			$item_count++;
			next;
		}

		s/\n//g;
		s/\r//g;

		($tag, $value) = split ':',$_,2;

		#------------------------------------------------------------
		# fix up in bound data glitches.
		if ($tag eq 'rx_os_axis') {
			$value =~ s/\.00$//;
		}
		#------------------------------------------------------------

		if ($in_item) {
			$ref->{'item_list'}[$item_count]{$tag} = $value;
		} elsif ($tag eq 'trace_file') {
			die "***BUG*** external traces not supported yet\n";
		} else {
			$ref->{$tag} = $value;
		}
	}
	die "Missing end_item/end_order ignoring partial order\n";
	return undef;
}

sub fix_near_far {
	my($t, $r) = @_;

	my($mono) = $r->{lens_SV_MF} || '';
	if ($mono =~ /^[sm]$/ || $mono eq '') {        # 1.5 standard data mode
	    $t->{rx_od_near} = $r->{rx_OD_Near_PD};
	    $t->{rx_os_near} = $r->{rx_OS_Near_PD};

	    $t->{rx_od_far}  = $r->{rx_OD_Far_PD};
	    $t->{rx_os_far}  = $r->{rx_OS_Far_PD};

	    $t->{'lens_sv_mf'} = $mono

	} elsif ($mono =~ /^[SM]$/) {   # 1.4 data mode
	    $t->{rx_od_near} = $r->{rx_OD_Near_PD}/2;
	    $t->{rx_os_near} = $r->{rx_OS_Near_PD}/2;

	    $t->{rx_od_far}  = $r->{rx_OD_Mono_PD};
	    $t->{rx_os_far}  = $r->{rx_OS_Mono_PD};

	    $t->{'lens_sv_mf'} = lc($mono);

	} elsif ($mono eq 'BPD') {      # legacy data
	    $t->{rx_od_far}  = $r->{rx_OD_Mono_PD}/2;
	    $t->{rx_os_far}  = $r->{rx_OS_Mono_PD}/2;

	    $t->{rx_od_near}  = $r->{rx_OD_Near_PD}/2;
	    $t->{rx_os_near}  = $r->{rx_OS_Near_PD}/2;

	    $t->{'lens_sv_mf'} = 'm';

	} elsif ($mono eq 'MON') {
	    $t->{rx_od_far}  = $r->{rx_OD_Mono_PD};
	    $t->{rx_os_far}  = $r->{rx_OS_Mono_PD};

	    $t->{rx_od_near} = $r->{rx_OD_Near_PD};
	    $t->{rx_os_near} = $r->{rx_OS_Near_PD};
	   

	    $t->{'lens_sv_mf'} = 's';

	} else {
	    die "Can't translate mode (lens_SV_MF=$mono)\n";
	}

	if ($t->{'lens_sv_mf'} eq 's') {
		unless ($t->{rx_od_far}) {
			$t->{rx_od_far} = $t->{rx_od_near};
			$t->{rx_od_near} = '';
		}
		unless ($t->{rx_os_far}) {
			$t->{rx_os_far} = $t->{rx_os_near};
			$t->{rx_os_near} = '';
		}
	}
}

sub fix_misc_mounting {
	my($ref) = @_;

        my($mounting) = $ref->{frame_mounting} || '';
	my($tag) = $mounting;

	return if $mounting eq '';

	$tag = 'METAL' if $tag eq 'METALFRAME';

	foreach my $item (@{$ref->{item_list}}) {
		next if $item->{item_source} ne 'MISC';

		# got tag
		return if $item->{sku} eq $mounting;
		return if $item->{sku} eq $tag;
	}
	add_item($ref, $tag, 'MISC', 'Y', '', '');
}

sub add_item {
        # ($to, 7413, 'MISC', 'Y' 'BEVEL EDGES', $bevel_desc);
        my($job, $sku, $source, $partrx, $value, $desc) = @_;
                                                                                                                        
        my($item_count) = $job->{item_count} || 0;
        my($items) = $job->{item_list};
        $items->[$item_count] = {
                'sku'                   => $sku,
                'item_description'      => $desc,
                'item_part_rx'          => $partrx,
                'item_side'             => 'NONE',
                'item_quantity'         => 1,
                'item_value'            => $value,
                'item_source'           => $source,
        };
        ++$item_count;
                                                                                                                        
        $job->{item_count} = $item_count;
        $job->{item_list} = $items;
}

sub extract_info {
	my($job, $db) = @_;

	my($extra) = '';
	my($fixed) = 0;
	my($field, $value);
	foreach my $info (split(/\n/, $db->{extra_info})) {
		($field, $value) = split(':', $info, 2);

		if (defined $ord_tab_hash->{$field}
		and         $ord_tab_hash->{$field} eq '+') {
			$value =~ s/^\s+//;
			chomp $value;

			$job->{$field} = $value;
			$fixed = 1;
		} else {
			$extra .= $info . "\n";
		}
	}
	if ($fixed) {
		$job->{extra_info} = $extra;
	} else {
		$job->{extra_info} = $db->{extra_info};
	}
}

1;
