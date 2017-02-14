# TCL File Generated by Component Editor 16.0
# Mon Feb 13 13:12:50 CET 2017
# DO NOT MODIFY


# 
# ws2812 "ws2812" v16.0
#  2017.02.13.13:12:50
# Make LEDs blink ! 
# 

# 
# request TCL package from ACDS 16.0
# 
package require -exact qsys 16.0


# 
# module ws2812
# 
set_module_property DESCRIPTION "Make LEDs blink ! "
set_module_property NAME ws2812
set_module_property VERSION 16.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR "Florian Depraz"
set_module_property DISPLAY_NAME ws2812
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ws2812
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ws2812.vhd VHDL PATH ws2812.vhd TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter NUMBER_LEDS INTEGER 1 ""
set_parameter_property NUMBER_LEDS DEFAULT_VALUE 1
set_parameter_property NUMBER_LEDS DISPLAY_NAME NUMBER_LEDS
set_parameter_property NUMBER_LEDS TYPE INTEGER
set_parameter_property NUMBER_LEDS UNITS None
set_parameter_property NUMBER_LEDS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property NUMBER_LEDS DESCRIPTION ""
set_parameter_property NUMBER_LEDS HDL_PARAMETER true
add_parameter LUMINOSITY POSITIVE 2
set_parameter_property LUMINOSITY DEFAULT_VALUE 2
set_parameter_property LUMINOSITY DISPLAY_NAME LUMINOSITY
set_parameter_property LUMINOSITY TYPE POSITIVE
set_parameter_property LUMINOSITY UNITS None
set_parameter_property LUMINOSITY HDL_PARAMETER true
add_parameter ADDR_WIDTH POSITIVE 1
set_parameter_property ADDR_WIDTH DEFAULT_VALUE 1
set_parameter_property ADDR_WIDTH DISPLAY_NAME ADDR_WIDTH
set_parameter_property ADDR_WIDTH TYPE POSITIVE
set_parameter_property ADDR_WIDTH UNITS None
set_parameter_property ADDR_WIDTH ALLOWED_RANGES 1:2147483647
set_parameter_property ADDR_WIDTH HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 50000000
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink nReset reset_n Input 1


# 
# connection point as
# 
add_interface as avalon end
set_interface_property as addressUnits WORDS
set_interface_property as associatedClock clock
set_interface_property as associatedReset reset_sink
set_interface_property as bitsPerSymbol 8
set_interface_property as burstOnBurstBoundariesOnly false
set_interface_property as burstcountUnits WORDS
set_interface_property as explicitAddressSpan 0
set_interface_property as holdTime 0
set_interface_property as linewrapBursts false
set_interface_property as maximumPendingReadTransactions 0
set_interface_property as maximumPendingWriteTransactions 0
set_interface_property as readLatency 0
set_interface_property as readWaitTime 1
set_interface_property as setupTime 0
set_interface_property as timingUnits Cycles
set_interface_property as writeWaitTime 0
set_interface_property as ENABLED true
set_interface_property as EXPORT_OF ""
set_interface_property as PORT_NAME_MAP ""
set_interface_property as CMSIS_SVD_VARIABLES ""
set_interface_property as SVD_ADDRESS_GROUP ""

add_interface_port as as_addr address Input addr_width
add_interface_port as as_wrdata writedata Input 32
add_interface_port as as_rddata readdata Output 32
add_interface_port as as_write write Input 1
add_interface_port as as_read read Input 1
set_interface_assignment as embeddedsw.configuration.isFlash 0
set_interface_assignment as embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment as embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment as embeddedsw.configuration.isPrintableDevice 0


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end LED_BGR name Output 1

