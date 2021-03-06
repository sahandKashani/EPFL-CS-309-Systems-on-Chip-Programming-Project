# TCL File Generated by Component Editor 15.1
# Mon May 23 13:47:40 CEST 2016
# DO NOT MODIFY


# 
# vga_sequencer "vga_sequencer" v15.1
#  2016.05.23.13:47:40
# 
# 

# 
# request TCL package from ACDS 15.1
# 
package require -exact qsys 15.1


# 
# module vga_sequencer
# 
set_module_property DESCRIPTION ""
set_module_property NAME vga_sequencer
set_module_property VERSION 15.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME vga_sequencer
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL vga_sequencer
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file vga_sequencer.vhd VHDL PATH vga_sequencer.vhd TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter HBP_DEFAULT POSITIVE 12
set_parameter_property HBP_DEFAULT DEFAULT_VALUE 12
set_parameter_property HBP_DEFAULT DISPLAY_NAME HBP_DEFAULT
set_parameter_property HBP_DEFAULT TYPE POSITIVE
set_parameter_property HBP_DEFAULT UNITS None
set_parameter_property HBP_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property HBP_DEFAULT HDL_PARAMETER true
add_parameter HFP_DEFAULT POSITIVE 18
set_parameter_property HFP_DEFAULT DEFAULT_VALUE 18
set_parameter_property HFP_DEFAULT DISPLAY_NAME HFP_DEFAULT
set_parameter_property HFP_DEFAULT TYPE POSITIVE
set_parameter_property HFP_DEFAULT UNITS None
set_parameter_property HFP_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property HFP_DEFAULT HDL_PARAMETER true
add_parameter VBP_DEFAULT POSITIVE 8
set_parameter_property VBP_DEFAULT DEFAULT_VALUE 8
set_parameter_property VBP_DEFAULT DISPLAY_NAME VBP_DEFAULT
set_parameter_property VBP_DEFAULT TYPE POSITIVE
set_parameter_property VBP_DEFAULT UNITS None
set_parameter_property VBP_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property VBP_DEFAULT HDL_PARAMETER true
add_parameter VFP_DEFAULT POSITIVE 20
set_parameter_property VFP_DEFAULT DEFAULT_VALUE 20
set_parameter_property VFP_DEFAULT DISPLAY_NAME VFP_DEFAULT
set_parameter_property VFP_DEFAULT TYPE POSITIVE
set_parameter_property VFP_DEFAULT UNITS None
set_parameter_property VFP_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property VFP_DEFAULT HDL_PARAMETER true
add_parameter HDATA_DEFAULT POSITIVE 240
set_parameter_property HDATA_DEFAULT DEFAULT_VALUE 240
set_parameter_property HDATA_DEFAULT DISPLAY_NAME HDATA_DEFAULT
set_parameter_property HDATA_DEFAULT TYPE POSITIVE
set_parameter_property HDATA_DEFAULT UNITS None
set_parameter_property HDATA_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property HDATA_DEFAULT HDL_PARAMETER true
add_parameter VDATA_DEFAULT POSITIVE 320
set_parameter_property VDATA_DEFAULT DEFAULT_VALUE 320
set_parameter_property VDATA_DEFAULT DISPLAY_NAME VDATA_DEFAULT
set_parameter_property VDATA_DEFAULT TYPE POSITIVE
set_parameter_property VDATA_DEFAULT UNITS None
set_parameter_property VDATA_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property VDATA_DEFAULT HDL_PARAMETER true
add_parameter HSYNC_DEFAULT POSITIVE 2
set_parameter_property HSYNC_DEFAULT DEFAULT_VALUE 2
set_parameter_property HSYNC_DEFAULT DISPLAY_NAME HSYNC_DEFAULT
set_parameter_property HSYNC_DEFAULT TYPE POSITIVE
set_parameter_property HSYNC_DEFAULT UNITS None
set_parameter_property HSYNC_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property HSYNC_DEFAULT HDL_PARAMETER true
add_parameter VSYNC_DEFAULT POSITIVE 7
set_parameter_property VSYNC_DEFAULT DEFAULT_VALUE 7
set_parameter_property VSYNC_DEFAULT DISPLAY_NAME VSYNC_DEFAULT
set_parameter_property VSYNC_DEFAULT TYPE POSITIVE
set_parameter_property VSYNC_DEFAULT UNITS None
set_parameter_property VSYNC_DEFAULT ALLOWED_RANGES 1:2147483647
set_parameter_property VSYNC_DEFAULT HDL_PARAMETER true


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

add_interface_port clock clk clk Input 1


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
# connection point csr
# 
add_interface csr avalon end
set_interface_property csr addressUnits WORDS
set_interface_property csr associatedClock clock
set_interface_property csr associatedReset reset
set_interface_property csr bitsPerSymbol 8
set_interface_property csr burstOnBurstBoundariesOnly false
set_interface_property csr burstcountUnits WORDS
set_interface_property csr explicitAddressSpan 0
set_interface_property csr holdTime 0
set_interface_property csr linewrapBursts false
set_interface_property csr maximumPendingReadTransactions 0
set_interface_property csr maximumPendingWriteTransactions 0
set_interface_property csr readLatency 0
set_interface_property csr readWaitTime 1
set_interface_property csr setupTime 0
set_interface_property csr timingUnits Cycles
set_interface_property csr writeWaitTime 0
set_interface_property csr ENABLED true
set_interface_property csr EXPORT_OF ""
set_interface_property csr PORT_NAME_MAP ""
set_interface_property csr CMSIS_SVD_VARIABLES ""
set_interface_property csr SVD_ADDRESS_GROUP ""

add_interface_port csr address address Input 5
add_interface_port csr read read Input 1
add_interface_port csr write write Input 1
add_interface_port csr readdata readdata Output 32
add_interface_port csr writedata writedata Input 32
set_interface_assignment csr embeddedsw.configuration.isFlash 0
set_interface_assignment csr embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment csr embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment csr embeddedsw.configuration.isPrintableDevice 0


# 
# connection point out
# 
add_interface out conduit end
set_interface_property out associatedClock clock
set_interface_property out associatedReset ""
set_interface_property out ENABLED true
set_interface_property out EXPORT_OF ""
set_interface_property out PORT_NAME_MAP ""
set_interface_property out CMSIS_SVD_VARIABLES ""
set_interface_property out SVD_ADDRESS_GROUP ""

add_interface_port out hsync hsync Output 1
add_interface_port out g g Output 8
add_interface_port out b b Output 8
add_interface_port out de de Output 1
add_interface_port out vsync vsync Output 1
add_interface_port out r r Output 8


# 
# connection point in
# 
add_interface in avalon_streaming end
set_interface_property in associatedClock pixclk
set_interface_property in associatedReset reset
set_interface_property in dataBitsPerSymbol 24
set_interface_property in errorDescriptor ""
set_interface_property in firstSymbolInHighOrderBits true
set_interface_property in maxChannel 0
set_interface_property in readyLatency 0
set_interface_property in ENABLED true
set_interface_property in EXPORT_OF ""
set_interface_property in PORT_NAME_MAP ""
set_interface_property in CMSIS_SVD_VARIABLES ""
set_interface_property in SVD_ADDRESS_GROUP ""

add_interface_port in sink_ready ready Output 1
add_interface_port in sink_valid valid Input 1
add_interface_port in sink_data data Input 24


# 
# connection point pixclk
# 
add_interface pixclk clock end
set_interface_property pixclk clockRate 0
set_interface_property pixclk ENABLED true
set_interface_property pixclk EXPORT_OF ""
set_interface_property pixclk PORT_NAME_MAP ""
set_interface_property pixclk CMSIS_SVD_VARIABLES ""
set_interface_property pixclk SVD_ADDRESS_GROUP ""

add_interface_port pixclk pixclk clk Input 1


# 
# connection point frame_sync
# 
add_interface frame_sync conduit end
set_interface_property frame_sync associatedClock clock
set_interface_property frame_sync associatedReset ""
set_interface_property frame_sync ENABLED true
set_interface_property frame_sync EXPORT_OF ""
set_interface_property frame_sync PORT_NAME_MAP ""
set_interface_property frame_sync CMSIS_SVD_VARIABLES ""
set_interface_property frame_sync SVD_ADDRESS_GROUP ""

add_interface_port frame_sync frame_sync frame_sync Output 1

