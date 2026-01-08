module cpu_top (
    input  logic clk,
    input  logic reset,

    // Debug outputs (super helpful)
    output logic [2:0] state_dbg,
    output logic [7:0] pc_dbg,
    output logic [15:0] ir_dbg,
    
    output logic [3:0]  opcode_dbg,
    output logic [3:0]  rs_dbg,
    output logic [3:0]  rt_dbg,
    output logic [15:0] rs_val_dbg,
    output logic [15:0] rt_val_dbg,
    output logic [15:0] alu_out_dbg,

    output logic [3:0] rd_dbg,
    output logic       rf_we_dbg
);

    // ----------------------------
    // State encoding
    // ----------------------------
    localparam logic [2:0]
        S_FETCH   = 3'd0,
        S_DECODE  = 3'd1,
        S_EXECUTE = 3'd2,
        S_MEM     = 3'd3,
        S_WB      = 3'd4;

    logic [2:0] state, next_state;

    // ----------------------------
    // PC + IR registers
    // ----------------------------
    logic [7:0]  pc, pc_next;
    logic [15:0] ir, ir_next;
    logic [15:0] alu_out, alu_out_next;
    
    // ----------------------------
    // Decode fields from IR
        // Format (16-bit):
    // [15:12] opcode
    // [11:8]  rd
    // [7:4]   rs
    // [3:0]   rt
    // ----------------------------
    logic [3:0] opcode, rd, rs, rt;

    assign opcode = ir[15:12];
    assign rd     = ir[11:8];
    assign rs     = ir[7:4];
    assign rt     = ir[3:0];

    // ----------------------------
    // Register file (8 regs x 16-bit)
    // ----------------------------
    logic [15:0] rf [0:7];
    logic [15:0] rf_rs_data, rf_rt_data;
    
    logic        rf_we;
    logic [2:0]  rf_waddr;
    logic [15:0] rf_wdata;

    assign rf_rs_data = rf[rs[2:0]];
    assign rf_rt_data = rf[rt[2:0]];

    // Initialize registers for simulation (so you can see real values)
    initial begin
        rf[0] = 16'd10;
        rf[1] = 16'd20;
        rf[2] = 16'd30;
        rf[3] = 16'd40;
        rf[4] = 16'd50;
        rf[5] = 16'd60;
        rf[6] = 16'd70;
        rf[7] = 16'd80;
    end

    // ----------------------------
    // ALU (combinational)
    // ----------------------------
    logic [15:0] alu_a, alu_b, alu_result;

    localparam logic [3:0]
        OP_ADD = 4'h1,
        OP_SUB = 4'h2,
        OP_AND = 4'h3,
        OP_OR  = 4'h4;

    assign alu_a = rf_rs_data;
    assign alu_b = rf_rt_data;

    always_comb begin
        alu_result = 16'd0;
        case (opcode)
            OP_ADD: alu_result = alu_a + alu_b;
            OP_SUB: alu_result = alu_a - alu_b;
            OP_AND: alu_result = alu_a & alu_b;
            OP_OR : alu_result = alu_a | alu_b;
            default: alu_result = 16'd0;
        endcase
    end

    // ----------------------------
    // Tiny instruction ROM (16-bit instructions)
    // For now this is just a demo program.
    // Addressed by PC[7:0], but we only fill a few entries.
    // ----------------------------
    logic [15:0] imem [0:255];

    initial begin
        // ADD  r5 = r1 + r2  => 20 + 30 = 50
        imem[8'd0] = 16'h1512; // opcode=1, rd=5, rs=1, rt=2

        // SUB  r6 = r4 - r3  => 50 - 40 = 10
        imem[8'd1] = 16'h2643; // opcode=2, rd=6, rs=4, rt=3

        // AND  r7 = r6 & r7  => after r6 becomes 10, this becomes 10 & 80 = 0
        imem[8'd2] = 16'h3767; // opcode=3, rd=7, rs=6, rt=7

        // OR   r5 = r5 | r3  => after r5 becomes 50, 50 | 40 = 58
        imem[8'd3] = 16'h4553; // opcode=4, rd=5, rs=5, rt=3
    end

    // ----------------------------
    // Sequential state + registers
    // ----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_FETCH;
            pc    <= 8'd0;
            ir    <= 16'd0;
            alu_out <= 16'd0;
        end else begin
            state <= next_state;
            pc    <= pc_next;
            ir    <= ir_next;
            alu_out <= alu_out_next;
        end
        
        if (rf_we) begin
            rf[rf_waddr] <= rf_wdata;
        end
    end

    // ----------------------------
    // Next-state logic (same as before)
    // ----------------------------
    always_comb begin
        next_state = state;
        case (state)
            S_FETCH:   next_state = S_DECODE;
            S_DECODE:  next_state = S_EXECUTE;
            S_EXECUTE: next_state = S_MEM;
            S_MEM:     next_state = S_WB;
            S_WB:      next_state = S_FETCH;
            default:   next_state = S_FETCH;
        endcase
    end

    // ----------------------------
    // Default "hold" behavior for registers
    // Then override in specific states.
    // ----------------------------
    always_comb begin
        pc_next = pc;
        ir_next = ir;
        alu_out_next = alu_out;
        
        rf_we    = 1'b0;
        rf_waddr = 3'b0;
        rf_wdata = 16'd0;
        
        case (state)
            S_FETCH: begin
                // Fetch instruction at current PC into IR
                ir_next = imem[pc];
                // Increment PC for next instruction
                pc_next = pc + 8'd1;
            end
            
            S_EXECUTE: begin
                alu_out_next = alu_result; //gets the ALU result on clock edge
            end
            
            S_WB: begin
                // For ALU ops, it writes ALUOut into rd
                if (opcode == OP_ADD || opcode == OP_SUB || opcode == OP_AND || opcode == OP_OR) begin
                    rf_we    = 1'b1;
                    rf_waddr = rd[2:0];
                    rf_wdata = alu_out;
                end
            end
                
            default: begin
                // other states do nothing yet
            end
        endcase
    end

    // Debug outputs
    assign state_dbg = state;
    assign pc_dbg    = pc;
    assign ir_dbg    = ir;
    assign opcode_dbg = opcode;
    assign rs_dbg     = rs;
    assign rt_dbg     = rt;
    assign rs_val_dbg = rf_rs_data;
    assign rt_val_dbg = rf_rt_data;
    assign alu_out_dbg = alu_out;
    
    assign rf_we_dbg = rf_we;
    assign rd_dbg = rd;

endmodule
