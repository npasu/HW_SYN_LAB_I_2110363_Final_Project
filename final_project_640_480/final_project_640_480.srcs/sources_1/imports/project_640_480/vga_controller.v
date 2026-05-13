module vga_controller (
    input  wire       clk,
    input  wire       rst,
    output reg  [9:0] hcount,
    output reg  [9:0] vcount,
    output wire       hsync,
    output wire       vsync,
    output wire       active
);

    reg reg_hsync;
    reg reg_vsync;
    reg reg_active;

    assign hsync = reg_hsync;
    assign vsync = reg_vsync;
    assign active = reg_active;

    always @( posedge clk ) begin
        if (rst) begin
            hcount <= 10'd0;
            vcount <= 10'd0;
        end else begin
            // Horizontal Counter: 0 to 799 (includes sync and blanking)
            if (hcount == 10'd799) begin
                hcount <= 10'd0;

                // Vertical Counter: 0 to 524
                if (vcount == 10'd524) vcount <= 10'd0;
                else vcount <= vcount + 10'd1;
            end else hcount <= hcount + 10'd1;

            // Generate HSync/VSync pulses based on industry standards
            reg_hsync <= (hcount < 10'd656) || (hcount >= 10'd752);
            reg_vsync <= (vcount < 10'd490) || (vcount >= 10'd492);

            // Determine if we are in the "Active" visible area
            reg_active <= (hcount < 10'd640) && (vcount < 10'd480);
        end
    end

endmodule
