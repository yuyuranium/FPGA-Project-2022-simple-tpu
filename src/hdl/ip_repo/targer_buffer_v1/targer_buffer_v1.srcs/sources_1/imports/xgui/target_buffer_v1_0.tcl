# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDRWIDTHA" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDRWIDTHB" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SIZEA" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SIZEB" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WIDTHA" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WIDTHB" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDRWIDTHA { PARAM_VALUE.ADDRWIDTHA } {
	# Procedure called to update ADDRWIDTHA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDRWIDTHA { PARAM_VALUE.ADDRWIDTHA } {
	# Procedure called to validate ADDRWIDTHA
	return true
}

proc update_PARAM_VALUE.ADDRWIDTHB { PARAM_VALUE.ADDRWIDTHB } {
	# Procedure called to update ADDRWIDTHB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDRWIDTHB { PARAM_VALUE.ADDRWIDTHB } {
	# Procedure called to validate ADDRWIDTHB
	return true
}

proc update_PARAM_VALUE.SIZEA { PARAM_VALUE.SIZEA } {
	# Procedure called to update SIZEA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SIZEA { PARAM_VALUE.SIZEA } {
	# Procedure called to validate SIZEA
	return true
}

proc update_PARAM_VALUE.SIZEB { PARAM_VALUE.SIZEB } {
	# Procedure called to update SIZEB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SIZEB { PARAM_VALUE.SIZEB } {
	# Procedure called to validate SIZEB
	return true
}

proc update_PARAM_VALUE.WIDTHA { PARAM_VALUE.WIDTHA } {
	# Procedure called to update WIDTHA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WIDTHA { PARAM_VALUE.WIDTHA } {
	# Procedure called to validate WIDTHA
	return true
}

proc update_PARAM_VALUE.WIDTHB { PARAM_VALUE.WIDTHB } {
	# Procedure called to update WIDTHB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WIDTHB { PARAM_VALUE.WIDTHB } {
	# Procedure called to validate WIDTHB
	return true
}


proc update_MODELPARAM_VALUE.WIDTHB { MODELPARAM_VALUE.WIDTHB PARAM_VALUE.WIDTHB } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WIDTHB}] ${MODELPARAM_VALUE.WIDTHB}
}

proc update_MODELPARAM_VALUE.SIZEB { MODELPARAM_VALUE.SIZEB PARAM_VALUE.SIZEB } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SIZEB}] ${MODELPARAM_VALUE.SIZEB}
}

proc update_MODELPARAM_VALUE.ADDRWIDTHB { MODELPARAM_VALUE.ADDRWIDTHB PARAM_VALUE.ADDRWIDTHB } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDRWIDTHB}] ${MODELPARAM_VALUE.ADDRWIDTHB}
}

proc update_MODELPARAM_VALUE.WIDTHA { MODELPARAM_VALUE.WIDTHA PARAM_VALUE.WIDTHA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WIDTHA}] ${MODELPARAM_VALUE.WIDTHA}
}

proc update_MODELPARAM_VALUE.SIZEA { MODELPARAM_VALUE.SIZEA PARAM_VALUE.SIZEA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SIZEA}] ${MODELPARAM_VALUE.SIZEA}
}

proc update_MODELPARAM_VALUE.ADDRWIDTHA { MODELPARAM_VALUE.ADDRWIDTHA PARAM_VALUE.ADDRWIDTHA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDRWIDTHA}] ${MODELPARAM_VALUE.ADDRWIDTHA}
}

