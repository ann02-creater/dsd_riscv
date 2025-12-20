

`timescale 1ns / 1ps
`include "../rtl/config.vh"

module darksocv_tb;

    parameter CLK_PERIOD = 10;          // 100MHz = 10ns Ï£ºÍ∏∞
    parameter RESET_DURATION = 2000;    // 2us Î¶¨ÏÖã ?ú†Ïß? (Ï∂©Î∂Ñ?ïú ?ãúÍ∞?)
    parameter SIM_DURATION = 200000;    // 200us ?ãúÎÆ¨Î†à?ù¥?Öò (?çî Í∏? ?ãúÍ∞?)

    reg         XCLK;
    reg         XRES;
    reg  [15:0] SW;
    
    wire        UART_TXD;
    reg         UART_RXD;
    wire [15:0] LED;
    wire [7:0]  SEG;
    wire [7:0]  AN;


    initial begin
        XCLK = 0;
        forever #(CLK_PERIOD/2) XCLK = ~XCLK;
    end

    //=========================================================================
    // Î¶¨ÏÖã ?ãú???ä§ (INVRES Í≥†Î†§)
    //=========================================================================
    initial begin
  
        XRES = 1;           
        SW = 16'h0000;
        UART_RXD = 1;    
        
        $display("=====================================");
        $display("  DarkRISCV Testbench Started");
        $display("  Clock Period: %0d ns", CLK_PERIOD);
        $display("=====================================");
        $display("Time: %0t ns - Reset ACTIVE (XRES=1)", $time);
        

        #RESET_DURATION;
        

        XRES = 0;
        $display("Time: %0t ns - Reset RELEASED (XRES=0) <<<", $time);
        $display("=====================================");
        $display("Monitoring CPU activity...");
        $display("=====================================");
        
        // CPU ?èô?ûë Í¥?Ï∞?
        #SIM_DURATION;
        
        $display("=====================================");
        $display("  Simulation Complete at %0t ns", $time);
        $display("=====================================");
        $finish;
    end

    //=========================================================================
    // DUT (Device Under Test) ?ù∏?ä§?Ñ¥?ä§
    //=========================================================================
    darksocv soc0 (
        .XCLK(XCLK),
        .XRES(XRES),
        .UART_RXD(UART_RXD),
        .UART_TXD(UART_TXD),
        .LED(LED),
        .SW(SW),
        .SEG(SEG),
        .AN(AN)
    );
    
    //=========================================================================
    // Î©îÎ™®Î¶? Ï¥àÍ∏∞?ôî
    // ?ö†Ô∏? Block Memory Generator IP ?Ç¨?ö© ?ãú: 
    //    IP ?Ñ§?†ï?óê?Ñú .coe ?åå?ùº Ïß??†ï?ï¥?ïº ?ï® (?ù¥ ÏΩîÎìú?äî ?ûë?èô ?ïà ?ï®)
    // ?ö†Ô∏? ?ùºÎ∞? darkram.v ?Ç¨?ö© ?ãú:
    //    ?ïÑ?ûò $readmemh Ï£ºÏÑù ?ï¥?†ú
    //=========================================================================
    /*
    initial begin
        // ?ùºÎ∞? darkram.v ?Ç¨?ö© ?ãú?óêÎß? ?ûë?èô
        $readmemh("darksocv.mem", soc0.bram0.MEM);
        $display("Memory loaded from darksocv.mem");
        $display("First instruction: %08h", soc0.bram0.MEM[0]);
        $display("Second instruction: %08h", soc0.bram0.MEM[1]);
    end
    */
    
    //=========================================================================
    // CPU ?Ç¥Î∂? ?ã†?ò∏ Î™®Îãà?Ñ∞Îß? (PC, IADDR, IDATA)
    //=========================================================================
    wire [31:0] monitor_pc;
    wire [31:0] monitor_iaddr;
    wire [31:0] monitor_idata;
    wire        monitor_idreq;
    wire        monitor_idack;
    wire        monitor_flush;
    wire        monitor_hlt;
    wire        monitor_res;
    
    // CPU ?Ç¥Î∂? ?ã†?ò∏ ?ó∞Í≤?
    assign monitor_pc     = soc0.bridge0.core0.PC;
    assign monitor_iaddr  = soc0.bridge0.core0.IADDR;
    assign monitor_idata  = soc0.bridge0.core0.IDATA;
    assign monitor_idreq  = soc0.bridge0.core0.IDREQ;
    assign monitor_idack  = soc0.bridge0.core0.IDACK;
    assign monitor_flush  = soc0.bridge0.core0.FLUSH;
    assign monitor_hlt    = soc0.bridge0.core0.HLT;
    assign monitor_res    = soc0.bridge0.core0.XRES;

    //=========================================================================
    // Î™®Îãà?Ñ∞Îß? - Ï£ºÏöî ?ã†?ò∏ Í¥?Ï∞?
    //=========================================================================
    
    // Î¶¨ÏÖã ?ï¥?†ú ?õÑ CPU ?èô?ûë Î™®Îãà?Ñ∞Îß?
    always @(posedge XCLK) begin
        if (!XRES) begin  // Î¶¨ÏÖã ?ï¥?†ú ?õÑ?óêÎß? Î™®Îãà?Ñ∞Îß?
            // 100 ?Å¥?ü≠ÎßàÎã§ ?ÉÅ?Éú Ï∂úÎ†•
            if ($time % 1000 == 0 && $time > RESET_DURATION) begin
                $display("Time: %0t | LED: %04h | SEG: %02h | AN: %02h", 
                         $time, LED, SEG, AN);
            end
        end
    end

    //=========================================================================
    // UART ?Ü°?ã† Î™®Îãà?Ñ∞Îß? (CPUÍ∞? Ï∂úÎ†•?ïò?äî Î¨∏Ïûê Ï∫°Ï≤ò)
    //=========================================================================
    reg [7:0] uart_byte;
    reg [3:0] uart_bit_cnt;
    reg       uart_receiving;
    
    initial begin
        uart_receiving = 0;
        uart_bit_cnt = 0;
        uart_byte = 0;
    end
    
    // UART TX ?ã†?ò∏ Î≥??ôî Í∞êÏ? (Í∞ÑÎã®?ïú Î™®Îãà?Ñ∞)
    always @(negedge UART_TXD) begin
        if (!uart_receiving && !XRES) begin
            $display("Time: %0t - UART TX Activity Detected!", $time);
        end
    end

    //=========================================================================
    // VCD ?åå?ùº ?Éù?Ñ± (Vivado ?åå?òï Î∑∞Ïñ¥?ö©)
    //=========================================================================
    initial begin
        $dumpfile("darksocv_tb.vcd");
        $dumpvars(0, darksocv_tb);
        
        // CPU ?Ç¥Î∂? ?†àÏß??ä§?Ñ∞?èÑ ?ç§?îÑ (?îîÎ≤ÑÍπÖ?ö©)
        // $dumpvars(0, soc0.bridge0.core0);
    end

    //=========================================================================
    // PC Î≥??ôî Î™®Îãà?Ñ∞Îß? (Î¶¨ÏÖã ?ï¥?†ú ?õÑ)
    //=========================================================================
    reg [31:0] prev_pc = 32'hFFFFFFFF;
    reg        first_pc_print = 1;
    
    always @(posedge XCLK) begin
        if (!monitor_res && monitor_pc !== 32'hxxxxxxxx) begin
            // PCÍ∞? Î≥?Í≤ΩÎê† ?ïåÎßàÎã§ Ï∂úÎ†• (Ï≤òÏùå 20Î≤àÎßå)
            if (monitor_pc != prev_pc && first_pc_print) begin
                $display("Time: %0t ns | PC: %08h | IDATA: %08h | FLUSH: %0d", 
                         $time, monitor_pc, monitor_idata, monitor_flush);
                prev_pc <= monitor_pc;
                
                // Ï≤òÏùå 20Í∞? Î™ÖÎ†π?ñ¥Îß? Ï∂úÎ†•
                if (monitor_pc > 32'h50) first_pc_print <= 0;
            end
        end
    end
    
    //=========================================================================
    // IO ?†ëÍ∑? Î™®Îãà?Ñ∞Îß? (UART, LED, 7-Segment)
    //=========================================================================
    wire [31:0] monitor_daddr = soc0.bridge0.core0.DADDR;
    wire [31:0] monitor_datao = soc0.bridge0.core0.DATAO;
    wire        monitor_dwr   = soc0.bridge0.core0.DWR;
    
    always @(posedge XCLK) begin
        // IO ?òÅ?ó≠ (0x40000000) ?†ëÍ∑? Í∞êÏ?
        if (!monitor_res && monitor_daddr[31:28] == 4'h4 && !monitor_dwr) begin
            $display("Time: %0t ns | IO WRITE: Addr=%08h Data=%08h", 
                     $time, monitor_daddr, monitor_datao);
        end
    end

endmodule
