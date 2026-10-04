// ============================================================
// PROGRAM COUNTER
// ============================================================
module Program_Counter(
    input clk,
    input reset,
    input [31:0] PC_in,
    output reg [31:0] PC_out
);

always @(posedge clk or posedge reset) begin
    if (reset)
        PC_out <= 32'b0;
    else
        PC_out <= PC_in;
end

endmodule


// ============================================================
// PC + 4 ADDER
// ============================================================
module PCpuls4(
    input [31:0] fromPC,
    output [31:0] NextoPC
);

assign NextoPC = fromPC + 32'd4;

endmodule


// ============================================================
// INSTRUCTION MEMORY
// ============================================================
// 64 words x 32 bits
//
// PC is a BYTE address:
// 0, 4, 8, 12, ...
//
// [7:2] converts byte address to word index:
// 0 -> 0
// 4 -> 1
// 8 -> 2
// 12 -> 3
// ============================================================
module Instruction_Memory(
    input clk,
    input reset,
    input [31:0] read_address,
    output [31:0] instruction_out
);

integer k;

reg [31:0] I_Mem [0:63];


// Reset only clears memory.
// Instruction reading is combinational.
always @(posedge reset) begin
    for (k = 0; k < 64; k = k + 1)
        I_Mem[k] <= 32'b0;
end


assign instruction_out = I_Mem[read_address[7:2]];

endmodule


// ============================================================
// REGISTER FILE
// ============================================================
// 32 registers x 32 bits
//
// x0 is always zero.
// ============================================================
module Reg_File(
    input clk,
    input reset,
    input RegWrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);

integer k;

reg [31:0] Registers [0:31];


// Reset registers
always @(posedge reset) begin
    for (k = 0; k < 32; k = k + 1)
        Registers[k] <= 32'b0;
end


// Register write
always @(posedge clk) begin
    if (RegWrite && (rd != 5'b00000))
        Registers[rd] <= write_data;
end


// Register reads
assign read_data1 = (rs1 == 5'b00000) ? 32'b0 : Registers[rs1];

assign read_data2 = (rs2 == 5'b00000) ? 32'b0 : Registers[rs2];

endmodule


// ============================================================
// IMMEDIATE GENERATOR
// ============================================================
// Supports:
// I-type  : LOAD and ADDI
// S-type  : STORE
// B-type  : BRANCH
// ============================================================
module ImmGen(
    input [6:0] Opcode,
    input [31:0] instruction,
    output reg [31:0] ImmExt
);

always @(*) begin

    ImmExt = 32'b0;

    case (Opcode)

        // I-type
        // LW and ADDI
        7'b0000011,
        7'b0010011: begin

            ImmExt = {{20{instruction[31]}},
                      instruction[31:20]};

        end


        // S-type
        // SW
        7'b0100011: begin

            ImmExt = {{20{instruction[31]}},
                      instruction[31:25],
                      instruction[11:7]};

        end


        // B-type
        // BEQ
        7'b1100011: begin

            ImmExt = {{19{instruction[31]}},
                      instruction[31],
                      instruction[30:25],
                      instruction[11:8],
                      1'b0};

        end


        default: begin

            ImmExt = 32'b0;

        end

    endcase

end

endmodule


// ============================================================
// CONTROL UNIT
// ============================================================
// Supported instructions:
//
// R-type : ADD, SUB, AND, OR
// I-type : ADDI
// Load   : LW
// Store  : SW
// Branch : BEQ
// ============================================================
module Control_Unit(
    input [6:0] instruction,
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,
    output reg [1:0] ALUOp
);

always @(*) begin

    // Default values
    Branch   = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    ALUSrc   = 1'b0;
    RegWrite = 1'b0;
    ALUOp    = 2'b00;


    case (instruction)

        // ====================================================
        // R-TYPE
        // ADD / SUB / AND / OR
        // ====================================================
        7'b0110011: begin

            ALUSrc   = 1'b0;
            MemtoReg = 1'b0;
            RegWrite = 1'b1;
            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;
            ALUOp    = 2'b10;

        end


        // ====================================================
        // LOAD
        // LW
        // ====================================================
        7'b0000011: begin

            ALUSrc   = 1'b1;
            MemtoReg = 1'b1;
            RegWrite = 1'b1;
            MemRead  = 1'b1;
            MemWrite = 1'b0;
            Branch   = 1'b0;
            ALUOp    = 2'b00;

        end


        // ====================================================
        // STORE
        // SW
        // ====================================================
        7'b0100011: begin

            ALUSrc   = 1'b1;
            MemtoReg = 1'b0;
            RegWrite = 1'b0;
            MemRead  = 1'b0;
            MemWrite = 1'b1;
            Branch   = 1'b0;
            ALUOp    = 2'b00;

        end


        // ====================================================
        // BRANCH
        // BEQ
        // ====================================================
        7'b1100011: begin

            ALUSrc   = 1'b0;
            MemtoReg = 1'b0;
            RegWrite = 1'b0;
            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b1;
            ALUOp    = 2'b01;

        end


        // ====================================================
        // I-TYPE ALU
        // ADDI
        // ====================================================
        7'b0010011: begin

            ALUSrc   = 1'b1;
            MemtoReg = 1'b0;
            RegWrite = 1'b1;
            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;
            ALUOp    = 2'b00;

        end


        default: begin

            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            ALUSrc   = 1'b0;
            RegWrite = 1'b0;
            ALUOp    = 2'b00;

        end

    endcase

end

endmodule


// ============================================================
// ALU
// ============================================================
// Control:
// 0000 = AND
// 0001 = OR
// 0010 = ADD
// 0110 = SUB
// ============================================================
module ALU_unit(
    input [31:0] A,
    input [31:0] B,
    input [3:0] Control_in,
    output reg [31:0] ALU_result,
    output reg zero
);

always @(*) begin

    ALU_result = 32'b0;
    zero = 1'b0;

    case (Control_in)

        // AND
        4'b0000: begin

            ALU_result = A & B;

        end


        // OR
        4'b0001: begin

            ALU_result = A | B;

        end


        // ADD
        4'b0010: begin

            ALU_result = A + B;

        end


        // SUB
        4'b0110: begin

            ALU_result = A - B;

            if (A == B)
                zero = 1'b1;
            else
                zero = 1'b0;

        end


        default: begin

            ALU_result = 32'b0;
            zero = 1'b0;

        end

    endcase

end

endmodule


// ============================================================
// ALU CONTROL
// ============================================================
// ALUOp:
//
// 00 = ADD
// 01 = SUB (branch)
// 10 = R-type
//
// R-type funct3/funct7:
//
// ADD = funct7=0, funct3=000
// SUB = funct7=1, funct3=000
// AND = funct7=0, funct3=111
// OR  = funct7=0, funct3=110
// ============================================================
module ALU_Control(
    input [1:0] ALUOp,
    input [2:0] funct3,
    input funct7,
    output reg [3:0] Control_out
);

always @(*) begin

    // Default = ADD
    Control_out = 4'b0010;

    case (ALUOp)

        // ====================================================
        // LOAD / STORE / ADDI
        // ====================================================
        2'b00: begin

            Control_out = 4'b0010;

        end


        // ====================================================
        // BRANCH
        // ====================================================
        2'b01: begin

            Control_out = 4'b0110;

        end


        // ====================================================
        // R-TYPE
        // ====================================================
        2'b10: begin

            case (funct3)

                // ADD / SUB
                3'b000: begin

                    if (funct7 == 1'b1)
                        Control_out = 4'b0110;
                    else
                        Control_out = 4'b0010;

                end


                // AND
                3'b111: begin

                    Control_out = 4'b0000;

                end


                // OR
                3'b110: begin

                    Control_out = 4'b0001;

                end


                default: begin

                    Control_out = 4'b0010;

                end

            endcase

        end


        default: begin

            Control_out = 4'b0010;

        end

    endcase

end

endmodule


// ============================================================
// DATA MEMORY
// ============================================================
// 64 words x 32 bits
// ============================================================
module Data_Memory(
    input clk,
    input reset,
    input MemRead,
    input MemWrite,
    input [31:0] read_address,
    input [31:0] write_data,
    output [31:0] Mem_data_out
);

integer k;

reg [31:0] D_Memory [0:63];


// Reset memory
always @(posedge reset) begin

    for (k = 0; k < 64; k = k + 1)
        D_Memory[k] <= 32'b0;

end


// Store
always @(posedge clk) begin

    if (MemWrite)
        D_Memory[read_address[7:2]] <= write_data;

end


// Load
assign Mem_data_out =
    (MemRead) ? D_Memory[read_address[7:2]] : 32'b0;

endmodule


// ============================================================
// MUX 1
// ============================================================
module Mux1(
    input sel1,
    input [31:0] A1,
    input [31:0] B1,
    output [31:0] Mux1_out
);

assign Mux1_out =
    (sel1 == 1'b0) ? A1 : B1;

endmodule


// ============================================================
// MUX 2
// ============================================================
module Mux2(
    input sel2,
    input [31:0] A2,
    input [31:0] B2,
    output [31:0] Mux2_out
);

assign Mux2_out =
    (sel2 == 1'b0) ? A2 : B2;

endmodule


// ============================================================
// MUX 3
// ============================================================
module Mux3(
    input sel3,
    input [31:0] A3,
    input [31:0] B3,
    output [31:0] Mux3_out
);

assign Mux3_out =
    (sel3 == 1'b0) ? A3 : B3;

endmodule


// ============================================================
// AND GATE
// ============================================================
module AND_Gate(
    input branch,
    input zero,
    output and_out
);

assign and_out = branch & zero;

endmodule


// ============================================================
// ADDER
// ============================================================
module Adder(
    input [31:0] in_1,
    input [31:0] in_2,
    output [31:0] sum_out
);

assign sum_out = in_1 + in_2;

endmodule


// ============================================================
// TOP LEVEL
// ============================================================
module Top_Level(
    input clk,
    input reset
);

wire [31:0] PC_top;
wire [31:0] instruction_top;

wire [31:0] rd1_top;
wire [31:0] rd2_top;

wire [31:0] ImmExt_top;

wire [31:0] mux1_top;

wire [31:0] sum_out_top;
wire [31:0] NextoPC_top;
wire [31:0] PCin_top;

wire [31:0] address_top;

wire [31:0] Memdata_top;

wire [31:0] WriteBack_top;

wire RegWrite_top;
wire ALUSrc_top;

wire zero_top;
wire branch_top;
wire sel2_top;

wire MemtoReg_top;
wire MemWrite_top;
wire MemRead_top;

wire [1:0] ALUOp_top;

wire [3:0] control_top;


// ============================================================
// PROGRAM COUNTER
// ============================================================
Program_Counter PC(
    .clk(clk),
    .reset(reset),
    .PC_in(PCin_top),
    .PC_out(PC_top)
);


// ============================================================
// PC + 4
// ============================================================
PCpuls4 PC_Adder(
    .fromPC(PC_top),
    .NextoPC(NextoPC_top)
);


// ============================================================
// INSTRUCTION MEMORY
// ============================================================
Instruction_Memory Inst_Memory(
    .clk(clk),
    .reset(reset),
    .read_address(PC_top),
    .instruction_out(instruction_top)
);


// ============================================================
// REGISTER FILE
// ============================================================
Reg_File Reg_File(
    .clk(clk),
    .reset(reset),
    .RegWrite(RegWrite_top),
    .rs1(instruction_top[19:15]),
    .rs2(instruction_top[24:20]),
    .rd(instruction_top[11:7]),
    .write_data(WriteBack_top),
    .read_data1(rd1_top),
    .read_data2(rd2_top)
);


// ============================================================
// IMMEDIATE GENERATOR
// ============================================================
ImmGen Imm_Gen(
    .Opcode(instruction_top[6:0]),
    .instruction(instruction_top),
    .ImmExt(ImmExt_top)
);


// ============================================================
// CONTROL UNIT
// ============================================================
Control_Unit Control_Unit(
    .instruction(instruction_top[6:0]),
    .Branch(branch_top),
    .MemRead(MemRead_top),
    .MemtoReg(MemtoReg_top),
    .ALUOp(ALUOp_top),
    .MemWrite(MemWrite_top),
    .ALUSrc(ALUSrc_top),
    .RegWrite(RegWrite_top)
);


// ============================================================
// ALU CONTROL
// ============================================================
ALU_Control ALU_Control(
    .ALUOp(ALUOp_top),
    .funct3(instruction_top[14:12]),
    .funct7(instruction_top[30]),
    .Control_out(control_top)
);


// ============================================================
// ALU
// ============================================================
ALU_unit ALU(
    .A(rd1_top),
    .B(mux1_top),
    .Control_in(control_top),
    .ALU_result(address_top),
    .zero(zero_top)
);


// ============================================================
// ALU INPUT MUX
// ============================================================
Mux1 ALU_MUX(
    .sel1(ALUSrc_top),
    .A1(rd2_top),
    .B1(ImmExt_top),
    .Mux1_out(mux1_top)
);


// ============================================================
// BRANCH TARGET ADDER
// ============================================================
Adder Branch_Adder(
    .in_1(PC_top),
    .in_2(ImmExt_top),
    .sum_out(sum_out_top)
);


// ============================================================
// BRANCH AND ZERO
// ============================================================
AND_Gate AND(
    .branch(branch_top),
    .zero(zero_top),
    .and_out(sel2_top)
);


// ============================================================
// PC MUX
// ============================================================
Mux2 PC_Mux(
    .sel2(sel2_top),
    .A2(NextoPC_top),
    .B2(sum_out_top),
    .Mux2_out(PCin_top)
);


// ============================================================
// DATA MEMORY
// ============================================================
Data_Memory Data_Mem(
    .clk(clk),
    .reset(reset),
    .MemRead(MemRead_top),
    .MemWrite(MemWrite_top),
    .read_address(address_top),
    .write_data(rd2_top),
    .Mem_data_out(Memdata_top)
);


// ============================================================
// WRITEBACK MUX
// ============================================================
Mux3 Memory_mux(
    .sel3(MemtoReg_top),
    .A3(address_top),
    .B3(Memdata_top),
    .Mux3_out(WriteBack_top)
);

endmodule