module ALU(
        input logic [31:0] SrcA,
        input logic [31:0] SrcB,
        input logic [3:0] ALUcontrol,
        output logic [31:0] ALUresult,
        output logic zero
    );

    logic [4:0] bits; //this will help me prevent bit slicing
    logic [63:0] temp_result; //temporary result for certain signed operations
    assign bits = SrcB[4:0];

    always_comb begin
        temp_result = 64'd0;
        case(ALUcontrol)
            4'b0000:begin //ADD
                zero = 0;
                ALUresult = SrcA + SrcB; 
            end

            4'b0001:begin //SUB
                zero = 0; 
                ALUresult = SrcA - SrcB;
            end

            4'b0010:begin //AND
                zero = 0;
                ALUresult = SrcA & SrcB;
            end

            4'b0011:begin //OR
                zero = 0;
                ALUresult = SrcA | SrcB;
            end

            4'b0100:begin //XOR
                zero = 0;
                ALUresult = SrcA ^ SrcB;
            end

            4'b0101:begin //SLL
                zero = 0;
                ALUresult = SrcA << bits;
            end

            4'b0110:begin //SRL
                zero = 0;
                ALUresult = SrcA >> bits;
            end

            4'b0111:begin //Shift Right
                zero = 0;
                ALUresult = $signed(SrcA) >>> bits;
            end

            4'b1000:begin //Set Less Than
                zero = 0;
                ALUresult = ($signed(SrcA) < $signed(SrcB)) ? 32'd1 : 32'd0;
            end
            4'b1001:begin //Set Less Than Unsigned
                zero = 0;
                ALUresult = (SrcA < SrcB) ? 32'd1 : 32'd0;
            end

            4'b1010: begin //MUL
                zero = 0;
                temp_result = SrcA * SrcB;
                ALUresult = temp_result[31:0];
            end

            4'b1011: begin //MULH
                zero = 0;
                temp_result = $signed({{32{SrcA[31]}}, SrcA}) * $signed({{32{SrcB[31]}}, SrcB});
                ALUresult = temp_result[63:32];
            end

            4'b1100: begin //MULHSU
                zero = 0;
                temp_result = $signed({{32{SrcA[31]}}, SrcA}) * $signed({32'd0, SrcB});
                ALUresult = temp_result[63:32];
            end

            4'b1101: begin //MULHU
                zero = 0;
                temp_result = {32'd0, SrcA} * {32'd0, SrcB};
                ALUresult = temp_result[63:32];
            end

            4'b1110: begin //DIV 
                zero = 0;
                if (SrcB == 32'd0) begin
                    ALUresult = 32'hFFFFFFFF; // Division by zero
                end else if (SrcA == 32'h80000000 && SrcB == 32'hFFFFFFFF) begin
                    ALUresult = 32'h80000000; // Overflow
                end else begin
                    ALUresult = ($signed(SrcA) / $signed(SrcB));
                end
            end

            4'b1111: begin //DIVU
                zero = 0;
                if (SrcB == 32'd0) begin
                    ALUresult = 32'hFFFFFFFF; // Division by zero
                end else begin
                    ALUresult = (SrcA / SrcB);
                end
            end
             
            default:begin
                zero = 0;
                ALUresult = 32'd0;
            end
       endcase

       zero = (ALUresult == 32'd0);
    end
endmodule