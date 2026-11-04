`timescale 1ns/1ps

module riscv_5stage (
    input wire clk,
    input wire reset
);

    // =====================================================
    // 1. INSTRUCTION MEMORY AND DATA MEMORY
    // =====================================================

    reg [31:0] instr_mem [0:255];
    reg [31:0] data_mem  [0:255];

    // Register file: 32 registers, each 32 bits
    reg [31:0] regfile [0:31];

    // =====================================================
    // 2. PROGRAM COUNTER - IF STAGE
    // =====================================================

    reg [31:0] PC;

    wire [31:0] instruction;
    assign instruction = instr_mem[PC[9:2]];

    // =====================================================
    // 3. IF/ID PIPELINE REGISTER
    // =====================================================

    reg [31:0] IF_ID_PC;
    reg [31:0] IF_ID_instr;

    // =====================================================
    // 4. ID STAGE - INSTRUCTION DECODING
    // =====================================================

    wire [6:0] opcode = IF_ID_instr[6:0];
    wire [4:0] rd     = IF_ID_instr[11:7];
    wire [2:0] funct3 = IF_ID_instr[14:12];
    wire [4:0] rs1    = IF_ID_instr[19:15];
    wire [4:0] rs2    = IF_ID_instr[24:20];
    wire [6:0] funct7 = IF_ID_instr[31:25];

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // =====================================================
    // WRITE BACK SIGNALS
    // =====================================================

    reg [31:0] MEM_WB_mem_data;
    reg [31:0] MEM_WB_alu_result;
    reg [4:0]  MEM_WB_rd;

    reg MEM_WB_reg_write;
    reg MEM_WB_mem_to_reg;

    wire [31:0] wb_data =
        MEM_WB_mem_to_reg ?
        MEM_WB_mem_data : MEM_WB_alu_result;

    // Register file read with WB bypass
    assign read_data1 =
        (MEM_WB_reg_write && MEM_WB_rd != 0 &&
         MEM_WB_rd == rs1) ?
         wb_data : regfile[rs1];

    assign read_data2 =
        (MEM_WB_reg_write && MEM_WB_rd != 0 &&
         MEM_WB_rd == rs2) ?
         wb_data : regfile[rs2];

    // =====================================================
    // 5. IMMEDIATE GENERATOR
    // =====================================================

    reg [31:0] immediate;

    always @(*) begin

        case (opcode)

            // I-type: ADDI, LW
            7'b0010011,
            7'b0000011:
                immediate =
                    {{20{IF_ID_instr[31]}},
                      IF_ID_instr[31:20]};

            // S-type: SW
            7'b0100011:
                immediate =
                    {{20{IF_ID_instr[31]}},
                      IF_ID_instr[31:25],
                      IF_ID_instr[11:7]};

            // B-type: BEQ
            7'b1100011:
                immediate =
                    {{19{IF_ID_instr[31]}},
                      IF_ID_instr[31],
                      IF_ID_instr[7],
                      IF_ID_instr[30:25],
                      IF_ID_instr[11:8],
                      1'b0};

            default:
                immediate = 32'b0;

        endcase

    end

    // =====================================================
    // 6. CONTROL UNIT
    // =====================================================

    reg reg_write;
    reg mem_read;
    reg mem_write;
    reg mem_to_reg;
    reg alu_src;
    reg branch;

    always @(*) begin

        reg_write  = 0;
        mem_read   = 0;
        mem_write  = 0;
        mem_to_reg = 0;
        alu_src    = 0;
        branch     = 0;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                reg_write = 1;
            end

            // ADDI
            7'b0010011: begin
                reg_write = 1;
                alu_src = 1;
            end

            // LW
            7'b0000011: begin
                reg_write = 1;
                mem_read = 1;
                mem_to_reg = 1;
                alu_src = 1;
            end

            // SW
            7'b0100011: begin
                mem_write = 1;
                alu_src = 1;
            end

            // BEQ
            7'b1100011: begin
                branch = 1;
            end

        endcase

    end

    // =====================================================
    // 7. HAZARD DETECTION UNIT
    // =====================================================

    reg stall;

    reg ID_EX_mem_read;
    reg [4:0] ID_EX_rd;

    wire uses_rs1 =
        (opcode == 7'b0110011) ||
        (opcode == 7'b0010011) ||
        (opcode == 7'b0000011) ||
        (opcode == 7'b0100011) ||
        (opcode == 7'b1100011);

    wire uses_rs2 =
        (opcode == 7'b0110011) ||
        (opcode == 7'b0100011) ||
        (opcode == 7'b1100011);

    always @(*) begin

        stall = 0;

        if (ID_EX_mem_read && ID_EX_rd != 0 &&
            ((uses_rs1 && ID_EX_rd == rs1) ||
             (uses_rs2 && ID_EX_rd == rs2)))
            stall = 1;

    end

    // =====================================================
    // 8. ID/EX PIPELINE REGISTER
    // =====================================================

    reg [31:0] ID_EX_PC;
    reg [31:0] ID_EX_reg1;
    reg [31:0] ID_EX_reg2;
    reg [31:0] ID_EX_imm;

    reg [4:0] ID_EX_rs1;
    reg [4:0] ID_EX_rs2;

    reg [6:0] ID_EX_opcode;
    reg [2:0] ID_EX_funct3;
    reg [6:0] ID_EX_funct7;

    reg ID_EX_reg_write;
    reg ID_EX_mem_write;
    reg ID_EX_mem_to_reg;
    reg ID_EX_alu_src;
    reg ID_EX_branch;

    // =====================================================
    // 9. EX STAGE - FORWARDING UNIT
    // =====================================================

    reg [31:0] forwardA;
    reg [31:0] forwardB;

    // EX/MEM pipeline register
    reg [31:0] EX_MEM_alu_result;
    reg [31:0] EX_MEM_write_data;
    reg [4:0] EX_MEM_rd;

    reg EX_MEM_reg_write;
    reg EX_MEM_mem_read;
    reg EX_MEM_mem_write;
    reg EX_MEM_mem_to_reg;

    // =====================================================
    // FORWARDING
    // =====================================================

    always @(*) begin

        forwardA = ID_EX_reg1;
        forwardB = ID_EX_reg2;

        // Forward from EX/MEM
        if (EX_MEM_reg_write &&
            EX_MEM_rd != 0 &&
            EX_MEM_rd == ID_EX_rs1 &&
            !EX_MEM_mem_read)
            forwardA = EX_MEM_alu_result;

        else if (MEM_WB_reg_write &&
                 MEM_WB_rd != 0 &&
                 MEM_WB_rd == ID_EX_rs1)
            forwardA = wb_data;

        if (EX_MEM_reg_write &&
            EX_MEM_rd != 0 &&
            EX_MEM_rd == ID_EX_rs2 &&
            !EX_MEM_mem_read)
            forwardB = EX_MEM_alu_result;

        else if (MEM_WB_reg_write &&
                 MEM_WB_rd != 0 &&
                 MEM_WB_rd == ID_EX_rs2)
            forwardB = wb_data;

    end

    // =====================================================
    // 10. ALU
    // =====================================================

    reg [31:0] alu_result;
    reg [31:0] alu_input2;

    always @(*) begin

        alu_input2 =
            ID_EX_alu_src ? ID_EX_imm : forwardB;

        case (ID_EX_opcode)

            // R-type
            7'b0110011: begin

                case ({ID_EX_funct7, ID_EX_funct3})

                    {7'b0000000,3'b000}:
                        alu_result = forwardA + alu_input2;

                    {7'b0100000,3'b000}:
                        alu_result = forwardA - alu_input2;

                    {7'b0000000,3'b111}:
                        alu_result = forwardA & alu_input2;

                    {7'b0000000,3'b110}:
                        alu_result = forwardA | alu_input2;

                    {7'b0000000,3'b100}:
                        alu_result = forwardA ^ alu_input2;

                    default:
                        alu_result = 0;

                endcase

            end

            // ADDI, LW, SW
            7'b0010011,
            7'b0000011,
            7'b0100011:
                alu_result = forwardA + alu_input2;

            // BEQ subtraction
            7'b1100011:
                alu_result = forwardA - forwardB;

            default:
                alu_result = 0;

        endcase

    end

    // =====================================================
    // 11. BRANCH UNIT
    // =====================================================

    wire branch_taken =
        ID_EX_branch && (forwardA == forwardB);

    wire [31:0] branch_target =
        ID_EX_PC + ID_EX_imm;

    // =====================================================
    // 12. MEMORY STAGE
    // =====================================================

    wire [31:0] memory_read_data =
        data_mem[EX_MEM_alu_result[9:2]];

    // =====================================================
    // 13. WRITE BACK STAGE
    // =====================================================

    always @(posedge clk) begin

        if (MEM_WB_reg_write && MEM_WB_rd != 0)
            regfile[MEM_WB_rd] <= wb_data;

        regfile[0] <= 0;

    end

    // =====================================================
    // 14. PIPELINE SEQUENTIAL LOGIC
    // =====================================================

    integer i;

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            PC <= 0;

            IF_ID_PC <= 0;
            IF_ID_instr <= 32'h00000013;

            ID_EX_PC <= 0;
            ID_EX_reg1 <= 0;
            ID_EX_reg2 <= 0;
            ID_EX_imm <= 0;
            ID_EX_rs1 <= 0;
            ID_EX_rs2 <= 0;
            ID_EX_opcode <= 0;
            ID_EX_funct3 <= 0;
            ID_EX_funct7 <= 0;

            ID_EX_reg_write <= 0;
            ID_EX_mem_read <= 0;
            ID_EX_mem_write <= 0;
            ID_EX_mem_to_reg <= 0;
            ID_EX_alu_src <= 0;
            ID_EX_branch <= 0;

            ID_EX_mem_read <= 0;
            ID_EX_rd <= 0;

            EX_MEM_alu_result <= 0;
            EX_MEM_write_data <= 0;
            EX_MEM_rd <= 0;
            EX_MEM_reg_write <= 0;
            EX_MEM_mem_read <= 0;
            EX_MEM_mem_write <= 0;
            EX_MEM_mem_to_reg <= 0;

            MEM_WB_mem_data <= 0;
            MEM_WB_alu_result <= 0;
            MEM_WB_rd <= 0;
            MEM_WB_reg_write <= 0;
            MEM_WB_mem_to_reg <= 0;

            for (i = 0; i < 32; i = i + 1)
                regfile[i] <= 0;

        end else begin

            // =============================================
            // IF STAGE
            // =============================================

            if (branch_taken) begin

                PC <= branch_target;

                IF_ID_PC <= 0;
                IF_ID_instr <= 32'h00000013;

            end

            else if (!stall) begin

                PC <= PC + 4;

                IF_ID_PC <= PC;
                IF_ID_instr <= instruction;

            end

            // =============================================
            // ID STAGE
            // =============================================

            if (branch_taken || stall) begin

                // Insert NOP into ID/EX
                ID_EX_PC <= 0;
                ID_EX_reg1 <= 0;
                ID_EX_reg2 <= 0;
                ID_EX_imm <= 0;
                ID_EX_rs1 <= 0;
                ID_EX_rs2 <= 0;
                ID_EX_opcode <= 0;
                ID_EX_funct3 <= 0;
                ID_EX_funct7 <= 0;

                ID_EX_reg_write <= 0;
                ID_EX_mem_read <= 0;
                ID_EX_mem_write <= 0;
                ID_EX_mem_to_reg <= 0;
                ID_EX_alu_src <= 0;
                ID_EX_branch <= 0;

                ID_EX_rd <= 0;

            end

            else begin

                ID_EX_PC <= IF_ID_PC;
                ID_EX_reg1 <= read_data1;
                ID_EX_reg2 <= read_data2;
                ID_EX_imm <= immediate;

                ID_EX_rs1 <= rs1;
                ID_EX_rs2 <= rs2;
                ID_EX_rd <= rd;

                ID_EX_opcode <= opcode;
                ID_EX_funct3 <= funct3;
                ID_EX_funct7 <= funct7;

                ID_EX_reg_write <= reg_write;
                ID_EX_mem_read <= mem_read;
                ID_EX_mem_write <= mem_write;
                ID_EX_mem_to_reg <= mem_to_reg;
                ID_EX_alu_src <= alu_src;
                ID_EX_branch <= branch;

            end

            // =============================================
            // EX STAGE
            // =============================================

            EX_MEM_alu_result <= alu_result;
            EX_MEM_write_data <= forwardB;
            EX_MEM_rd <= ID_EX_rd;

            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;

            // =============================================
            // MEM STAGE
            // =============================================

            if (EX_MEM_mem_write)
                data_mem[EX_MEM_alu_result[9:2]]
                    <= EX_MEM_write_data;

            // =============================================
            // WB STAGE
            // =============================================

            MEM_WB_mem_data <= memory_read_data;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_rd <= EX_MEM_rd;

            MEM_WB_reg_write <= EX_MEM_reg_write;
            MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;

        end

    end

endmodule