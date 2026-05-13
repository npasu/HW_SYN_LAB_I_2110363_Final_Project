module filter_engine (
    input  wire [4:0] pixel_in,     // input RGB221
    input  wire [3:0] sw,           // Switches for filter
    output reg  [11:0] pixel_out    // output RGB444
);

    wire [1:0] r2 = pixel_in[4:3];
    wire [1:0] g2 = pixel_in[2:1];
    wire b1 = pixel_in[0];

    wire [3:0] r4 = {2{r2}};
    wire [3:0] g4 = {2{g2}};
    wire [3:0] b4 = {4{b1}};

    wire [7:0] gray_sum = (r4 * 3) + (g4 * 6) + b4 + 5;
    wire [3:0] gray = gray_sum / 10;

    wire [1:0] r_invt = 3 - r2;
    wire [1:0] g_invt = 3 - g2;
    wire b_invt = !b1;

    always @(*) begin
        case (sw)
            4'b0000 : pixel_out = {r4, g4, b4};                             // Normal
            4'b0001 : pixel_out = {gray, gray, gray};                       // Grayscale
            4'b0010 : pixel_out = {4'b0000, 4'b0000, b4};                   // Blue Only
            4'b0100 : pixel_out = {4'b0000, g4, 4'b0000};                   // Green Only
            4'b1000 : pixel_out = {r4, 4'b0000, 4'b0000};                   // Red only
            4'b1111 : pixel_out = {{2{r_invt}}, {2{g_invt}}, {4{b_invt}}};  // Invertion
            default : pixel_out = {r4, g4, b4};
        endcase
    end
endmodule
