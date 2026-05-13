module display_scaler (
    input  wire        clk,
    input  wire        rst,

    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire        active,

    input  wire [11:0] rd_data,
    output reg  [16:0] rd_addr,

    input  wire [3:0]  sw,

    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    wire [8:0] fb_x;
    wire [7:0] fb_y;
    assign fb_x = hcount[9:1];
    assign fb_y = vcount[8:1];

    wire [16:0] addr_next;
    assign addr_next = (fb_y * 17'd320) + fb_x;

    reg active_d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_addr  <= 17'd0;
            active_d <= 1'b0;

        end else begin
            if (active) rd_addr <= addr_next;
            active_d <= active;
        end
    end

    wire [11:0] pixel_display;

    filter_engine filter (
        .pixel_in(rd_data),
        .sw(sw),
        .pixel_out(pixel_display)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end else begin
            if (active_d) begin
                vga_r <= pixel_display[11:8];
                vga_g <= pixel_display[7:4];
                vga_b <= pixel_display[3:0];
            end else begin
                vga_r <= 4'd0;
                vga_g <= 4'd0;
                vga_b <= 4'd0;
            end
        end
    end

endmodule
