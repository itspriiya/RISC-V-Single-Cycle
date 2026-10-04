// ============================================================
// RISC-V SINGLE-CYCLE PROCESSOR
// COMPREHENSIVE TESTBENCH
// ============================================================

module tb_top;

reg clk;
reg reset;


// ============================================================
// DUT
// ============================================================

Top_Level uut(
    .clk(clk),
    .reset(reset)
);


// ============================================================
// CLOCK
// ============================================================

always begin
    #5 clk = ~clk;
end


// ============================================================
// INSTRUCTION MEMORY
// ============================================================

initial begin

    clk   = 1'b0;
    reset = 1'b1;

    // Hold reset
    #10;
    reset = 1'b0;


    // --------------------------------------------------------
    // ADDI x1, x0, 10
    // x1 = 10
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[0] =
        32'b00000000101000000000000010010011;


    // --------------------------------------------------------
    // ADDI x2, x0, 20
    // x2 = 20
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[1] =
        32'b00000001010000000000000100010011;


    // --------------------------------------------------------
    // ADD x3, x1, x2
    // x3 = 10 + 20 = 30
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[2] =
        32'b00000000001000001000000110110011;


    // --------------------------------------------------------
    // SUB x4, x3, x1
    // x4 = 30 - 10 = 20
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[3] =
        32'b01000000000100011000001000110011;


    // --------------------------------------------------------
    // AND x5, x3, x2
    // x5 = 30 AND 20 = 20
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[4] =
        32'b00000000001000011111001010110011;


    // --------------------------------------------------------
    // OR x6, x3, x2
    // x6 = 30 OR 20 = 30
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[5] =
        32'b00000000001000011110001100110011;


    // --------------------------------------------------------
    // SW x6, 0(x0)
    // Memory[0] = 30
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[6] =
        32'b00000000011000000010000000100011;


    // --------------------------------------------------------
    // LW x7, 0(x0)
    // x7 = Memory[0] = 30
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[7] =
        32'b00000000000000000010001110000011;


    // --------------------------------------------------------
    // BEQ x6, x7, +8
    //
    // x6 = 30
    // x7 = 30
    //
    // Branch is TAKEN.
    // PC jumps from 32 to 40.
    // This skips instruction at address 36.
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[8] =
        32'b00000000011100110000010001100011;


    // --------------------------------------------------------
    // ADDI x9, x0, 55
    //
    // This instruction should be SKIPPED by BEQ.
    // Therefore x9 must remain 0.
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[9] =
        32'b00000011011100000000010010010011;


    // --------------------------------------------------------
    // ADDI x8, x0, 99
    //
    // Branch target.
    // --------------------------------------------------------

    uut.Inst_Memory.I_Mem[10] =
        32'b00000110001100000000010000010011;


    // Keep x0 explicitly zero
    uut.Reg_File.Registers[0] = 32'd0;


    // --------------------------------------------------------
    // Run simulation
    // --------------------------------------------------------

    #150;


    // ========================================================
    // SELF-CHECKING
    // ========================================================

    $display("");
    $display("==============================================");
    $display(" RISC-V SINGLE-CYCLE PROCESSOR TEST");
    $display("==============================================");


    // ADDI
    if (uut.Reg_File.Registers[1] === 32'd10)
        $display("PASS: ADDI  x1 = 10");
    else
        $display("FAIL: ADDI  x1 = %0d", uut.Reg_File.Registers[1]);


    // ADDI
    if (uut.Reg_File.Registers[2] === 32'd20)
        $display("PASS: ADDI  x2 = 20");
    else
        $display("FAIL: ADDI  x2 = %0d", uut.Reg_File.Registers[2]);


    // ADD
    if (uut.Reg_File.Registers[3] === 32'd30)
        $display("PASS: ADD   x3 = 30");
    else
        $display("FAIL: ADD   x3 = %0d", uut.Reg_File.Registers[3]);


    // SUB
    if (uut.Reg_File.Registers[4] === 32'd20)
        $display("PASS: SUB   x4 = 20");
    else
        $display("FAIL: SUB   x4 = %0d", uut.Reg_File.Registers[4]);


    // AND
    if (uut.Reg_File.Registers[5] === 32'd20)
        $display("PASS: AND   x5 = 20");
    else
        $display("FAIL: AND   x5 = %0d", uut.Reg_File.Registers[5]);


    // OR
    if (uut.Reg_File.Registers[6] === 32'd30)
        $display("PASS: OR    x6 = 30");
    else
        $display("FAIL: OR    x6 = %0d", uut.Reg_File.Registers[6]);


    // SW
    if (uut.Data_Mem.D_Memory[0] === 32'd30)
        $display("PASS: SW    Memory[0] = 30");
    else
        $display("FAIL: SW    Memory[0] = %0d",
                 uut.Data_Mem.D_Memory[0]);


    // LW
    if (uut.Reg_File.Registers[7] === 32'd30)
        $display("PASS: LW    x7 = 30");
    else
        $display("FAIL: LW    x7 = %0d",
                 uut.Reg_File.Registers[7]);


    // BEQ
    // x9 should remain 0 because instruction at PC=36 was skipped.
    if (uut.Reg_File.Registers[9] === 32'd0)
        $display("PASS: BEQ   branch taken");
    else
        $display("FAIL: BEQ   branch NOT taken");


    // Branch target
    if (uut.Reg_File.Registers[8] === 32'd99)
        $display("PASS: BEQ   branch target reached");
    else
        $display("FAIL: BEQ   branch target not reached");


    $display("==============================================");
    $display(" TEST COMPLETE");
    $display("==============================================");
    $display("");

    $finish;

end


// ============================================================
// WAVEFORM DUMP
// ============================================================

initial begin

    $dumpfile("riscv.vcd");

    $dumpvars(0, tb_top);

end

endmodule