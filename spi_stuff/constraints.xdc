## This file is a general .xdc for the ARTY Rev. A
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


# Clock signal

set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {sys_clock}];


# IDK
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]


# SPI pins
set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports { spi_miso }]; #IO_L17N_T2_35 Sch=ck_miso
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { spi_mosi }]; #IO_L17P_T2_35 Sch=ck_mosi
set_property -dict { PACKAGE_PIN F1    IOSTANDARD LVCMOS33 } [get_ports { spi_sck }]; #IO_L18P_T2_35 Sch=ck_sck
set_property -dict { PACKAGE_PIN C1    IOSTANDARD LVCMOS33 } [get_ports { spi_cs }]; #IO_L16N_T2_35 Sch=ck_ss

# This is bad practice, and probably not needed on final board
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets spi_sck_IBUF]