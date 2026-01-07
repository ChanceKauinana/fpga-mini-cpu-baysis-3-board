module cpu_top_tb;

    logic clk = 0;
    logic reset = 1;

    logic [2:0]  state_dbg;
    logic [7:0]  pc_dbg;
    logic [15:0] ir_dbg;
    
    logic [3:0]  opcode_dbg;
    logic [3:0]  rs_dbg;
    logic [3:0]  rt_dbg;
    logic [15:0] rs_val_dbg;
    logic [15:0] rt_val_dbg;
    logic [15:0] alu_out_dbg;

    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .state_dbg(state_dbg),
        .pc_dbg(pc_dbg),
        .ir_dbg(ir_dbg),
        .opcode_dbg(opcode_dbg),
        .rs_dbg(rs_dbg),
        .rt_dbg(rt_dbg),
        .rs_val_dbg(rs_val_dbg),
        .rt_val_dbg(rt_val_dbg),
        .alu_out_dbg(alu_out_dbg)
    );

    // 100 MHz clock = 10 ns period
    always #5 clk = ~clk;

    initial begin
        #20;
        reset = 0;

        #400;
        $finish;
    end

endmodule
