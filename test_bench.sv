//`include "top.sv"

`timescale 1ns/1ps
`include "./top.sv"

module test_bench;

    logic clk = 0;
    logic SW = 0;
    logic BOOT = 0;
    logic led, red, green, blue;

    top u0 (
        .clk    (clk),
        .SW     (SW),
        .BOOT   (BOOT),
        .led    (led),
        .red    (red),
        .green  (green),
        .blue   (blue)
    );

    // Monitor signals
    logic [31:0] prev_pc;
    logic [31:0] prev_instr;
    logic [3:0] prev_state;
    
 initial begin
    $dumpfile("test_bench.vcd");
    $dumpvars(0, test_bench);
    $dumpvars(0, u0.u3.register_array[0]);
    $dumpvars(0, u0.u3.register_array[1]);
    $dumpvars(0, u0.u3.register_array[2]);
    $dumpvars(0, u0.u3.register_array[3]);
    $dumpvars(0, u0.u3.register_array[4]);
    $dumpvars(0, u0.u3.register_array[5]);
    $dumpvars(0, u0.u3.register_array[6]);
    $dumpvars(0, u0.u3.register_array[7]);
    $dumpvars(0, u0.u3.register_array[8]);
    $dumpvars(0, u0.u3.register_array[9]);
    $dumpvars(0, u0.u3.register_array[10]);
    $dumpvars(0, u0.u3.register_array[11]);
    $dumpvars(0, u0.u3.register_array[12]);
    $dumpvars(0, u0.u3.register_array[13]);
    $dumpvars(0, u0.u3.register_array[14]);
    $dumpvars(0, u0.u3.register_array[15]);
    $dumpvars(0, u0.u3.register_array[16]);
    $dumpvars(0, u0.u3.register_array[17]);
    $dumpvars(0, u0.u3.register_array[18]);
    $dumpvars(0, u0.u3.register_array[19]);
    $dumpvars(0, u0.u3.register_array[20]);
    
    // Initialize previous values
    #100;
    
    prev_pc = u0.pc;
    prev_instr = u0.Instr_reg;
    prev_state = u0.u4.current_state;
    
    #35000;

    $display("\n================ FINAL REGISTER AUDIT ================");
    $display("x1  = 0x%08h (expected 0xfedcba98)", u0.u3.register_array[1]);
    $display("x2  = 0x%08h (expected 0x0fedcba9)", u0.u3.register_array[2]);
    $display("x3  = 0x%08h (expected 0xffedcba9)", u0.u3.register_array[3]);
    $display("x4  = 0x%08h (expected 0x00123456)", u0.u3.register_array[4]);
    $display("x5  = 0x%08h (expected 0x00000002)", u0.u3.register_array[5]);
    $display("x6  = 0x%08h (expected 0x00123458)", u0.u3.register_array[6]);
    $display("x7  = 0x%08h (expected 0x00000002)", u0.u3.register_array[7]);
    $display("x8  = 0x%08h (expected 0x0048d158)", u0.u3.register_array[8]);
    $display("x9  = 0x%08h (expected 0x0048d15f)", u0.u3.register_array[9]);
    $display("x10 = 0x%08h (expected 0x12346058)", u0.u3.register_array[10]);
    $display("x11 = 0x%08h (expected 0x00000001)", u0.u3.register_array[11]);
    $display("x12 = 0x%08h (expected 0x00000000)", u0.u3.register_array[12]);
    $display("x13 = 0x%08h (expected 0x00001068)", u0.u3.register_array[13]);
    $display("x14 = 0x%08h (expected 0x00001090)", u0.u3.register_array[14]);
    $display("x15 = 0x%08h (expected 0x00000000)", u0.u3.register_array[15]);
    $display("x16 = 0x%08h (expected 0x00001078)", u0.u3.register_array[16]);
    $display("x17 = 0x%08h (expected 0x000000c0)", u0.u3.register_array[17]);
    $display("x18 = 0x%08h (expected 0xc0c0c0c0)", u0.u3.register_array[18]);
    $display("x20 = 0x%08h (expected 0xffffc0c0)", u0.u3.register_array[20]);
    $display("x21 = 0x%08h (expected 0x0000c0c0)", u0.u3.register_array[21]);

    if (u0.u3.register_array[1]  === 32'hfedcba98 &&
        u0.u3.register_array[2]  === 32'h0fedcba9 &&
        u0.u3.register_array[3]  === 32'hffedcba9 &&
        u0.u3.register_array[4]  === 32'h00123456 &&
        u0.u3.register_array[5]  === 32'h00000002 &&
        u0.u3.register_array[6]  === 32'h00123458 &&
        u0.u3.register_array[7]  === 32'h00000002 &&
        u0.u3.register_array[8]  === 32'h0048d158 &&
        u0.u3.register_array[9]  === 32'h0048d15f &&
        u0.u3.register_array[10] === 32'h12346058 &&
        u0.u3.register_array[11] === 32'h00000001 &&
        u0.u3.register_array[12] === 32'h00000000 &&
        u0.u3.register_array[13] === 32'h00001068 &&
        u0.u3.register_array[14] === 32'h00001090 &&
        u0.u3.register_array[15] === 32'h00000000 &&
        u0.u3.register_array[16] === 32'h00001078 &&
        u0.u3.register_array[17] === 32'h000000c0 &&
        u0.u3.register_array[18] === 32'hc0c0c0c0 &&
        u0.u3.register_array[20] === 32'hffffc0c0 &&
        u0.u3.register_array[21] === 32'h0000c0c0) begin
        $display("\n>>> ALL 20 REGISTER ASSERTIONS PASSED! <<<");
    end else begin
        $display("\n>>> VERIFICATION FAILED! <<<");
    end
    $display("======================================================\n");

    $finish;
end
    
    // Display state changes
    always @(posedge clk) begin
        if (u0.reset) begin
            // Every time the state changes
            if (u0.u4.current_state !== prev_state) begin
                $display("PC: 0x%08h  State: %1d  Instr: 0x%08h  rd: x%0d  rs1: x%0d  rs2: x%0d", 
                         u0.pc,
                         u0.u4.current_state,
                         u0.Instr_reg,
                         u0.Instr_reg[11:7],
                         u0.Instr_reg[19:15],
                         u0.Instr_reg[24:20]);
                prev_state = u0.u4.current_state;
            end
        end
    end
    
    // Display register writes
    always @(posedge clk) begin
        if (u0.reset && u0.WriteEnable) begin
            if (u0.Address3 != 0) begin
                $display("    >>> REG WRITE: x%0d = 0x%08h", 
                         u0.Address3,
                         u0.WriteData);
            end
        end
    end
    
    // Display memory writes
    always @(posedge clk) begin
        if (u0.reset && u0.dmem_wren) begin
            $display("    >>> MEM WRITE: Addr=0x%08h Data=0x%08h", 
                     u0.dmem_address,
                     u0.dmem_data_in);
        end
    end

    // Clock generation (12MHz = 83.33ns period)
    always begin
        #41.67 clk = ~clk;
    end

endmodule