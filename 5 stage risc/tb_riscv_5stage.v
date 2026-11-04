`timescale 1ns/1ps

module tb_riscv_5stage;

    reg clk;
    reg reset;

    integer i;
    integer errors;

    // ============================================
    // DUT: DEVICE UNDER TEST
    // ============================================

    riscv_5stage dut (
        .clk   (clk),
        .reset (reset)
    );

    // ============================================
    // CLOCK GENERATION
    // 10 ns clock period
    // ============================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================
    // TEST PROGRAM AND RESET
    // ============================================

    initial begin

        reset = 1;
        errors = 0;

        // Initialize instruction memory with NOP
        for (i = 0; i < 256; i = i + 1)
            dut.instr_mem[i] = 32'h00000013;

        // Initialize data memory
        for (i = 0; i < 256; i = i + 1)
            dut.data_mem[i] = 32'b0;

        // ========================================
        // RISC-V TEST INSTRUCTIONS
        // ========================================

        // 1. ADDI x1, x0, 5
        // x1 = 5
        dut.instr_mem[0] = 32'h00500093;

        // 2. ADDI x2, x0, 10
        // x2 = 10
        dut.instr_mem[1] = 32'h00A00113;

        // 3. ADD x3, x1, x2
        // x3 = 5 + 10 = 15
        dut.instr_mem[2] = 32'h002081B3;

        // 4. SUB x4, x2, x1
        // x4 = 10 - 5 = 5
        dut.instr_mem[3] = 32'h40110233;

        // 5. SW x3, 0(x0)
        // Memory[0] = 15
        dut.instr_mem[4] = 32'h00302023;

        // 6. LW x5, 0(x0)
        // x5 = Memory[0] = 15
        dut.instr_mem[5] = 32'h00002283;

        // 7. ADDI x6, x5, 1
        // x6 = 16
        // Tests load-use hazard
        dut.instr_mem[6] = 32'h00128313;

        // 8. ADDI x7, x0, 15
        // x7 = 15
        dut.instr_mem[7] = 32'h00F00393;

        // 9. BEQ x3, x7, +8
        // x3 == x7, branch taken
        dut.instr_mem[8] = 32'h00718463;

        // 10. ADDI x8, x0, 99
        // Must be flushed because branch is taken
        dut.instr_mem[9] = 32'h06300413;

        // 11. ADDI x9, x0, 7
        // Branch target
        dut.instr_mem[10] = 32'h00700493;

        // ========================================
        // APPLY RESET
        // ========================================

        repeat (3) @(negedge clk);
        reset = 0;

        // Allow the processor to execute
        repeat (35) @(posedge clk);

        // Wait for nonblocking assignments
        #1;

        // ========================================
        // DISPLAY REGISTER RESULTS
        // ========================================

        $display("");
        $display("========================================");
        $display("  5-STAGE RISC-V PROCESSOR TEST RESULTS");
        $display("========================================");

        $display("Register x0 = %0d", dut.regfile[0]);
        $display("Register x1 = %0d", dut.regfile[1]);
        $display("Register x2 = %0d", dut.regfile[2]);
        $display("Register x3 = %0d", dut.regfile[3]);
        $display("Register x4 = %0d", dut.regfile[4]);
        $display("Register x5 = %0d", dut.regfile[5]);
        $display("Register x6 = %0d", dut.regfile[6]);
        $display("Register x7 = %0d", dut.regfile[7]);
        $display("Register x8 = %0d", dut.regfile[8]);
        $display("Register x9 = %0d", dut.regfile[9]);

        $display("Data Memory[0] = %0d", dut.data_mem[0]);

        // ========================================
        // AUTOMATIC VERIFICATION
        // ========================================

        if (dut.regfile[0] !== 0) begin
            $display("ERROR: x0 is not zero");
            errors = errors + 1;
        end

        if (dut.regfile[1] !== 5) begin
            $display("ERROR: x1 expected 5");
            errors = errors + 1;
        end

        if (dut.regfile[2] !== 10) begin
            $display("ERROR: x2 expected 10");
            errors = errors + 1;
        end

        if (dut.regfile[3] !== 15) begin
            $display("ERROR: x3 expected 15");
            errors = errors + 1;
        end

        if (dut.regfile[4] !== 5) begin
            $display("ERROR: x4 expected 5");
            errors = errors + 1;
        end

        if (dut.regfile[5] !== 15) begin
            $display("ERROR: x5 expected 15");
            errors = errors + 1;
        end

        if (dut.regfile[6] !== 16) begin
            $display("ERROR: x6 expected 16");
            errors = errors + 1;
        end

        if (dut.regfile[7] !== 15) begin
            $display("ERROR: x7 expected 15");
            errors = errors + 1;
        end

        if (dut.regfile[8] !== 0) begin
            $display("ERROR: x8 should be flushed");
            errors = errors + 1;
        end

        if (dut.regfile[9] !== 7) begin
            $display("ERROR: x9 expected 7");
            errors = errors + 1;
        end

        if (dut.data_mem[0] !== 15) begin
            $display("ERROR: Memory[0] expected 15");
            errors = errors + 1;
        end

        // ========================================
        // FINAL STATUS
        // ========================================

        $display("----------------------------------------");

        if (errors == 0)
            $display("       ALL TESTS PASSED!");
        else
            $display("       TEST FAILED: %0d errors", errors);

        $display("========================================");

        $finish;

    end

    // ============================================
    // WAVEFORM GENERATION
    // ============================================

    initial begin

        $dumpfile("riscv_5stage.vcd");
        $dumpvars(0, tb_riscv_5stage);

    end

endmodule