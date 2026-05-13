module sccb_master (
    input  wire clk,        // Main 100MHz clock
    input  wire rst,        // System reset

    output reg  sio_c,      // SCCB Clock signal
    output reg  sio_d,      // SCCB Data signal

    output reg  init_ready  // High when all registers are configured
);

    // Generates a 'tick' to slow down the 100MHz clock for SCCB timing
    reg [8:0] divcnt;
    reg tick;

    always @( posedge clk ) begin
        if (rst) begin
            divcnt <= 0;
            tick   <= 0;
        end else begin
            tick <= 0;

            // Divide clock to reach ~400kHz
            if (divcnt == 249) begin
                divcnt <= 0;
                tick   <= 1;
            end else divcnt <= divcnt + 1;
        end
    end

    // Stores 16-bit values: [8-bit Register Address, 8-bit Data Value]
    reg [15:0] rom_data;
    reg [7:0] rom_addr;

    always @(*) begin
        case (rom_addr)

            // 1. Soft Reset : Resets all camera registers to default
            0  : rom_data = 16'h1280;

            // 2. Clocking & PLL : Sets internal camera speeds
            1  : rom_data = 16'h1100;
            2  : rom_data = 16'h6B4A;
            3  : rom_data = 16'h3B0A;

            // 3. Format & Scaling : Sets output to RGB and specific resolutions
            4  : rom_data = 16'h1204;
            5  : rom_data = 16'h40D0;
            6  : rom_data = 16'h3A04;

            7  : rom_data = 16'h0C00;
            8  : rom_data = 16'h3E00;

            9  : rom_data = 16'h703A;
            10 : rom_data = 16'h7135;
            11 : rom_data = 16'h7211;
            12 : rom_data = 16'h73F1;
            13 : rom_data = 16'hA202;

            // 4. Windowing : Defines the visible area of the sensor
            14 : rom_data = 16'h1713;
            15 : rom_data = 16'h1801;
            16 : rom_data = 16'h32BF;

            17 : rom_data = 16'h1902;
            18 : rom_data = 16'h1A7A;
            19 : rom_data = 16'h030A;

            // 5. Color Matrix : Adjusts how colors are calculated
            20 : rom_data = 16'h4F8A;
            21 : rom_data = 16'h5075;
            22 : rom_data = 16'h5100;
            23 : rom_data = 16'h5215;
            24 : rom_data = 16'h539C;
            25 : rom_data = 16'h54D4;
            26 : rom_data = 16'h589E;

            // 6. AEC / AGC / AWB : Auto Exposure and White Balance settings
            27 : rom_data = 16'h13EF;
            28 : rom_data = 16'h0000;
            29 : rom_data = 16'h1000;
            30 : rom_data = 16'h0D40;

            31 : rom_data = 16'h1438;

            32 : rom_data = 16'h2495;
            33 : rom_data = 16'h2533;
            34 : rom_data = 16'h26E3;

            // 7. Gamma Curve : Adjusts brightness/contrast non-linearly
            35 : rom_data = 16'h7A20;
            36 : rom_data = 16'h7B10;
            37 : rom_data = 16'h7C1E;
            38 : rom_data = 16'h7D35;
            39 : rom_data = 16'h7E5A;
            40 : rom_data = 16'h7F69;
            41 : rom_data = 16'h8076;
            42 : rom_data = 16'h8180;
            43 : rom_data = 16'h8288;
            44 : rom_data = 16'h838F;
            45 : rom_data = 16'h8496;
            46 : rom_data = 16'h85A3;
            47 : rom_data = 16'h86AF;
            48 : rom_data = 16'h87C4;
            49 : rom_data = 16'h88D7;
            50 : rom_data = 16'h89E8;

            // 8. DSP & Denoise : Digital processing to clean up the image
            51 : rom_data = 16'h4108;
            52 : rom_data = 16'h76E1;
            53 : rom_data = 16'h330B;
            54 : rom_data = 16'h3C78;
            55 : rom_data = 16'h6900;
            56 : rom_data = 16'h7400;

            57 : rom_data = 16'hB084;
            58 : rom_data = 16'hB100;
            59 : rom_data = 16'hB20E;
            60 : rom_data = 16'hB382;

            // 9. Saturation & Contrast
            61 : rom_data = 16'h6780;
            62 : rom_data = 16'h6880;
            63 : rom_data = 16'h5640;

            // 10. Frame Stability
            64 : rom_data = 16'h1500;
            65 : rom_data = 16'h13EF;
            66 : rom_data = 16'h0E61;
            67 : rom_data = 16'h1600;
            68 : rom_data = 16'h1E07;

            // End of configuration marker
            default : rom_data = 16'hFFFF;
        endcase
    end

    localparam WAIT  = 0; // Wait between transmissions
    localparam IDLE  = 1; // Prepare to send next register
    localparam START = 2; // SCCB Start Condition (Data pulls low before Clock)
    localparam SEND  = 3; // Shift out 8 bits of data
    localparam ACK   = 4; // "Don't care" bit (acknowledge cycle)
    localparam STOP  = 5; // SCCB Stop Condition (Data pulls high after Clock)
    localparam NEXT  = 6; // Move to next ROM address
    localparam DONE  = 7; // Configuration finished

    reg [2:0] state;

    reg [1:0] phase;
    reg [2:0] bit_index;
    reg [1:0] byte_index;
    reg [7:0] current_byte;
    reg [19:0] wait_cnt;

    always @( posedge clk ) begin
        if (rst) begin
            state <= WAIT;
            sio_c <= 1;
            sio_d <= 1;
            rom_addr <= 0;
            init_ready <= 0;
            phase <= 0;
            bit_index <= 7;
            byte_index <= 0;
            current_byte <= 0;
            wait_cnt <= 0;
        end else begin
            case (state)
                // Provides a delay for the camera to process data
                WAIT : begin
                    if (wait_cnt == 1_000_000) begin
                        wait_cnt <= 0;
                        state <= IDLE;
                    end else wait_cnt <= wait_cnt + 1;
                end
                IDLE : begin
                    sio_c <= 1;
                    sio_d <= 1;
                    if (rom_data == 16'hFFFF) begin // Check for end of ROM
                        init_ready <= 1;
                        state <= DONE;
                    end else begin
                        current_byte <= 8'h42; // Camera Write ID Address
                        byte_index <= 0;
                        bit_index <= 7;
                        phase <= 0;
                        state <= START;
                    end
                end
                // Start bit : SIO_D goes low while SIO_C is high
                START : begin
                    if (tick) begin
                        if (!phase) begin
                            sio_d <= 0;
                            phase <= 1;
                        end else begin
                            sio_c <= 0;
                            phase <= 0;
                            state <= SEND;
                        end
                    end
                end
                // Transmits bits 7 down to 0
                SEND : begin
                    if (tick) begin
                        if (!phase) begin
                            sio_c <= 0;
                            // Place bit on data line
                            sio_d <= current_byte[bit_index];
                            phase <= 1;
                        end else begin
                            // Pulse clock to signal data is ready
                            sio_c <= 1;
                            phase <= 0;
                            if (bit_index == 0) state <= ACK; // Byte finished
                            else  bit_index <= bit_index - 1;
                        end
                    end
                end
                // SCCB 3-phase write requires an ACK/Don't Care bit
                ACK : begin
                    if (tick) begin
                        case (phase)
                            0 : begin
                                sio_c <= 0;
                                sio_d <= 1;
                                phase <= 1;
                            end
                            1 : begin
                                sio_c <= 1;
                                phase <= 2;
                            end
                            2 : begin
                                sio_c <= 0;
                                phase <= 0;
                                if (byte_index == 2) state <= STOP; // Sent ID, Addr, and Data
                                else begin
                                    byte_index <= byte_index + 1;
                                    // Prepare next byte from ROM
                                    case (byte_index)
                                        0: current_byte <= rom_data[15:8];
                                        1: current_byte <= rom_data[7:0];
                                    endcase
                                    bit_index <= 7;
                                    state <= SEND;
                                end
                            end
                        endcase
                    end
                end
                // Stop bit : SIO_D goes high while SIO_C is high
                STOP : begin
                    if (tick) begin
                        if (!phase) begin
                            sio_c <= 1;
                            sio_d <= 0;
                            phase <= 1;
                        end else begin
                            sio_d <= 1;
                            phase <= 0;
                            state <= NEXT;
                        end
                    end
                end
                // Increment ROM address to configure next register
                NEXT : begin
                    rom_addr <= rom_addr + 1;
                    wait_cnt <= 0;
                    state <= WAIT;
                end
                // All 68 registers sent successfully
                DONE : init_ready <= 1;
                default : state <= WAIT;
            endcase
        end
    end
endmodule
