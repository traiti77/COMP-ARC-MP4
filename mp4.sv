`include "memory.sv"

// top - connect external memory file
module mp4 (
    input  logic clk,
    input  logic rst,
    output logic led,  
    output logic red,    
    output logic green,           
    output logic blue             
);

// signals
logic mem_rst;
logic [31:0] imem_address, imem_data;
logic [31:0] dmem_address, dmem_data_in, dmem_data_out;
logic dmem_wren;
logic [2:0] funct3;

memory #(
    .IMEM_INIT_FILE_PREFIX("rv32I_test"),
    .DMEM_INIT_FILE_PREFIX("dmem"),
    .CLK_FREQ(12000000)
) mem (
    .clk(clk),
    .funct3(funct3),
    .dmem_wren(dmem_wren),
    .dmem_address(dmem_address),
    .dmem_data_in(dmem_data_in),
    .imem_address(imem_address),
    .imem_data_out(imem_data),
    .dmem_data_out(dmem_data_out),
    .reset(mem_rst),
    .led(led),
    .red(red),
    .green(green),
    .blue(blue)
);

processor riscvmulti(
    .clk(clk), 
    .reset(rst),
    .imem_address(imem_address),
    .imem_data(imem_data),
    .dmem_wren(dmem_wren),
    .dmem_address(dmem_address),
    .dmem_data_in(dmem_data_in),
    .dmem_data_out(dmem_data_out),
    .funct3(funct3)
);

endmodule

module processor(
    input logic clk, reset,
    output logic [31:0] imem_address,
    input  logic [31:0] imem_data,
    output logic        dmem_wren,
    output logic [31:0] dmem_address,
    output logic [31:0] dmem_data_in,
    input  logic [31:0] dmem_data_out,
    output logic [2:0]  funct3
);
    logic [1:0]  ResultSrc, ALUSrcA, ALUSrcB;
    logic [2:0]  ImmSrc;
    logic        AdrSrc, IRWrite, PCWrite, RegWrite, zero, lt_zero;
    logic [3:0]  ALUControl;
    logic [31:0] Instr, pc;

assign imem_address = pc;
assign funct3 = Instr[14:12];

control c(
    .clk(clk), 
    .reset(reset),
    .op(Instr[6:0]),
    .funct3(Instr[14:12]),
    .funct7b5(Instr[30]),
    .funct7(Instr[31:25]),
    .zero(zero),
    .lt_zero(lt_zero),
    .PCWrite(PCWrite),
    .AdrSrc(AdrSrc),
    .MemWrite(dmem_wren),
    .IRWrite(IRWrite),
    .ResultSrc(ResultSrc),
    .ALUControl(ALUControl),
    .ALUSrcB(ALUSrcB),
    .ALUSrcA(ALUSrcA),
    .ImmSrc(ImmSrc),
    .RegWrite(RegWrite)
);

datapath dp(
    .clk(clk),
    .reset(reset),
    .ResultSrc(ResultSrc),
    .ImmSrc(ImmSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .AdrSrc(AdrSrc),
    .IRWrite(IRWrite),
    .PCWrite(PCWrite),
    .RegWrite(RegWrite),
    .ALUControl(ALUControl),
    .ReadData(dmem_data_out),
    .imem_data(imem_data),
    .zero(zero),
    .lt_zero(lt_zero),
    .Instr(Instr),
    .DataAdr(dmem_address),
    .WriteData(dmem_data_in),
    .pc(pc)
);
endmodule

module control(
    input logic clk, reset,
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [6:0] funct7,
    input logic zero,
    input logic lt_zero,
    output logic PCWrite,
    output logic AdrSrc,
    output logic MemWrite,
    output logic IRWrite,
    output logic [1:0] ResultSrc,
    output logic [3:0] ALUControl,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ALUSrcA,
    output logic [2:0] ImmSrc,
    output logic RegWrite
); 

    logic [1:0] ALUOp;
    logic PCUpdate;
    logic Branch;
    logic BranchCondition;

fsm finite_state_machine(
    .clk(clk),
    .reset(reset),
    .op(op),
    .funct3(funct3),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ALUOp(ALUOp),
    .ResultSrc(ResultSrc),
    .AdrSrc(AdrSrc),
    .IRWrite(IRWrite),
    .PCUpdate(PCUpdate),
    .MemWrite(MemWrite),
    .RegWrite(RegWrite),
    .Branch(Branch),
    .ImmSrc(ImmSrc)
);

aludec alu_decoder(
    .op(op),
    .op5(op[5]),
    .funct3(funct3),
    .funct7b5(funct7b5),
    .funct7(funct7),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl)
);

always_comb begin
    case(funct3)
        3'b000: BranchCondition = zero;
        3'b001: BranchCondition = ~zero;
        3'b100: BranchCondition = lt_zero;
        3'b101: BranchCondition = ~lt_zero;
        3'b110: BranchCondition = lt_zero;
        3'b111: BranchCondition = ~lt_zero;
        default: BranchCondition = 0;
    endcase
end

assign PCWrite = PCUpdate | (Branch & BranchCondition);
endmodule 

module datapath(
    input logic clk, reset,
    input  logic [1:0]  ResultSrc, ALUSrcA, ALUSrcB,
    input  logic [2:0]  ImmSrc,
    input  logic        AdrSrc,
    input  logic        IRWrite,
    input  logic        PCWrite,
    input  logic        RegWrite,
    input  logic [3:0]  ALUControl,
    input  logic [31:0] ReadData, imem_data,
    output logic        zero,
    output logic        lt_zero,
    output logic [31:0] Instr, DataAdr, WriteData, pc
);

logic [31:0] PCNext, OldPC;
logic [31:0] RD1, RD2, A, B;
logic [31:0] SrcA, SrcB;
logic [31:0] ALUResult, ALUOut, Data, Result, ImmExt;

assign PCNext = Result;
ff_en_register #(.INIT_VALUE(32'h00001000)) program_counter(clk, reset, PCWrite, PCNext, pc);

mux_AdrSrc addr_mux(AdrSrc, pc, Result, DataAdr);

ff_en_register #(.INIT_VALUE(32'd0)) instr_reg(clk, reset, IRWrite, imem_data, Instr);
ff_en_register #(.INIT_VALUE(32'h00001000)) OldPC_reg(clk, reset, IRWrite, pc, OldPC);
ff_register data_register(clk, reset, ReadData, Data);

register_file rf(
    .clk(clk),
    .Rs1(Instr[19:15]),
    .Rs2(Instr[24:20]),
    .Rd(Instr[11:7]),
    .RegWrite(RegWrite),
    .Result(Result),
    .RD1(RD1),
    .RD2(RD2)
);

extend sign_extender(Instr, ImmSrc, ImmExt);

ff_register A_register(clk, reset, RD1, A);
ff_register B_register(clk, reset, RD2, B);
assign WriteData = B;

mux_3input A_mux(pc, OldPC, A, ALUSrcA, SrcA);
mux_3input B_mux(B, ImmExt, 32'd4, ALUSrcB, SrcB);

ALU alu(ALUControl, SrcA, SrcB, zero, lt_zero, ALUResult);

ff_register ALUOut_register(clk, reset, ALUResult, ALUOut);

mux_3input result_mux(ALUOut, Data, ALUResult, ResultSrc, Result);

endmodule

module fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    output logic [1:0] ALUSrcA, ALUSrcB, ALUOp, ResultSrc,
    output logic [2:0] ImmSrc,
    output logic       AdrSrc,
    output logic       IRWrite, PCUpdate, MemWrite, RegWrite, Branch
);

    typedef enum logic [3:0] {
        FETCH, DECODE, MEMADR, MEMREAD, MEMWB,
        MEMWRITE, EXECUTER, ALUWB, EXECUTEI,
        JAL, BEQ, LUI, AUIPC
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            state <= FETCH;
        else 
            state <= next_state;
    end

    always_comb begin
        IRWrite = 0;
        PCUpdate = 0;
        RegWrite = 0;
        MemWrite = 0;
        Branch = 0;
        AdrSrc = 0;
        ALUOp = 2'b00;
        ALUSrcA = 2'b00;
        ALUSrcB = 2'b00;
        ResultSrc = 2'b00;
        ImmSrc = 3'b000;
        next_state = FETCH;

        case(state)
            FETCH: begin
                AdrSrc = 0;
                IRWrite = 1;
                ALUSrcA = 2'b00;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                ResultSrc = 2'b10;
                PCUpdate = 1;
                next_state = DECODE;
            end
            
            DECODE: begin
                ALUSrcA = 2'b01;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                
                case (op)
                    7'b0000011: begin  // lw - I-type
                        ImmSrc = 3'b000;
                        next_state = MEMADR;
                    end
                    7'b0100011: begin  // sw - S-type
                        ImmSrc = 3'b001;
                        next_state = MEMADR;
                    end
                    7'b0110011: begin  // R-type
                        next_state = EXECUTER;
                    end
                    7'b0010011: begin  // I-type ALU
                        ImmSrc = 3'b000;
                        next_state = EXECUTEI;
                    end
                    7'b0110111: begin  // lui, U-type 
                        ImmSrc = 3'b011;
                        next_state = LUI;
                    end
                    7'b0010111: begin  // auipc, U-type 
                        ImmSrc = 3'b011;
                        next_state = AUIPC;
                    end
                    7'b1101111: begin  // jal,J-type
                        ImmSrc = 3'b100;
                        next_state = JAL;
                    end
                    7'b1100111: begin  // jalr, I-type
                        ImmSrc = 3'b000;
                        next_state = EXECUTEI;
                    end
                    7'b1100011: begin  // branch, B-type
                        ImmSrc = 3'b010;
                        next_state = BEQ;
                    end
                    default: begin
                        ImmSrc = 3'b000;  // Default to I-type, check if ok
                        next_state = FETCH; // initial
                    end
                endcase
            end
            
            MEMADR: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                
                if (op == 7'b0000011)
                    next_state = MEMREAD;
                else
                    next_state = MEMWRITE;
            end
            
            MEMREAD: begin
                ResultSrc = 2'b00;
                AdrSrc = 1;
                next_state = MEMWB;
            end
            
            MEMWB: begin
                ResultSrc = 2'b01;
                RegWrite = 1;
                next_state = FETCH;
            end
            
            MEMWRITE: begin
                ResultSrc = 2'b00;
                AdrSrc = 1;
                MemWrite = 1;
                next_state = FETCH;
            end
            
            EXECUTER: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                ALUOp = 2'b10;
                next_state = ALUWB;
            end
            
            ALUWB: begin
                ResultSrc = 2'b00;
                RegWrite = 1;
                next_state = FETCH;
            end
            
            EXECUTEI: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp = 2'b10;
                next_state = ALUWB;
            end
            
            LUI: begin
                // pass immediate through the ALU
                ImmSrc = 3'b011;  
                ALUSrcA = 2'b00;  
                ALUSrcB = 2'b01; 
                ALUOp = 2'b11;   
                next_state = ALUWB;  // writeback
            end
            
            AUIPC: begin // check later
                ImmSrc = 3'b011;  
                ALUSrcA = 2'b01;  // Use OldPC ??
                ALUSrcB = 2'b01;  
                ALUOp = 2'b00;    
                next_state = ALUWB;  // wrteback 
            end
            
            JAL: begin
                ALUSrcA = 2'b01;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                ResultSrc = 2'b00;
                PCUpdate = 1;
                next_state = ALUWB;
            end
            
            BEQ: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                ALUOp = 2'b01;
                ResultSrc = 2'b00;
                Branch = 1;
                next_state = FETCH;
            end
            
            default: begin
                next_state = FETCH;
            end
        endcase
    end
endmodule

module register_file (
    input logic clk,
    input logic [4:0] Rs1,
    input logic [4:0] Rs2,
    input logic [4:0] Rd,
    input logic RegWrite,
    input logic [31:0] Result,
    output logic [31:0] RD1, RD2
);
    logic [31:0] regFile[31:0];
    assign RD1 = (Rs1 != 0) ? regFile[Rs1] : 0;
    assign RD2 = (Rs2 != 0) ? regFile[Rs2] : 0;
    always_ff @(posedge clk) begin
        if (RegWrite && Rd > 0) begin
            regFile[Rd] <= Result;
        end
    end
endmodule

module extend (
    input logic [31:0] Instr,
    input logic [2:0] ImmSrc,
    output logic [31:0] ImmExt
);
    always_comb begin 
        case(ImmSrc)
            3'b000: ImmExt = {{20{Instr[31]}}, Instr[31:20]};  // I-type: sign-extend 12 bits
            3'b001: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};  // S-type: sign-extend store offset
            3'b010: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};  // B-type: sign-extend branch offset
            3'b011: ImmExt = {Instr[31:12], 12'b0};  // U-type: upper 20 bits in [31:12], zeros in [11:0]
            3'b100: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};  // J-type: JAL immediate
            default: ImmExt = 32'bx;
        endcase
    end
endmodule

module aludec(
    input logic [6:0] op,
    input logic op5,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [6:0] funct7,
    input logic [1:0] ALUOp,
    output logic [3:0] ALUControl
);
    logic RtypeSub;
    assign RtypeSub = (funct7b5 & op5);
    
    always_comb begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0000;  // Add
            2'b01: ALUControl = 4'b0001;  // Subtract
            2'b11: ALUControl = 4'b0100;  //lui
            default: case(funct3)
                3'b000: if (RtypeSub)
                    ALUControl = 4'b0001;  // sub
                else
                    ALUControl = 4'b0000;  // add/addi
                3'b010: ALUControl = 4'b0101;  // slt/slti
                3'b110: ALUControl = 4'b0011;  // or/ori
                3'b111: ALUControl = 4'b0010;  // and/andi
                3'b100: ALUControl = 4'b0110;  // xor/xori
                3'b001: ALUControl = 4'b0111;  // sll/slli 
                3'b101: begin  // srl/srli or sra/srai
                    if (funct7[5])  // Check bit 30 of instruction
                        ALUControl = 4'b1001;  // sra/srai 
                    else
                        ALUControl = 4'b1000;  // srl/srli 
                end
                default: ALUControl = 4'bxxxx; // i think this avoids latches
            endcase
        endcase
    end
endmodule

module ALU (
    input logic [3:0] ALUControl,
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    output logic zero, lt_zero,
    output logic [31:0] ALUResult
);
    always_comb begin
        case (ALUControl)
            4'b0000: ALUResult = SrcA + SrcB;  // add
            4'b0001: ALUResult = SrcA - SrcB;  // subtract
            4'b0010: ALUResult = SrcA & SrcB;  // and
            4'b0011: ALUResult = SrcA | SrcB;  // or
            4'b0100: ALUResult = SrcB;  // lui
            4'b0101: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 1 : 0;  // slt
            4'b0110: ALUResult = SrcA ^ SrcB;  // xor
            4'b0111: ALUResult = SrcA << SrcB[4:0];  // sll/sll
            4'b1000: ALUResult = SrcA >> SrcB[4:0];  // srl/srli
            4'b1001: ALUResult = $signed(SrcA) >>> SrcB[4:0]; // check syntax
            default: ALUResult = 0;
        endcase
        zero = (ALUResult == 32'd0);
        lt_zero = ALUResult[31];
    end
endmodule

module mux_AdrSrc (
    input logic AdrSrc,
    input logic [31:0] pc,
    input logic [31:0] Result,
    output logic [31:0] Adr
);
    always_comb begin
        if (AdrSrc) Adr = Result;
        else Adr = pc;
    end
endmodule

module mux_3input (
    input logic [31:0] input00, input01, input10,
    input logic [1:0] Src,
    output logic [31:0] output_data
);
    always_comb begin
        case (Src)
            2'b00: output_data = input00;
            2'b01: output_data = input01;
            2'b10: output_data = input10;
            default: output_data = 32'b0;
        endcase
    end
endmodule

module ff_register (
    input logic clk,
    input logic reset,
    input logic [31:0] input_data,
    output logic [31:0] output_data
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) output_data <= 0;
        else output_data <= input_data;
    end
endmodule

module ff_en_register #(
    parameter [31:0] INIT_VALUE = 32'd0
)(
    input logic clk,
    input logic reset,
    input logic enable,
    input logic [31:0] input_data,
    output logic [31:0] output_data
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) output_data <= INIT_VALUE;
        else if (enable) output_data <= input_data;
    end
endmodule