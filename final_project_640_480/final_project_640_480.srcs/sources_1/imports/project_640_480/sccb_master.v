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

            // =================================================================
            // 1. Soft Reset
            // =================================================================
            // Reg 12 (COM7) = 0x80 -> Clear all registers to defaults and reset internal FSMs
            0  : rom_data = 16'h1280;

            // =================================================================
            // 2. Clocking & PLL (Internal Camera Speeds)
            // =================================================================
            // Reg 11 (CLKRC) = 0x00 -> Internal clock pre-scaler divide-by-1 (Direct external clock)
            1  : rom_data = 16'h1100;
            // Reg 6B (DBLV)  = 0x4A -> Enable PLL (x4 clock multiplier) and bypass internal regulator
            2  : rom_data = 16'h6B4A;
            // Reg 3B (COM11) = 0x0A -> Enable night mode, allowing frame rate to auto-drop in low light
            3  : rom_data = 16'h3B0A;

            // =================================================================
            // 3. Format & Scaling (Output Formats & Resolution)
            // =================================================================
            // Reg 12 (COM7)  = 0x04 -> Change digital output format to RGB processing
            4  : rom_data = 16'h1204;
            // Reg 40 (COM15) = 0xD0 -> Select normal digital output range [00 to FF] and format as RGB565
            5  : rom_data = 16'h40D0;
            // Reg 3A (TSLB)  = 0x04 -> Initialize line sequence windowing and UV auto-balancing
            6  : rom_data = 16'h3A04;
            // Reg 0C (COM3)  = 0x00 -> Output single frame mode, disable scale tracking features
            7  : rom_data = 16'h0C00;
            // Reg 3E (COM14) = 0x00 -> Disable manual pixel clock scaling dividers
            8  : rom_data = 16'h3E00;
            // Reg 70 (SCALING_XSC)   = 0x3A -> Horizontal scaling test pattern row ratio calculation
            9  : rom_data = 16'h703A;
            // Reg 71 (SCALING_YSC)   = 0x35 -> Vertical scaling test pattern column ratio calculation
            10 : rom_data = 16'h7135;
            // Reg 72 (SCALING_DCWCTR)= 0x11 -> Downsampling Control (Downsample digital array by 2)
            11 : rom_data = 16'h7211;
            // Reg 73 (SCALING_PCLK_DIV)  = 0xF1 -> Divide Pixel Clock (PCLK) by 2 for scaling synchronization
            12 : rom_data = 16'h73F1;
            // Reg A2 (SCALING_PCLK_DELAY)= 0x02 -> Slew delay output pixel clock to match data valid setup time
            13 : rom_data = 16'hA202;

            // =================================================================
            // 4. Windowing (Defines Visible Sensor Array Coordinates)
            // =================================================================
            // Reg 17 (HSTART) = 0x13 -> Horizontal sensor window start position (MSB 8 bits)
            14 : rom_data = 16'h1713;
            // Reg 18 (HSTOP)  = 0x01 -> Horizontal sensor window end position (MSB 8 bits)
            15 : rom_data = 16'h1801;
            // Reg 32 (HREF)   = 0xBF -> Horizontal edge control details (fractional alignment LSB bits)
            16 : rom_data = 16'h32BF;
            // Reg 19 (VSTART) = 0x02 -> Vertical sensor window start position (MSB 8 bits)
            17 : rom_data = 16'h1902;
            // Reg 1A (VSTOP)  = 0x7A -> Vertical sensor window end position (MSB 8 bits)
            18 : rom_data = 16'h1A7A;
            // Reg 03 (VREF)   = 0x0A -> Vertical edge control details (fractional alignment LSB bits)
            19 : rom_data = 16'h030A;

            // =================================================================
            // 5. Color Matrix (RGB Calculation / Tint adjustments)
            // =================================================================
            // Reg 4F to 54 define the color correction matrix multipliers (MTX1 to MTX6)
            20 : rom_data = 16'h4F8A; // MTX1 - Red gain matrix multiplier coefficient
            21 : rom_data = 16'h5075; // MTX2 - Green gain matrix multiplier coefficient
            22 : rom_data = 16'h5100; // MTX3 - Blue gain matrix multiplier coefficient
            23 : rom_data = 16'h5215; // MTX4 - Color space balance parameter
            24 : rom_data = 16'h539C; // MTX5 - Color space balance parameter
            25 : rom_data = 16'h54D4; // MTX6 - Color space balance parameter
            // Reg 58 (MTXS)   = 0x9E -> Matrix sign control for hardware color calculation formulas
            26 : rom_data = 16'h589E;

            // =================================================================
            // 6. AEC / AGC / AWB (Auto Exposure, Auto Gain, Auto White Balance)
            // =================================================================
            // Reg 13 (COM8)  = 0xEF -> Turn ON: Fast AGC, AEC, AWB, and Fast Color Filtering processes
            27 : rom_data = 16'h13EF;
            // Reg 00 (GAIN)  = 0x00 -> Set initial hardware multiplier gain to baseline 0dB
            28 : rom_data = 16'h0000;
            // Reg 10 (AECH)  = 0x00 -> Clear exposure value registers to hand control to auto-exposure engine
            29 : rom_data = 16'h1000;
            // Reg 0D (COM4)  = 0x40 -> Average window speed evaluation parameter for auto-exposure 
            30 : rom_data = 16'h0D40;
            // Reg 14 (COM9)  = 0x38 -> Restrict Automatic Gain Ceiling threshold limit to a max of 4x
            31 : rom_data = 16'h1438;
            // Reg 24 (AEW)   = 0x95 -> Upper limit luminance target threshold for Auto Exposure
            32 : rom_data = 16'h2495;
            // Reg 25 (AEB)   = 0x33 -> Lower limit luminance target threshold for Auto Exposure
            33 : rom_data = 16'h2533;
            // Reg 26 (VPT)   = 0xE3 -> Fast AGC/AEC target luminance balance threshold variable
            34 : rom_data = 16'h26E3;

            // =================================================================
            // 7. Gamma Curve Adjustments (Non-linear Brightness/Contrast mapping)
            // =================================================================
            // Reg 7A to 89 act as the 16 slope-points mapping raw sensor luminance 
            // data curves into clean, standard visual brightness ranges.
            35 : rom_data = 16'h7A20; // SLOP  - Gamma curve slope point 1
            36 : rom_data = 16'h7B10; // GAM1  - Gamma curve point 2
            37 : rom_data = 16'h7C1E; // GAM2  - Gamma curve point 3
            38 : rom_data = 16'h7D35; // GAM3  - Gamma curve point 4
            39 : rom_data = 16'h7E5A; // GAM4  - Gamma curve point 5
            40 : rom_data = 16'h7F69; // GAM5  - Gamma curve point 6
            41 : rom_data = 16'h8076; // GAM6  - Gamma curve point 7
            42 : rom_data = 16'h8180; // GAM7  - Gamma curve point 8
            43 : rom_data = 16'h8288; // GAM8  - Gamma curve point 9
            44 : rom_data = 16'h838F; // GAM9  - Gamma curve point 10
            45 : rom_data = 16'h8496; // GAM10 - Gamma curve point 11
            46 : rom_data = 16'h85A3; // GAM11 - Gamma curve point 12
            47 : rom_data = 16'h86AF; // GAM12 - Gamma curve point 13
            48 : rom_data = 16'h87C4; // GAM13 - Gamma curve point 14
            49 : rom_data = 16'h88D7; // GAM14 - Gamma curve point 15
            50 : rom_data = 16'h89E8; // GAM15 - Gamma curve point 16

            // =================================================================
            // 8. DSP & Denoise (Digital Processing Filter Engine)
            // =================================================================
            // Reg 41 (COM16) = 0x08 -> Turn ON Edge Enhancement filtering (sharpening)
            51 : rom_data = 16'h4108;
            // Reg 76 (OV_R45) = 0xE1 -> Active Color Matrix processing and digital denoise engine
            52 : rom_data = 16'h76E1;
            // Reg 33 (CHLF)  = 0x0B -> Pixel array low-pass color filter channel tuning
            53 : rom_data = 16'h330B;
            // Reg 3C (COM12) = 0x78 -> Enable internal noise-reduction filtering windows
            54 : rom_data = 16'h3C78;
            // Reg 69 (GFIX)  = 0x00 -> Fix digital gain metrics to manual zero baseline bounds
            55 : rom_data = 16'h6900;
            // Reg 74 (REG74) = 0x00 -> Disable digital gain headroom boost (preserves noise clarity)
            56 : rom_data = 16'h7400;
            // Reg B0 (RSVD)  = 0x84 -> Reserved optimization register parameter for lens correction
            57 : rom_data = 16'hB084;
            // Reg B1 (ABLC1) = 0x00 -> Automatic Black Level Calibration active
            58 : rom_data = 16'hB100;
            // Reg B2 (RSVD)  = 0x0E -> Reserved optimization bits for color separation thresholds
            59 : rom_data = 16'hB20E;
            // Reg B3 (THL_ST) = 0x82 -> Target baseline setup for dark frame sensor cleanup
            60 : rom_data = 16'hB382;

            // =================================================================
            // 9. Saturation & Contrast
            // =================================================================
            // Reg 67 (MANU)  = 0x80 -> Set manual color saturation initialization index (U-channel)
            61 : rom_data = 16'h6780;
            // Reg 68 (MANV)  = 0x80 -> Set manual color saturation initialization index (V-channel)
            62 : rom_data = 16'h6880;
            // Reg 56 (MANC)  = 0x40 -> Fixed manual contrast ratio scaling matrix value
            63 : rom_data = 16'h5640;

            // =================================================================
            // 10. Frame Stability & Sync Tuning
            // =================================================================
            // Reg 15 (COM10) = 0x00 -> VSYNC edges fall on valid markers, HREF normal polarity bounds
            64 : rom_data = 16'h1500;
            // Reg 13 (COM8)  = 0xEF -> Re-assert Auto parameters to guarantee clock states haven't lost values
            65 : rom_data = 16'h13EF;
            // Reg 0E (COM5)  = 0x61 -> Drive strength adjustments optimized for internal register reading stability
            66 : rom_data = 16'h0E61;
            // Reg 16 (RSVD)  = 0x00 -> Reserved sensor sync baseline initialization tuning
            67 : rom_data = 16'h1600;
            // Reg 1E (MVFP)  = 0x07 -> Enable physical mirror/flip layout matrix over output image data pixels
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
