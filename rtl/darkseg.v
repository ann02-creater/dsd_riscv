/*
 * 7-Segment Controller for DarkRISCV
 * Displays 32-bit integer on 8-digit 7-segment display (Hexadecimal)
 */

`timescale 1ns / 1ps

module darkseg
(
    input         CLK,       // System Clock (100MHz)
    input         RES,       // Reset
    input  [31:0] DATA,      // Data to display
    
    output [7:0]  SEG,       // Segments (CA-CG, DP)
    output [7:0]  AN         // Anodes (AN0-AN7)
);

    reg [16:0] PRESCALER = 0; // 100MHz 
    reg [2:0]  DIGIT_SEL = 0; // Current digit (0-7)

    always @(posedge CLK) begin
        if (RES) begin
            PRESCALER <= 0;
            DIGIT_SEL <= 0;
        end else begin
            PRESCALER <= PRESCALER + 1;
            if (PRESCALER == 0) begin
                DIGIT_SEL <= DIGIT_SEL + 1;
            end
        end
    end

    // Anode Control (Active Low)
    reg [7:0] AN_REG;
    always @(*) begin
        AN_REG = 8'hFF;
        AN_REG[DIGIT_SEL] = 0;
    end
    assign AN = AN_REG;

    // Data Selection
    reg [3:0] HEX;
    always @(*) begin
        case (DIGIT_SEL)
            3'd0: HEX = DATA[3:0];
            3'd1: HEX = DATA[7:4];
            3'd2: HEX = DATA[11:8];
            3'd3: HEX = DATA[15:12];
            3'd4: HEX = DATA[19:16];
            3'd5: HEX = DATA[23:20];
            3'd6: HEX = DATA[27:24];
            3'd7: HEX = DATA[31:28];
            default: HEX = 0;
        endcase
    end

    // Segment Decoder (0: On, 1: Off) - Common Anode standard
    // Some boards use Common Anode (0=ON), some Common Cathode (1=ON).
    // Nexys A7 uses Common Anode -> 0 is ON.
    // Segments: DP, G, F, E, D, C, B, A
    reg [7:0] SEG_REG;
    always @(*) begin
        case (HEX)
            //                        xgfedcba
            4'h0: SEG_REG = 8'b11000000; // 0
            4'h1: SEG_REG = 8'b11111001; // 1
            4'h2: SEG_REG = 8'b10100100; // 2
            4'h3: SEG_REG = 8'b10110000; // 3
            4'h4: SEG_REG = 8'b10011001; // 4
            4'h5: SEG_REG = 8'b10010010; // 5
            4'h6: SEG_REG = 8'b10000010; // 6
            4'h7: SEG_REG = 8'b11111000; // 7
            4'h8: SEG_REG = 8'b10000000; // 8
            4'h9: SEG_REG = 8'b10010000; // 9
            4'hA: SEG_REG = 8'b10001000; // A
            4'hB: SEG_REG = 8'b10000011; // b
            4'hC: SEG_REG = 8'b11000110; // C
            4'hD: SEG_REG = 8'b10100001; // d
            4'hE: SEG_REG = 8'b10000110; // E
            4'hF: SEG_REG = 8'b10001110; // F
            default: SEG_REG = 8'b11111111;
        endcase
    end
    
    assign SEG = SEG_REG;

endmodule
