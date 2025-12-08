// run: iverilog -g2012 -o mp4_sim mp4_tb.sv
// then: vvp mp4_sim

`include "mp4.sv"
`timescale 1ns / 1ps

module mp4_tb;

    logic clk = 0;
    logic rst = 1;
    logic LED, RGB_R, RGB_G, RGB_B;

    mp4 u0 (
        .clk            (clk),
        .rst            (rst),
        .led            (LED), 
        .red            (RGB_R), 
        .green          (RGB_G), 
        .blue           (RGB_B)
    );

    // Monitor for terminal display
    logic [31:0] prev_pc;
    logic [31:0] prev_instr;
    logic [3:0] prev_state;
    
    initial begin
        $dumpfile("mp4.vcd"); //dump
        $dumpvars(0, mp4_tb);   
        
        #20 rst = 0;
        prev_pc = u0.riscvmulti.pc;
        prev_instr = u0.riscvmulti.Instr;
        prev_state = u0.riscvmulti.c.finite_state_machine.state;
        
        #1000
        $finish;
    end
    
    // state changes
    always @(posedge clk) begin
        if (!rst) begin
            //every time the state changes:
            if (u0.riscvmulti.c.finite_state_machine.state !== prev_state) begin
                $display("  PC: 0x%08h    state: %s   instr: 0x%08h", 
                         u0.riscvmulti.pc,
                         u0.riscvmulti.c.finite_state_machine.state.name(),
                         u0.riscvmulti.Instr);
                prev_state = u0.riscvmulti.c.finite_state_machine.state;
            end
        end
    end
    
    //register write
    always @(posedge clk) begin
        if (!rst && u0.riscvmulti.RegWrite) begin // whenever writing to reg
            if (u0.riscvmulti.Instr[11:7] != 0) begin
                $display("reg x%0d = 0x%08h", 
                         u0.riscvmulti.Instr[11:7], //reg address
                         u0.riscvmulti.dp.Result); //value
            end
        end
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule