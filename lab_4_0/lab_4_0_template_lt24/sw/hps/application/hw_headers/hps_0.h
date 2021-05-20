#ifndef _ALTERA_HPS_0_H_
#define _ALTERA_HPS_0_H_

/*
 * This file was automatically generated by the swinfo2header utility.
 * 
 * Created from SOPC Builder system 'soc_system' in
 * file 'hw/quartus/soc_system.sopcinfo'.
 */

/*
 * This file contains macros for module 'hps_0' and devices
 * connected to the following master:
 *   h2f_lw_axi_master
 * 
 * Do not include this header file and another header file created for a
 * different module or master group at the same time.
 * Doing so may result in duplicate macro names.
 * Instead, use the system header file which has macros with unique names.
 */

/*
 * Macros for device 'lt24_sequencer_0', class 'lt24_sequencer'
 * The macros are prefixed with 'LT24_SEQUENCER_0_'.
 * The prefix is the slave descriptor.
 */
#define LT24_SEQUENCER_0_COMPONENT_TYPE lt24_sequencer
#define LT24_SEQUENCER_0_COMPONENT_NAME lt24_sequencer_0
#define LT24_SEQUENCER_0_BASE 0x0
#define LT24_SEQUENCER_0_SPAN 16
#define LT24_SEQUENCER_0_END 0xf

/*
 * Macros for device 'framebuffer_manager_0', class 'framebuffer_manager'
 * The macros are prefixed with 'FRAMEBUFFER_MANAGER_0_'.
 * The prefix is the slave descriptor.
 */
#define FRAMEBUFFER_MANAGER_0_COMPONENT_TYPE framebuffer_manager
#define FRAMEBUFFER_MANAGER_0_COMPONENT_NAME framebuffer_manager_0
#define FRAMEBUFFER_MANAGER_0_BASE 0x80
#define FRAMEBUFFER_MANAGER_0_SPAN 64
#define FRAMEBUFFER_MANAGER_0_END 0xbf

/*
 * Macros for device 'pwm_0', class 'pwm'
 * The macros are prefixed with 'PWM_0_'.
 * The prefix is the slave descriptor.
 */
#define PWM_0_COMPONENT_TYPE pwm
#define PWM_0_COMPONENT_NAME pwm_0
#define PWM_0_BASE 0xc0
#define PWM_0_SPAN 16
#define PWM_0_END 0xcf

/*
 * Macros for device 'pwm_1', class 'pwm'
 * The macros are prefixed with 'PWM_1_'.
 * The prefix is the slave descriptor.
 */
#define PWM_1_COMPONENT_TYPE pwm
#define PWM_1_COMPONENT_NAME pwm_1
#define PWM_1_BASE 0xd0
#define PWM_1_SPAN 16
#define PWM_1_END 0xdf

/*
 * Macros for device 'mcp3204_0', class 'mcp3204'
 * The macros are prefixed with 'MCP3204_0_'.
 * The prefix is the slave descriptor.
 */
#define MCP3204_0_COMPONENT_TYPE mcp3204
#define MCP3204_0_COMPONENT_NAME mcp3204_0
#define MCP3204_0_BASE 0xe0
#define MCP3204_0_SPAN 16
#define MCP3204_0_END 0xef

/*
 * Macros for device 'lepton_0', class 'lepton'
 * The macros are prefixed with 'LEPTON_0_'.
 * The prefix is the slave descriptor.
 */
#define LEPTON_0_COMPONENT_TYPE lepton
#define LEPTON_0_COMPONENT_NAME lepton_0
#define LEPTON_0_BASE 0x8000
#define LEPTON_0_SPAN 32768
#define LEPTON_0_END 0xffff


#endif /* _ALTERA_HPS_0_H_ */
