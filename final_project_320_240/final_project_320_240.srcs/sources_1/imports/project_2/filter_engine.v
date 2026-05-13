module filter_engine (
    input  wire [11:0] pixel_in, // input RGB444
    input  wire [3:0]  sw,       // Switches for filter
    output reg  [11:0] pixel_out // output RGB444
);

    wire [3:0] r4 = pixel_in[11:8];
    wire [3:0] g4 = pixel_in[7:4];
    wire [3:0] b4 = pixel_in[3:0];

    wire [5:0] y_sum = r4 + g4 + b4;
    wire [3:0] gray  = y_sum[5:2];

    wire [3:0] r_invt = 15 - r4;
    wire [3:0] g_invt = 15 - g4;
    wire [3:0] b_invt = 15 - b4;

    always @(*) begin
        case (sw)
            4'b0000 : pixel_out = pixel_in;                 // Normal
            4'b0001 : pixel_out = {gray, gray, gray};       // Grayscale
            4'b0010 : pixel_out = {4'b0000, 4'b0000, b4};   // Blue Only
            4'b0100 : pixel_out = {4'b0000, g4, 4'b0000};   // Green Only
            4'b1000 : pixel_out = {r4, 4'b0000, 4'b0000};   // Red only
            4'b1111 : pixel_out = {r_invt, g_invt, b_invt}; // Invertion
            default : pixel_out = pixel_in;
        endcase
    end
endmodule
