module cpu_top (
    input  logic clk,
    input  logic reset,

    // Debug outputs (super helpful)
    output logic [2:0] state_dbg,
    output logic [7:0] pc_dbg,
    output logic [15:0] ir_dbg
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

    // ----------------------------
    // Tiny instruction ROM (16-bit instructions)
    // For now this is just a demo program.
    // Addressed by PC[7:0], but we only fill a few entries.
    // ----------------------------
    logic [15:0] imem [0:255];

    initial begin
        // Demo "program" (raw 16-bit words for now)
        // You'll replace these later with your real instruction encoding.
        imem[8'd0] = 16'h1111;
        imem[8'd1] = 16'h2222;
        imem[8'd2] = 16'h3333;
        imem[8'd3] = 16'h4444;
        imem[8'd4] = 16'h5555;
    end

    // ----------------------------
    // Sequential state + registers
    // ----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_FETCH;
            pc    <= 8'd0;
            ir    <= 16'd0;
        end else begin
            state <= next_state;
            pc    <= pc_next;
            ir    <= ir_next;
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

        case (state)
            S_FETCH: begin
                // Fetch instruction at current PC into IR
                ir_next = imem[pc];
                // Increment PC for next instruction
                pc_next = pc + 8'd1;
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

endmodule
