package Cos::Values;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	Set_Order
	get

	get_store_invoice_num
	getDayOfMonth
	getLens_OD_ColorCode
	getLens_OD_MaterCode
	getLens_OD_StyleCode
	getLens_OS_ColorCode
	getLens_OS_MaterCode
	getLens_OS_StyleCode
	getMonth
	getAgentVersion
	getCombo_orderType
	getCreatedBy
	getCreatedDate
	getDateOrdered
	getDatePromised
	getFdA
	getFdB
	getFdBridge
	getFdCirc
	getFdDBL
	getFdED
	getFdEye
	getFdSource
	getFdTemple
	getField_Acct_Id
	getField_Client_Addr
	getField_Client_Name
	getFp_dress
	getFp_edged
	getFp_mounting
	getFs1_color
	getFs1_model
	getFs1_upc
	getFs1_vendor
	getInstructions
	getIPAddress
	getIPName
	getLab_Id
	getLastAccess
	getLens_OD_Color
	getLens_OD_Material
	getLens_OD_Style
	getLens_OS_Color
	getLens_OS_Material
	getLens_OS_Style
	getLens_Pair
	getLens_SV_MF
	getOrderNumber
	getRedoOrderNum
	getRx_OD_Add
	getRx_OD_Axis
	getRx_OD_Base
	getRx_OD_Cylinder
	getRx_OD_Diopters
	getRx_OD_Far_PD
	getRx_OD_Mono_PD
	getRx_OD_Near_PD
	getRx_OD_OC_Height
	getRx_OD_Prism2_Diopters
	getRx_OD_Prism2
	getRx_OD_Prism_Angle_Val
	getRx_OD_Prism_Diopters
	getRx_OD_Prism
	getRx_OD_Seg_Height
	getRx_OD_Special_Base_Curve
	getRx_OD_Special_Thickness
	getRx_OD_Sphere
	getRx_OD_Thickness_Reference
	getRx_OS_Add
	getRx_OS_Axis
	getRx_OS_Base
	getRx_OS_Cylinder
	getRx_OS_Diopters
	getRx_OS_Far_PD
	getRx_OS_Mono_PD
	getRx_OS_Near_PD
	getRx_OS_OC_Height
	getRx_OS_Prism2_Diopters
	getRx_OS_Prism2
	getRx_OS_Prism_Angle_Val
	getRx_OS_Prism_Diopters
	getRx_OS_Prism
	getRx_OS_Seg_Height
	getRx_OS_Special_Base_Curve
	getRx_OS_Special_Thickness
	getRx_OS_Sphere
	getRx_OS_Thickness_Reference
	getSeqNum
	getStatus
	getStore
	getTimePromised
	getTr_AntiReflective_Code
	getTr_AntiReflective
	getTrayNo
	getTr_Coating_Code
	getTr_Coating
	getTr_Other1_Code
	getTr_Other1
	getTr_Other2_Code
	getTr_Other2
	getTr_Other3_Code
	getTr_Other3
	getTr_Other4_Code
	getTr_Other4
	getTr_Other5_Code
	getTr_Other5
	getTr_TintColor
	getTr_Tinting_Code
	getTr_Tinting
	getTr_TintPerCent
	getTr_Treatment_Code
	getTr_Treatment
	getUser_Id

	getL_Enclosed
	getR_Enclosed
	getRedoCode
	setRx_OD_Prism_Angle_Val
	setRx_OS_Prism_Angle_Val
	setRx_OD_Prism_Diopters
	setRx_OS_Prism_Diopters
);

my $Order;

# mapping info

sub get($)				{ return $Order->{$_[0]}; };

sub  get_store_invoice_num()		{ return $Order->{store_invoice_num}; }
sub  getDayOfMonth()			{ return $Order->{DayOfMonth}; }
sub  getLens_OD_ColorCode()		{ return $Order->{lens_OD_ColorCode_int}; }
sub  getLens_OD_MaterCode()		{ return $Order->{lens_OD_MaterCode_int}; }
sub  getLens_OD_StyleCode()		{ return $Order->{lens_OD_StyleCode_int}; }
sub  getLens_OS_ColorCode()		{ return $Order->{lens_OS_ColorCode_int}; }
sub  getLens_OS_MaterCode()		{ return $Order->{lens_OS_MaterCode_int}; }
sub  getLens_OS_StyleCode()		{ return $Order->{lens_OS_StyleCode_int}; }
sub  getMonth()				{ return $Order->{Month}; }
sub  getAgentVersion()			{ return $Order->{agentVersion}; }
sub  getCombo_orderType()		{ return $Order->{combo_orderType_str}; }
sub  getCreatedBy()			{ return $Order->{createdBy}; }
sub  getCreatedDate()			{ return $Order->{createdDate}; }
sub  getDateOrdered()			{ return $Order->{DateOrdered}; }
sub  getDatePromised()			{ return $Order->{DatePromised}; }
sub  getFdA()				{ return $Order->{fdA_str}; }
sub  getFdB()				{ return $Order->{fdB_str}; }
sub  getFdBridge()			{ return $Order->{fdBridge_str}; }
sub  getFdCirc()			{ return $Order->{fdCirc_str}; }
sub  getFdDBL()				{ return $Order->{fdDBL_str}; }
sub  getFdED()				{ return $Order->{fdED_str}; }
sub  getFdEye()				{ return $Order->{fdEye_str}; }
sub  getFdSource()			{ return $Order->{fdSource_str}; }
sub  getFdTemple()			{ return $Order->{fdTemple_str}; }
sub  getField_Acct_Id()			{ return $Order->{field_acct_id_str}; }
sub  getField_Client_Addr()		{ return $Order->{field_client_addr_str}; }
sub  getField_Client_Name()		{ return $Order->{field_client_name_str}; }
sub  getFp_dress()			{ return $Order->{fp_dress_str}; }
sub  getFp_edged()			{ return $Order->{fp_edged_str}; }
sub  getFp_mounting()			{ return $Order->{fp_mounting_str}; }
sub  getFs1_color()			{ return $Order->{fs1_color_str}; }
sub  getFs1_model()			{ return $Order->{fs1_model_str}; }
sub  getFs1_upc()			{ return $Order->{fs1_upc_str}; }
sub  getFs1_vendor()			{ return $Order->{fs1_vendor_str}; }
sub  getInstructions()			{ return $Order->{instText_str}; }
sub  getIPAddress()			{ return $Order->{IPAddress}; }
sub  getIPName()			{ return $Order->{IPName}; }
sub  getLab_Id()			{ return $Order->{lab_id_str}; }
sub  getLastAccess()			{ return $Order->{lastAccess}; }
sub  getLens_OD_Color()			{ return $Order->{lens_OD_Color_str}; }
sub  getLens_OD_Material()		{ return $Order->{lens_OD_Material_str}; }
sub  getLens_OD_Style()			{ return $Order->{lens_OD_Style_str}; }
sub  getLens_OS_Color()			{ return $Order->{lens_OS_Color_str}; }
sub  getLens_OS_Material()		{ return $Order->{lens_OS_Material_str}; }
sub  getLens_OS_Style()			{ return $Order->{lens_OS_Style_str}; }
sub  getLens_Pair()			{ return $Order->{lens_Pair_str}; }
sub  getLens_SV_MF()			{ return $Order->{lens_SV_MF_str}; }
sub  getOrderNumber()			{ return $Order->{orderNumber}; }
sub  getRedoOrderNum()			{ return $Order->{redo_order_num}; }
sub  getRx_OD_Add()			{ return $Order->{rx_OD_Add_str}; }
sub  getRx_OD_Axis()			{ return $Order->{rx_OD_Axis_str}; }
sub  getRx_OD_Base()			{ return $Order->{rx_OD_Base_str}; }
sub  getRx_OD_Cylinder()		{ return $Order->{rx_OD_Cylinder_str}; }
sub  getRx_OD_Diopters()		{ return $Order->{rx_OD_Diopters_str}; }
sub  getRx_OD_Far_PD()			{ return $Order->{rx_OD_Far_PD_str}; }
sub  getRx_OD_Mono_PD()			{ return $Order->{rx_OD_Mono_PD_str}; }
sub  getRx_OD_Near_PD()			{ return $Order->{rx_OD_Near_PD_str}; }
sub  getRx_OD_OC_Height()		{ return $Order->{rx_OD_OC_Height_str}; }
sub  getRx_OD_Prism2_Diopters()		{ return $Order->{rx_OD_Prism2_Diopters_str}; }
sub  getRx_OD_Prism2()			{ return $Order->{rx_OD_Prism2_str}; }
sub  getRx_OD_Prism_Angle_Val()		{ return $Order->{rx_OD_Prism_Angle_Val_str}; }
sub  getRx_OD_Prism_Diopters()		{ return $Order->{rx_OD_Prism_Diopters_str}; }
sub  getRx_OD_Prism()			{ return $Order->{rx_OD_Prism_str}; }
sub  getRx_OD_Seg_Height()		{ return $Order->{rx_OD_Seg_Height_str}; }
sub  getRx_OD_Special_Base_Curve()	{ return $Order->{rx_OD_Special_Base_Curve_str}; }
sub  getRx_OD_Special_Thickness()	{ return $Order->{rx_OD_Special_Thickness_str}; }
sub  getRx_OD_Sphere()			{ return $Order->{rx_OD_Sphere_str}; }
sub  getRx_OD_Thickness_Reference()	{ return $Order->{rx_OD_Thickness_Reference_str}; }
sub  getRx_OS_Add()			{ return $Order->{rx_OS_Add_str}; }
sub  getRx_OS_Axis()			{ return $Order->{rx_OS_Axis_str}; }
sub  getRx_OS_Base()			{ return $Order->{rx_OS_Base_str}; }
sub  getRx_OS_Cylinder()		{ return $Order->{rx_OS_Cylinder_str}; }
sub  getRx_OS_Diopters()		{ return $Order->{rx_OS_Diopters_str}; }
sub  getRx_OS_Far_PD()			{ return $Order->{rx_OS_Far_PD_str}; }
sub  getRx_OS_Mono_PD()			{ return $Order->{rx_OS_Mono_PD_str}; }
sub  getRx_OS_Near_PD()			{ return $Order->{rx_OS_Near_PD_str}; }
sub  getRx_OS_OC_Height()		{ return $Order->{rx_OS_OC_Height_str}; }
sub  getRx_OS_Prism2_Diopters()		{ return $Order->{rx_OS_Prism2_Diopters_str}; }
sub  getRx_OS_Prism2()			{ return $Order->{rx_OS_Prism2_str}; }
sub  getRx_OS_Prism_Angle_Val()		{ return $Order->{rx_OS_Prism_Angle_Val_str}; }
sub  getRx_OS_Prism_Diopters()		{ return $Order->{rx_OS_Prism_Diopters_str}; }
sub  getRx_OS_Prism()			{ return $Order->{rx_OS_Prism_str}; }
sub  getRx_OS_Seg_Height()		{ return $Order->{rx_OS_Seg_Height_str}; }
sub  getRx_OS_Special_Base_Curve()	{ return $Order->{rx_OS_Special_Base_Curve_str}; }
sub  getRx_OS_Special_Thickness()	{ return $Order->{rx_OS_Special_Thickness_str}; }
sub  getRx_OS_Sphere()			{ return $Order->{rx_OS_Sphere_str}; }
sub  getRx_OS_Thickness_Reference()	{ return $Order->{rx_OS_Thickness_Reference_str}; }
sub  getSeqNum()			{ return $Order->{seqNum_str}; }
sub  getStatus()			{ return $Order->{status}; }
sub  getStore()				{ return $Order->{customer_id}; }
sub  getTimePromised()			{ return $Order->{TimePromised}; }
sub  getTr_AntiReflective_Code()	{ return $Order->{tr_AntiReflective_code}; }
sub  getTr_AntiReflective()		{ return $Order->{tr_AntiReflective_str}; }
sub  getTrayNo()			{ 
	$Order->{trayNo} =~ s/^0+//;

	return $Order->{trayNo};
}
sub  getTr_Coating_Code()		{ return $Order->{tr_Coating_code}; }
sub  getTr_Coating()			{ return $Order->{tr_Coating_str}; }
sub  getTr_Other1_Code()		{ return $Order->{tr_Other1_code}; }
sub  getTr_Other1()			{ return $Order->{tr_Other1_str}; }
sub  getTr_Other2_Code()		{ return $Order->{tr_Other2_code}; }
sub  getTr_Other2()			{ return $Order->{tr_Other2_str}; }
sub  getTr_Other3_Code()		{ return $Order->{tr_Other3_code}; }
sub  getTr_Other3()			{ return $Order->{tr_Other3_str}; }
sub  getTr_Other4_Code()		{ return $Order->{tr_Other4_code}; }
sub  getTr_Other4()			{ return $Order->{tr_Other4_str}; }
sub  getTr_Other5_Code()		{ return $Order->{tr_Other5_code}; }
sub  getTr_Other5()			{ return $Order->{tr_Other5_str}; }
sub  getTr_TintColor()			{ return $Order->{tr_TintColor_str}; }
sub  getTr_Tinting_Code()		{ return $Order->{tr_Tinting_code}; }
sub  getTr_Tinting()			{ return $Order->{tr_Tinting_str}; }
sub  getTr_TintPerCent()		{ return $Order->{tr_TintPerCent_str}; }
sub  getTr_Treatment_Code()		{ return $Order->{tr_Treatment_code}; }
sub  getTr_Treatment()			{ return $Order->{tr_Treatment_str}; }
sub  getUser_Id()			{ return $Order->{user_id_str}; }

sub getL_Enclosed()			{ return ''; } # ***BUG*** 
sub getR_Enclosed()			{ return ''; } # ***BUG*** 
sub getRedoCode()			{ return ''; } # ***BUG*** 

sub setAgentVersion			{ $Order->{agentVersion} = $_[0]; }
sub setCombo_orderType			{ $Order->{combo_orderType_str} = $_[0]; }
sub setCreatedBy			{ $Order->{createdBy} = $_[0]; }
sub setCreatedDate			{ $Order->{createdDate} = $_[0]; }
sub setDateOrdered			{ $Order->{DateOrdered} = $_[0]; }
sub setDatePromised			{ $Order->{DatePromised} = $_[0]; }
sub setDayOfMonth			{ $Order->{DayOfMonth} = $_[0]; }
sub setDispenser			{ $Order->{Dispenser} = $_[0]; }
sub setFdA				{ $Order->{fdA_str} = $_[0]; }
sub setFdBridge				{ $Order->{fdBridge_str} = $_[0]; }
sub setFdB				{ $Order->{fdB_str} = $_[0]; }
sub setFdCirc				{ $Order->{fdCirc_str} = $_[0]; }
sub setFdDBL				{ $Order->{fdDBL_str} = $_[0]; }
sub setFdED				{ $Order->{fdED_str} = $_[0]; }
sub setFdEye				{ $Order->{fdEye_str} = $_[0]; }
sub setFdSource				{ $Order->{fdSource_str} = $_[0]; }
sub setFdTemple				{ $Order->{fdTemple_str} = $_[0]; }
sub setField_Acct_Id			{ $Order->{field_acct_id_str} = $_[0]; }
sub setField_Client_Addr		{ $Order->{field_client_addr_str} = $_[0]; }
sub setField_Client_Name		{ $Order->{field_client_name_str} = $_[0]; }
sub setFp_dress				{ $Order->{fp_dress_str} = $_[0]; }
sub setFp_edged				{ $Order->{fp_edged_str} = $_[0]; }
sub setFp_mounting			{ $Order->{fp_mounting_str} = $_[0]; }
sub setFs1_color			{ $Order->{fs1_color_str} = $_[0]; }
sub setFs1_model			{ $Order->{fs1_model_str} = $_[0]; }
sub setFs1_upc				{ $Order->{fs1_upc_str} = $_[0]; }
sub setFs1_vendor			{ $Order->{fs1_vendor_str} = $_[0]; }
sub setInstructions			{ $Order->{instText_str} = $_[0]; }
sub setIPAddress			{ $Order->{IPAddress} = $_[0]; }
sub setIPName				{ $Order->{IPName} = $_[0]; }
sub setLab_Id				{ $Order->{lab_id_str} = $_[0]; }
sub setLastAccess			{ $Order->{lastAccess} = $_[0]; }	# this is ignored on DB inserts!
sub setLens_OD_ColorCode		{ $Order->{lens_OD_ColorCode_int} = $_[0]; }
sub setLens_OD_Color			{ $Order->{lens_OD_Color_str} = $_[0]; }
sub setLens_OD_MaterCode		{ $Order->{lens_OD_MaterCode_int} = $_[0]; }
sub setLens_OD_Material			{ $Order->{lens_OD_Material_str} = $_[0]; }
sub setLens_OD_StyleCode		{ $Order->{lens_OD_StyleCode_int} = $_[0]; }
sub setLens_OD_Style			{ $Order->{lens_OD_Style_str} = $_[0]; }
sub setLens_OS_ColorCode		{ $Order->{lens_OS_ColorCode_int} = $_[0]; }
sub setLens_OS_Color			{ $Order->{lens_OS_Color_str} = $_[0]; }
sub setLens_OS_MaterCode		{ $Order->{lens_OS_MaterCode_int} = $_[0]; }
sub setLens_OS_Material			{ $Order->{lens_OS_Material_str} = $_[0]; }
sub setLens_OS_StyleCode		{ $Order->{lens_OS_StyleCode_int} = $_[0]; }
sub setLens_OS_Style			{ $Order->{lens_OS_Style_str} = $_[0]; }
sub setLens_Pair			{ $Order->{lens_Pair_str} = $_[0]; }
sub setLens_SV_MF			{ $Order->{lens_SV_MF_str} = $_[0]; }
sub setMonth				{ $Order->{Month} = $_[0]; }	# no DB insert
sub setOrderNumber			{ $Order->{orderNumber} = $_[0]; }	# this is ignored on DB inserts!
sub setRedoOrderNum			{ $Order->{redo_order_num} = $_[0]; }	
sub setRx_OD_Add			{ $Order->{rx_OD_Add_str} = $_[0]; }
sub setRx_OD_Axis			{ $Order->{rx_OD_Axis_str} = $_[0]; }
sub setRx_OD_Base			{ $Order->{rx_OD_Base_str} = $_[0]; }
sub setRx_OD_Cylinder			{ $Order->{rx_OD_Cylinder_str} = $_[0]; }
sub setRx_OD_Diopters			{ $Order->{rx_OD_Diopters_str} = $_[0]; }
sub setRx_OD_Far_PD			{ $Order->{rx_OD_Far_PD_str} = $_[0]; }
sub setRx_OD_Mono_PD			{ $Order->{rx_OD_Mono_PD_str} = $_[0]; }
sub setRx_OD_Near_PD			{ $Order->{rx_OD_Near_PD_str} = $_[0]; }
sub setRx_OD_OC_Height			{ $Order->{rx_OD_OC_Height_str} = $_[0]; }
sub setRx_OD_Prism2_Diopters		{ $Order->{rx_OD_Prism2_Diopters_str} = $_[0]; }
sub setRx_OD_Prism2			{ $Order->{rx_OD_Prism2_str} = $_[0]; }
sub setRx_OD_Prism_Angle_Val		{ $Order->{rx_OD_Prism_Angle_Val_str} = $_[0]; }
sub setRx_OD_Prism_Diopters		{ $Order->{rx_OD_Prism_Diopters_str} = $_[0]; }
sub setRx_OD_Prism			{ $Order->{rx_OD_Prism_str} = $_[0]; }
sub setRx_OD_Seg_Height			{ $Order->{rx_OD_Seg_Height_str} = $_[0]; }
sub setRx_OD_Special_Base_Curve		{ $Order->{rx_OD_Special_Base_Curve_str} = $_[0]; }
sub setRx_OD_Special_Thickness		{ $Order->{rx_OD_Special_Thickness_str} = $_[0]; }
sub setRx_OD_Sphere			{ $Order->{rx_OD_Sphere_str} = $_[0]; }
sub setRx_OD_Thickness_Reference	{ $Order->{rx_OD_Thickness_Reference_str} = $_[0]; }
sub setRx_OS_Add			{ $Order->{rx_OS_Add_str} = $_[0]; }
sub setRx_OS_Axis			{ $Order->{rx_OS_Axis_str} = $_[0]; }
sub setRx_OS_Base			{ $Order->{rx_OS_Base_str} = $_[0]; }
sub setRx_OS_Cylinder			{ $Order->{rx_OS_Cylinder_str} = $_[0]; }
sub setRx_OS_Diopters			{ $Order->{rx_OS_Diopters_str} = $_[0]; }
sub setRx_OS_Far_PD			{ $Order->{rx_OS_Far_PD_str} = $_[0]; }
sub setRx_OS_Mono_PD			{ $Order->{rx_OS_Mono_PD_str} = $_[0]; }
sub setRx_OS_Near_PD			{ $Order->{rx_OS_Near_PD_str} = $_[0]; }
sub setRx_OS_OC_Height			{ $Order->{rx_OS_OC_Height_str} = $_[0]; }
sub setRx_OS_Prism2_Diopters		{ $Order->{rx_OS_Prism2_Diopters_str} = $_[0]; }
sub setRx_OS_Prism2			{ $Order->{rx_OS_Prism2_str} = $_[0]; }
sub setRx_OS_Prism_Angle_Val		{ $Order->{rx_OS_Prism_Angle_Val_str} = $_[0]; }
sub setRx_OS_Prism_Diopters		{ $Order->{rx_OS_Prism_Diopters_str} = $_[0]; }
sub setRx_OS_Prism			{ $Order->{rx_OS_Prism_str} = $_[0]; }
sub setRx_OS_Seg_Height			{ $Order->{rx_OS_Seg_Height_str} = $_[0]; }
sub setRx_OS_Special_Base_Curve		{ $Order->{rx_OS_Special_Base_Curve_str} = $_[0]; }
sub setRx_OS_Special_Thickness		{ $Order->{rx_OS_Special_Thickness_str} = $_[0]; }
sub setRx_OS_Sphere			{ $Order->{rx_OS_Sphere_str} = $_[0]; }
sub setRx_OS_Thickness_Reference	{ $Order->{rx_OS_Thickness_Reference_str} = $_[0]; }
sub setSeqNum				{ $Order->{seqNum_str} = $_[0]; }
sub setStatus				{ $Order->{status} = $_[0];}
sub setStoreNum				{ $Order->{customer_id} = $_[0]; }
sub setTimePromised			{ $Order->{TimePromised} = $_[0]; }	# no DB insert
sub setTr_AntiReflective_Code		{ $Order->{tr_AntiReflective_code} = $_[0]; }
sub setTr_AntiReflective		{ $Order->{tr_AntiReflective_str} = $_[0]; }
sub setTrayNo				{ $Order->{trayNo} = $_[0]; }	
sub setTr_Coating_Code			{ $Order->{tr_Coating_code} = $_[0]; }
sub setTr_Coating			{ $Order->{tr_Coating_str} = $_[0]; }
sub setTr_Other1_Code			{ $Order->{tr_Other1_code} = $_[0]; }
sub setTr_Other1			{ $Order->{tr_Other1_str} = $_[0]; }
sub setTr_Other2_Code			{ $Order->{tr_Other2_code} = $_[0]; }
sub setTr_Other2			{ $Order->{tr_Other2_str} = $_[0]; }
sub setTr_Other3_Code			{ $Order->{tr_Other3_code} = $_[0]; }
sub setTr_Other3			{ $Order->{tr_Other3_str} = $_[0]; }
sub setTr_Other4_Code			{ $Order->{tr_Other4_code} = $_[0]; }
sub setTr_Other4			{ $Order->{tr_Other4_str} = $_[0]; }
sub setTr_Other5_Code			{ $Order->{tr_Other5_code} = $_[0]; }
sub setTr_Other5			{ $Order->{tr_Other5_str} = $_[0]; }
sub setTr_TintColor			{ $Order->{tr_TintColor_str} = $_[0]; }
sub setTr_Tinting_Code			{ $Order->{tr_Tinting_code} = $_[0]; }
sub setTr_Tinting			{ $Order->{tr_Tinting_str} = $_[0]; }
sub setTr_TintPerCent			{ $Order->{tr_TintPerCent_str} = $_[0]; }
sub setTr_Treatment_Code		{ $Order->{tr_Treatment_code} = $_[0]; }
sub setTr_Treatment			{ $Order->{tr_Treatment_str} = $_[0]; }
sub setUser_Id				{ $Order->{user_id_str} = $_[0]; }

sub Set_Order {
	my($aOrder) = @_;

	$Order = {};

	# Fixed access
	$Order->{customer_id} =		$aOrder->{customer_id};
	$Order->{store_invoice_num} =   $aOrder->{store_invoice_num};
	if ($Order->{store_invoice_num} == -1) {
		$Order->{store_invoice_num} = 0;
	}

	$Order->{lens_OD_BlankSize} =   $aOrder->{lens_OD_BlankSize};
	$Order->{lens_OS_BlankSize} =   $aOrder->{lens_OS_BlankSize};

	$Order->{lens_SV_MF} =          $aOrder->{lens_SV_MF};

	$Order->{cust_doctor}       =   $aOrder->{cust_doctor};
	$Order->{cust_doctor} = '' unless defined $Order->{cust_doctor};

	if ($aOrder->{created_by} =~ /^oo-/) {
		$Order->{cust_dispenser}  ||=   'disp';
	} else {
		$Order->{cust_dispenser}    =   $aOrder->{cust_dispenser};
	}

	# Object oriented BS
	# bookkeeping
	setOrderNumber(			$aOrder->{orders_pending_id});
	setLastAccess(			$aOrder->{last_access});
	setIPAddress(			$aOrder->{ip_address});
	setIPName(			$aOrder->{ip_name});
	setAgentVersion(		$aOrder->{agent_version});
	setStatus(			$aOrder->{status});
	setCreatedBy(			$aOrder->{created_by});
	setCreatedDate(			$aOrder->{created_date});


	# *** BUG ****
	setDayOfMonth(			$aOrder->{day});
	setMonth(			$aOrder->{month});
	setDateOrdered(			$aOrder->{dateOrdered});
	setDatePromised(		$aOrder->{datePromised});
	setTimePromised(		$aOrder->{timePromised});

	setField_Acct_Id(		$aOrder->{field_acct_id});
	setField_Client_Name(		$aOrder->{field_client_name});
	setField_Client_Addr(		$aOrder->{field_client_addr});
	setCombo_orderType(		$aOrder->{combo_orderType});
	setInstructions(		$aOrder->{instText});
	setTrayNo(			$aOrder->{tray_no});
	setRedoOrderNum(		$aOrder->{redo_order_num});

	# frames
	setFdSource(			$aOrder->{fdSource});
	setFs1_vendor(			$aOrder->{fs1_vendor});
	setFs1_model(			$aOrder->{fs1_model});
	setFs1_color(			$aOrder->{fs1_color});
	setFs1_upc(			$aOrder->{fs1_upc});
	setFp_mounting(			$aOrder->{fp_mounting});
	setFp_edged(			$aOrder->{fp_edged});
	setFp_dress(			$aOrder->{fp_dress});

	setFdEye(			$aOrder->{fdEye});
	setFdBridge(			$aOrder->{fdBridge});
	setFdTemple(			$aOrder->{fdTemple});
	setFdA(				$aOrder->{fdA});
	setFdB(				$aOrder->{fdB});
	setFdED(			$aOrder->{fdED});
	setFdDBL(			$aOrder->{fdDBL});
	setFdCirc(			$aOrder->{fdCirc});

	# Lenses
	setLens_SV_MF(			$aOrder->{lens_SV_MF});
	setLens_Pair(			$aOrder->{lens_Pair});
	setLens_OD_Style(		$aOrder->{lens_OD_Style});
	setLens_OD_Material(		$aOrder->{lens_OD_Material});
	setLens_OD_Color(		$aOrder->{lens_OD_Color});
	setLens_OS_Style(		$aOrder->{lens_OS_Style});
	setLens_OS_Material(		$aOrder->{lens_OS_Material});
	setLens_OS_Color(		$aOrder->{lens_OS_Color});

	setTr_Treatment_Code(		$aOrder->{tr_Treatment_code});
	setTr_Treatment(		$aOrder->{tr_Treatment});
	setTr_Tinting_Code(		$aOrder->{tr_Tinting_code});
	setTr_Tinting(			$aOrder->{tr_Tinting});
	setTr_TintColor(		$aOrder->{tr_TintColor});
	setTr_TintPerCent(		$aOrder->{tr_TintPerCent});
	setTr_Coating_Code(		$aOrder->{tr_Coating_code});
	setTr_Coating(			$aOrder->{tr_Coating});
	setTr_AntiReflective_Code(	$aOrder->{tr_AR_code});
	setTr_AntiReflective(		$aOrder->{tr_AntiReflective});
	setTr_Other1_Code(		$aOrder->{tr_Other1_code});
	setTr_Other2_Code(		$aOrder->{tr_Other2_code});
	setTr_Other3_Code(		$aOrder->{tr_Other3_code});
	setTr_Other4_Code(		$aOrder->{tr_Other4_code});
	setTr_Other5_Code(		$aOrder->{tr_Other5_code});
	setTr_Other1(			$aOrder->{tr_Other1});
	setTr_Other2(			$aOrder->{tr_Other2});
	setTr_Other3(			$aOrder->{tr_Other3});
	setTr_Other4(			$aOrder->{tr_Other4});
	setTr_Other5(			$aOrder->{tr_Other5});

	# Rx
	setRx_OD_Sphere(		$aOrder->{rx_OD_Sphere});
	setRx_OD_Cylinder(		$aOrder->{rx_OD_Cylinder});
	setRx_OD_Axis(			$aOrder->{rx_OD_Axis});
	setRx_OD_Add(			$aOrder->{rx_OD_Add});
	setRx_OD_Near_PD(		$aOrder->{rx_OD_Near_PD});
	setRx_OD_Far_PD(		$aOrder->{rx_OD_Far_PD});
	setRx_OD_Mono_PD(		$aOrder->{rx_OD_Mono_PD});
	setRx_OD_Prism_Diopters(	$aOrder->{rx_OD_Prism_Diopters});
	setRx_OD_Prism(			$aOrder->{rx_OD_Prism});
	setRx_OD_Prism_Angle_Val(	$aOrder->{rx_OD_Prism_Angle_Val});
	setRx_OD_Prism2_Diopters(	$aOrder->{rx_OD_Prism2_Diopters});
	setRx_OD_Prism2(		$aOrder->{rx_OD_Prism2});
	setRx_OD_Diopters(		$aOrder->{rx_OD_Diopters});
	setRx_OD_Base(			$aOrder->{rx_OD_Base});
	setRx_OD_Seg_Height(		$aOrder->{rx_OD_Seg_Height});
	setRx_OD_OC_Height(		$aOrder->{rx_OD_OC_Height});
	setRx_OD_Special_Base_Curve(	$aOrder->{rx_OD_Special_Base_Curve});
	setRx_OD_Thickness_Reference(	$aOrder->{rx_OD_Thickness_Reference});
	setRx_OD_Special_Thickness(	$aOrder->{rx_OD_Special_Thickness});

	setRx_OS_Sphere(		$aOrder->{rx_OS_Sphere});
	setRx_OS_Cylinder(		$aOrder->{rx_OS_Cylinder});
	setRx_OS_Axis(			$aOrder->{rx_OS_Axis});
	setRx_OS_Add(			$aOrder->{rx_OS_Add});
	setRx_OS_Near_PD(		$aOrder->{rx_OS_Near_PD});
	setRx_OS_Far_PD(		$aOrder->{rx_OS_Far_PD});
	setRx_OS_Mono_PD(		$aOrder->{rx_OS_Mono_PD});
	setRx_OS_Prism_Diopters(	$aOrder->{rx_OS_Prism_Diopters});
	setRx_OS_Prism(			$aOrder->{rx_OS_Prism});
	setRx_OS_Prism_Angle_Val(	$aOrder->{rx_OS_Prism_Angle_Val});
	setRx_OS_Prism2_Diopters(	$aOrder->{rx_OS_Prism2_Diopters});
	setRx_OS_Prism2(		$aOrder->{rx_OS_Prism2});
	setRx_OS_Diopters(		$aOrder->{rx_OS_Diopters});
	setRx_OS_Base(			$aOrder->{rx_OS_Base});
	setRx_OS_Seg_Height(		$aOrder->{rx_OS_Seg_Height});
	setRx_OS_OC_Height(		$aOrder->{rx_OS_OC_Height});
	setRx_OS_Special_Base_Curve(	$aOrder->{rx_OS_Special_Base_Curve});
	setRx_OS_Thickness_Reference(	$aOrder->{rx_OS_Thickness_Reference});
	setRx_OS_Special_Thickness(	$aOrder->{rx_OS_Special_Thickness});

	# mapping info
	setLab_Id(			$aOrder->{lab_id});
	setUser_Id(			$aOrder->{user_id});
	setSeqNum(			$aOrder->{seqNum});

	setLens_OD_StyleCode(		$aOrder->{lens_OD_StyleCode});
	setLens_OD_MaterCode(		$aOrder->{lens_OD_MaterCode});
	setLens_OD_ColorCode(		$aOrder->{lens_OD_ColorCode});
	setLens_OS_StyleCode(		$aOrder->{lens_OS_StyleCode});
	setLens_OS_MaterCode(		$aOrder->{lens_OS_MaterCode});
	setLens_OS_ColorCode(		$aOrder->{lens_OS_ColorCode});
}

1;
