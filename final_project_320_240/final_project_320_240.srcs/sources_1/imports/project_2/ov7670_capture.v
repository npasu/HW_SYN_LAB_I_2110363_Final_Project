module ov7670_capture (
    input  wire        pclk,
    input  wire        rst,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,

    output reg         we,
    output reg  [16:0] addr,
    output reg  [11:0] dout,
    output reg         frame_done
);

    reg [7:0] d_latched;    // Temperary register for first byte data
    reg byte_idx;           // byte index for clarify current data's byte
    reg [9:0] cam_x;        // Horizontal coordinates of the current address
    reg [8:0] cam_y;        // Vertical coordinates of the current address

    always @( posedge pclk ) begin
        if (rst) begin
            we         <= 1'b0;
            addr       <= 17'd0;
            dout       <= 12'd0;
            frame_done <= 1'b0;
            byte_idx   <= 1'b0;
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
                // Second byte : combine into the first byte to be 12 bits (RGB444)
                    // Only store into the BRAM on x and y is odd (to downsampling from 640 * 480 to 320 * 240 pixels per frame)
                    if (!cam_x[0] && !cam_y[0]) begin
                        addr <= ((cam_y >> 1) * 17'd320) + (cam_x >> 1); // Calculate memory address
                        dout <= {d_latched[7:4], d_latched[2:0], d[7], d[4:1]}; // RRRRXGGG GXXBBBBX
                        we <= 1'b1; // write enable to BRAM
                    end else we <= 1'b0;
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
