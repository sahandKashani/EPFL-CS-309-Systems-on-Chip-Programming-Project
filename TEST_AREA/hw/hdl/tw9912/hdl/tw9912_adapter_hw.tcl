# TCL File Generated by Component Editor 15.1
# Sun Jun 05 15:52:15 CEST 2016
# DO NOT MODIFY


# 
# tw9912_adapter "tw9912_adapter" v15.1
#  2016.06.05.15:52:15
# 
# 

# 
# request TCL package from ACDS 15.1
# 
package require -exact qsys 15.1


# 
# module tw9912_adapter
# 
set_module_property DESCRIPTION ""
set_module_property NAME tw9912_adapter
set_module_property VERSION 15.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME tw9912_adapter
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL tw9912_adapter
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file dc_pal_fifo.vhd VHDL PATH dc_pal_fifo.vhd
add_fileset_file tw9912_adapter.vhd VHDL PATH tw9912_adapter.vhd TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock sysclk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point out
# 
add_interface out avalon_streaming start
set_interface_property out associatedClock clock
set_interface_property out associatedReset reset
set_interface_property out dataBitsPerSymbol 8
set_interface_property out errorDescriptor ""
set_interface_property out firstSymbolInHighOrderBits true
set_interface_property out maxChannel 0
set_interface_property out readyLatency 0
set_interface_property out ENABLED true
set_interface_property out EXPORT_OF ""
set_interface_property out PORT_NAME_MAP ""
set_interface_property out CMSIS_SVD_VARIABLES ""
set_interface_property out SVD_ADDRESS_GROUP ""

add_interface_port out asrc_data data Output 32
add_interface_port out asrc_valid valid Output 1
add_interface_port out asrc_ready ready Input 1


# 
# connection point s1
# 
add_interface s1 avalon end
set_interface_property s1 addressUnits WORDS
set_interface_property s1 associatedClock clock
set_interface_property s1 associatedReset reset
set_interface_property s1 bitsPerSymbol 8
set_interface_property s1 burstOnBurstBoundariesOnly false
set_interface_property s1 burstcountUnits WORDS
set_interface_property s1 explicitAddressSpan 0
set_interface_property s1 holdTime 0
set_interface_property s1 linewrapBursts false
set_interface_property s1 maximumPendingReadTransactions 0
set_interface_property s1 maximumPendingWriteTransactions 0
set_interface_property s1 readLatency 0
set_interface_property s1 readWaitTime 1
set_interface_property s1 setupTime 0
set_interface_property s1 timingUnits Cycles
set_interface_property s1 writeWaitTime 0
set_interface_property s1 ENABLED true
set_interface_property s1 EXPORT_OF ""
set_interface_property s1 PORT_NAME_MAP ""
set_interface_property s1 CMSIS_SVD_VARIABLES ""
set_interface_property s1 SVD_ADDRESS_GROUP ""

add_interface_port s1 avs_address address Input 3
add_interface_port s1 avs_write write Input 1
add_interface_port s1 avs_read read Input 1
add_interface_port s1 avs_writedata writedata Input 32
add_interface_port s1 avs_readdata readdata Output 32
set_interface_assignment s1 embeddedsw.configuration.isFlash 0
set_interface_assignment s1 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s1 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s1 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point pal_in
# 
add_interface pal_in conduit end
set_interface_property pal_in associatedClock ""
set_interface_property pal_in associatedReset ""
set_interface_property pal_in ENABLED true
set_interface_property pal_in EXPORT_OF ""
set_interface_property pal_in PORT_NAME_MAP ""
set_interface_property pal_in CMSIS_SVD_VARIABLES ""
set_interface_property pal_in SVD_ADDRESS_GROUP ""

add_interface_port pal_in pal_vsync vso Input 1
add_interface_port pal_in pal_hsync hso Input 1
add_interface_port pal_in pal_vd vd Input 8
add_interface_port pal_in pal_clk clko Input 1


# 
# connection point debug
# 
add_interface debug conduit end
set_interface_property debug associatedClock clock
set_interface_property debug associatedReset ""
set_interface_property debug ENABLED true
set_interface_property debug EXPORT_OF ""
set_interface_property debug PORT_NAME_MAP ""
set_interface_property debug CMSIS_SVD_VARIABLES ""
set_interface_property debug SVD_ADDRESS_GROUP ""

add_interface_port debug debug_capturing capturing Output 1

