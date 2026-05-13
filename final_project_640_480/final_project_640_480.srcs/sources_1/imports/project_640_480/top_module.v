module top_module (
    input wire          clk,         // Main 100 MHz board clock
    input wire          btnC,        // Reset Button
    output wire         init_ready,  // LED : high when SCCB config is finished
    input wire [3:0]    sw,          // Filter Switches

    // Camera Hardware Interface
    input wire          PCLK,
    input wire          cam_vsync,
    input wire          HREF,
    input wire [7:0]    cam_data,
    output wire         XCLK,
    output wire         RST,
    output wire         PWDN,
    output wire         SCL,
    inout wire          SDA,

    // VGA Hardware Interface
    output wire         hsync,
    output wire         vsync,
    output wire [3:0]   vga_r,
    output wire [3:0]   vga_g,
    output wire [3:0]   vga_b
);

    wire        cam_clk;        // Clock for camera : 24 MHz
    wire        vga_clk;        // clock for VGA : 25.175 MHz
    wire        reset = btnC;
    wire        init_ready;

    // Clock generation : Create specific speeds for Camera and VGA
    clk_wiz_0 clock_gen (
        .clk(clk),
        .cam_clk(cam_clk),
        .vga_clk(vga_clk)
    );

    assign XCLK = cam_clk;      // Drive camera master clock
    assign RST  = 1'b1;
    assign PWDN = 1'b0;

    // Camera Configuration : Sends register settings via SCCB
    sccb_master sccb (
        .clk(clk),
        .rst(reset),
        .init_ready(init_ready),
        .sio_c(SCL),
        .sio_d(SDA)
    );

    wire [18:0] write_addr;     // 19 bits for 307200 addresses
    wire [4:0] capture_data;    // 5 bits for RGB221
    wire we;                    // write enable for BRAM

    // Capture unit : Converts raw camera bytes into 12-bits RGB pixels
    ov7670_capture capture_unit (
        .pclk(PCLK),
        .rst(reset),
        .vsync(cam_vsync),
        .href(HREF),
        .d(cam_data),
        .we(we),
        .addr(write_addr),
        .dout(capture_data)
    );

    wire [18:0] read_addr;      // 19 bits for 307200 addresses
    wire [4:0] bram_data;       // 5 bits for RGB221

    // Frame Buffer : True Dual-port memory to store one frame of video
    // Port A : Camera Writes | Port B : VGA Reads
    blk_mem_gen_0 fb (
        .clka(PCLK),
        .wea(we),
        .addra(write_addr),
        .dina(capture_data),
        .ena(1'b1),

        .clkb(vga_clk),
        .addrb(read_addr),
        .doutb(bram_data),
        .web  (1'b0)
    );

    // VGA Control & Filter : Generates sync signals and applies filters
    wire [9:0] hcount;
    wire [9:0] vcount;
    wire video_active;

    vga_controller vga_timing (
        .clk(vga_clk),
        .rst(reset),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .active(video_active)
    );

    display_scaler display_unit (
        .clk(vga_clk),
        .rst(reset),
        .hcount(hcount),
        .vcount(vcount),
        .active(video_active),
        .rd_data(bram_data),
        .rd_addr(read_addr),
        .sw(sw),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

endmodule
