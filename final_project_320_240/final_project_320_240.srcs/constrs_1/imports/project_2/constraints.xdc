# Main System Clock (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.00 [get_ports clk]

# VGA Sync Signals
set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]

# VGA Red Channel (4-bit)
set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]

# VGA Green Channel (4-bit)
set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]

# VGA Blue Channel (4-bit)
set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]

# Camera Pixel Clock (PCLK) Routing - Ignore standard clock buffer rules for this net
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]

# Camera Parallel Data Bus (D0–D7)
set_property PACKAGE_PIN P17 [get_ports {cam_data[0]}]
set_property PACKAGE_PIN N17 [get_ports {cam_data[1]}]
set_property PACKAGE_PIN M19 [get_ports {cam_data[2]}]
set_property PACKAGE_PIN M18 [get_ports {cam_data[3]}]
set_property PACKAGE_PIN L17 [get_ports {cam_data[4]}]
set_property PACKAGE_PIN K17 [get_ports {cam_data[5]}]
set_property PACKAGE_PIN C16 [get_ports {cam_data[6]}]
set_property PACKAGE_PIN B16 [get_ports {cam_data[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[7]}]

# Camera Control Signals (HREF, VSYNC, PCLK, XCLK)
set_property PACKAGE_PIN A17 [get_ports HREF]
set_property PACKAGE_PIN B15 [get_ports cam_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports HREF]
set_property IOSTANDARD LVCMOS33 [get_ports cam_vsync]

set_property PACKAGE_PIN A16 [get_ports PCLK]
set_property IOSTANDARD LVCMOS33 [get_ports PCLK]

set_property PACKAGE_PIN C15 [get_ports XCLK]
set_property IOSTANDARD LVCMOS33 [get_ports XCLK]

# SCCB (I2C-compatible) Interface Signals - PULLUPs added to stabilize floating signals
set_property PACKAGE_PIN A14 [get_ports SCL]
set_property IOSTANDARD LVCMOS33 [get_ports SCL]
set_property PULLUP TRUE [get_ports SCL]

set_property PACKAGE_PIN A15 [get_ports SDA]
set_property IOSTANDARD LVCMOS33 [get_ports SDA]
set_property PULLUP TRUE [get_ports SDA]

# Camera Power and Hardware Reset Signals
set_property PACKAGE_PIN R18 [get_ports PWDN]
set_property PACKAGE_PIN P18 [get_ports RST]
set_property IOSTANDARD LVCMOS33 [get_ports PWDN]
set_property IOSTANDARD LVCMOS33 [get_ports RST]

# User Interface Buttons and LEDs
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

set_property PACKAGE_PIN U16 [get_ports init_ready]
set_property IOSTANDARD LVCMOS33 [get_ports init_ready]

# Filter Selection Switches (sw[0] to sw[3])
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
