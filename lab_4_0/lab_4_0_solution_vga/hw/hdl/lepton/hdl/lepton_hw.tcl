# TCL File Generated by Component Editor 16.0
# Sun Feb 05 19:05:24 CET 2017
# DO NOT MODIFY


#
# lepton "lepton" v1.0
# Philemon Favrod & Sahand Kashani-Akhavan 2017.02.05.19:05:24
# IR Camera 80x60
#

#
# request TCL package from ACDS 16.0
#
package require -exact qsys 16.0


#
# module lepton
#
set_module_property DESCRIPTION "IR Camera 80x60"
set_module_property NAME lepton
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Camera
set_module_property AUTHOR "Philemon Favrod & Sahand Kashani-Akhavan"
set_module_property DISPLAY_NAME lepton
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL lepton
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file avalon_st_spi_master.vhd VHDL PATH avalon_st_spi_master.vhd
add_fileset_file byte2pix.vhd VHDL PATH byte2pix.vhd
add_fileset_file dual_ported_ram.vhd VHDL PATH dual_ported_ram.vhd
add_fileset_file lepton.vhd VHDL PATH lepton.vhd TOP_LEVEL_FILE
add_fileset_file lepton_manager.vhd VHDL PATH lepton_manager.vhd
add_fileset_file lepton_stats.vhd VHDL PATH lepton_stats.vhd
add_fileset_file ram_writer.vhd VHDL PATH ram_writer.vhd
add_fileset_file utils.vhd VHDL PATH utils.vhd
add_fileset_file level_adjuster.vhd VHDL PATH level_adjuster.vhd
add_fileset_file lpm_divider.vhd VHDL PATH lpm_divider.vhd


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
# connection point avalon_slave_0
#
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitStates 9
set_interface_property avalon_slave_0 readWaitTime 9
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 address address Input 14
add_interface_port avalon_slave_0 readdata readdata Output 16
add_interface_port avalon_slave_0 writedata writedata Input 16
add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 write write Input 1
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


#
# connection point spi
#
add_interface spi conduit end
set_interface_property spi associatedClock clock
set_interface_property spi associatedReset ""
set_interface_property spi ENABLED true
set_interface_property spi EXPORT_OF ""
set_interface_property spi PORT_NAME_MAP ""
set_interface_property spi CMSIS_SVD_VARIABLES ""
set_interface_property spi SVD_ADDRESS_GROUP ""

add_interface_port spi CSn cs_n Output 1
add_interface_port spi MISO miso Input 1
add_interface_port spi MOSI mosi Output 1
add_interface_port spi SCLK sclk Output 1
