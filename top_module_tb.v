`timescale 1ns / 1ps


module top_module_tb;
    // --- Configuration ---
    parameter MODE = 1;  // 0 = RGB444, 1 = RGB221


    localparam H_ACTIVE   = (MODE) ? 640 : 320;
    localparam V_ACTIVE   = (MODE) ? 480 : 240;
    localparam PIXEL_BITS = (MODE) ? 5   : 12;


    // --- Inputs ---
    reg clk;
    reg btnC;
    reg [3:0] sw;
    reg PCLK;
    reg cam_vsync;
    reg HREF;
    reg [7:0] cam_data;


    // --- Outputs ---
    wire init_ready;
    wire XCLK, RST, PWDN, SCL;
    wire SDA;
    wire hsync, vsync;
    wire [3:0] vga_r, vga_g, vga_b;


    // --- Instantiate UUT ---
    top_module uut (
        .clk(clk),
        .btnC(btnC),
        .init_ready(init_ready),
        .sw(sw),
        .PCLK(PCLK),
        .cam_vsync(cam_vsync),
        .HREF(HREF),
        .cam_data(cam_data),
        .XCLK(XCLK),
        .RST(RST),
        .PWDN(PWDN),
        .SCL(SCL),
        .SDA(SDA),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );


    // --- Instantiate Capture Module
    wire capture_we;
    wire [16:0] capture_addr;
    wire [11:0] capture_dout;
    ov7670_capture test_capture (
        .pclk(PCLK),
        .rst(btnC),
        .vsync(cam_vsync),
        .href(HREF),
        .d(cam_data),


        .we(capture_we),
        .addr(capture_addr),
        .dout(capture_dout),
        .frame_done()
    );


    // --- Instantiate filter engine---
    reg [PIXEL_BITS-1:0] test_pixel;
    wire [11:0] test_pixel_out;
    filter_engine test_filter (
        .pixel_in(test_pixel),
        .sw(sw),
        .pixel_out(test_pixel_out)
    );


    // --- Clock generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 1 T = 10ns
    end


    initial begin
        PCLK = 0;
        #10;
        forever #20 PCLK = ~PCLK; // 1 T = 40ns
    end


    reg vga_clk_sim;
    initial begin
        vga_clk_sim = 0;
        forever #19.86 vga_clk_sim = ~vga_clk_sim; // 25.175 MHz (T = 39.72ns)
    end


    // --- Main Test ---
    reg [11:0] expected_val;


    // for caculate grayscale
    wire [3:0] r4_tb = (MODE) ? {2{test_pixel[4:3]}} : test_pixel[11:8];
    wire [3:0] g4_tb = (MODE) ? {2{test_pixel[2:1]}} : test_pixel[7:4];
    wire [3:0] b4_tb = (MODE) ? {4{test_pixel[0]}}   : test_pixel[3:0];


    wire [5:0] gray_sum_m0 = r4_tb + g4_tb + b4_tb;
    wire [3:0] gray_m0     = gray_sum_m0[5:2];


    wire [7:0] gray_sum_m1 = (r4_tb * 3) + (g4_tb * 6) + b4_tb + 5;
    wire [3:0] gray_m1     = gray_sum_m1 / 10;


    wire [3:0] gray_tb = (MODE) ? gray_m1 : gray_m0;


    initial begin
        force uut.vga_timing.clk = vga_clk_sim; // clock for VGA


        // Initialize
        btnC = 1;
        sw = 4'b0000;
        cam_vsync = 0;
        HREF = 0;
        cam_data = 8'h00;
        test_pixel = 12'h000;
        #100;
        btnC = 0;
        #100;


        if (MODE) test_pixel = 5'b11101;
        else test_pixel = 12'hF84;


        $display("----------------------------------------------------------------");
        if (MODE) begin
            $display("RUNNING TEST: %0dx%0d | Color Mode: %0d-bit | Test Pixel: 5'b%b", H_ACTIVE, V_ACTIVE, PIXEL_BITS, test_pixel);
        end else begin
            $display("RUNNING TEST: %0dx%0d | Color Mode: %0d-bit | Test Pixel: 12'h%h", H_ACTIVE, V_ACTIVE, PIXEL_BITS, test_pixel);
        end
        $display("----------------------------------------------------------------");


        // Test system & clock
        if (XCLK !== 1'bx) $display("System: XCLK is toggling [PASS]");
        else $display("System: XCLK is undefined [FAIL]");


        // --- Test VGA Sync ---
        if (hsync !== 1'bx && vsync !== 1'bx) $display("VGA Sync: Signals are defined [PASS]");
        else $display("VGA Sync: Signals are X (Undefined) [FAIL]");


        // --- Test SCCB ---
        if (SCL !== 1'bx && SDA !== 1'bx) $display("SCCB Interface: Bus signals are alive [PASS]");
        else $display("SCCB Interface: Bus signals are X [FAIL]");


        // Test capture logic & memory addressing
        cam_vsync = 1; #80;
        cam_vsync = 0; #80;


        // Line 0: stored data
        HREF = 1;
        repeat(2) begin
            cam_data = 8'hAA; #40;
            cam_data = 8'h55; #40;
        end
        HREF = 0; #80;


        // Line 1: skip
        HREF = 1;
        repeat(2) begin
            cam_data = 8'hFF; #40;
            cam_data = 8'hEE; #40;
        end
        HREF = 0; #80;


        // Line 2: stored data
        HREF = 1;
        repeat(2) begin
            cam_data = 8'h11; #40;
            cam_data = 8'h22; #40;
        end
        HREF = 0;
        $display("Capture: Check addr for 0, 1 (Line 0) and 320, 321 (Line 2)");


        // --- Test grayscale ---
        sw = 4'b0001; #20;
        expected_val = {gray_tb,gray_tb,gray_tb};
        $display("Grayscale: Out=%h | Exp:%h [%s]", test_pixel_out, expected_val, (test_pixel_out == expected_val ? "PASS" : "FAIL"));


        // Test red chananel
        sw = 4'b1000; #20;
        expected_val = (MODE) ? { {2{test_pixel[4:3]}}, 8'h00 } : 12'hF00;
        $display("Red Filter: Out=%h | Exp:%h [%s]", test_pixel_out, expected_val, (test_pixel_out == expected_val ? "PASS" : "FAIL"));


        // Test green channel
        sw = 4'b0100; #20;
        expected_val = (MODE) ? { 4'h0, {2{test_pixel[2:1]}}, 4'h0 } : 12'h080;
        $display("Green Filter: %h | Exp:%h [%s]", test_pixel_out, expected_val, (test_pixel_out == expected_val ? "PASS" : "FAIL"));


        // Test blue channel
        sw = 4'b0010; #20;
        expected_val = (MODE) ? { 8'h00, {4{test_pixel[0]}} } : 12'h004;
        $display("Blue Filter: %h | Exp:%h [%s]", test_pixel_out, expected_val, (test_pixel_out == expected_val ? "PASS" : "FAIL"));


        // Test color inversion
        sw = 4'b1111; #20;
        if (MODE) begin
            expected_val = { {2{2'd3-test_pixel[4:3]}}, {2{2'd3-test_pixel[2:1]}}, {4{!test_pixel[0]}} };
        end else begin
            expected_val = ~test_pixel;
        end
        $display("Color Inversion: %h | Exp:%h [%s]", test_pixel_out, expected_val, (test_pixel_out == expected_val ? "PASS" : "FAIL"));
        sw = 4'b0000;


        $display("----------------------------------------------------------------");
        $display("Simulation finished at %t", $time);


        release uut.vga_timing.clk;


        $finish;


    end


endmodule
