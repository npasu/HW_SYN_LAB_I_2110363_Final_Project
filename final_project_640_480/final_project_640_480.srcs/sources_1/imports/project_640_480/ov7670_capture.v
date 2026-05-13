module ov7670_capture (
    input  wire        pclk,
    input  wire        rst,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,

    output reg         we,
    output reg  [18:0] addr,
    output reg  [4:0]  dout,
    output reg         frame_done
);

    reg [7:0] d_latched;    // Temperary register for first byte data
    reg byte_idx;           // byte index for clarify current data's byte
    reg [9:0] cam_x = 0;    // Horizontal coordinates of the current address
    reg [9:0] cam_y = 0;    // Vertical coordinates of the current address

    always @( posedge pclk ) begin
        if (rst) begin
            we <= 1'b0;
            cam_x <= 0;
            cam_y <= 0;
            dout <= 12'd0;
            frame_done <= 1'b0;
            byte_idx <= 1'b0;
        end else begin
            we <= 1'b0;

            // Reset coordinates at the start of a new frame
            if (vsync) begin
                byte_idx <= 0; cam_x <= 0; cam_y <= 0; we <= 1'b0;
            end else if (href) begin
                // HREF is high when a valid row of pixels is being sent

                // First byte : store the value and wait for second byte
                if (!byte_idx) begin
                    d_latched <= d;
                    we <= 1'b0;
                end else begin
                    // Second byte : combine into the first byte to be 5 bits (RGB221)
                    addr <= (cam_y * 19'd640) + cam_x; // Calculate memory address
                    dout <= {d_latched[7:6], d_latched[2:1], d[4]}; // RRXXXGGX XXXBXXXX
                    we <= 1'b1; // write enable to BRAM
                    cam_x <= cam_x + 1;
                end
                byte_idx <= !byte_idx; // Toggle byte counter
            end else begin
                byte_idx <= 0; we <= 1'b0;
                if (cam_x > 0) begin // End 1 horizontal line
                    cam_x <= 0;
                    cam_y <= cam_y + 1;
                end
            end
        end
    end
endmodule
