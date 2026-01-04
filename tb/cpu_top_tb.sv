module cpu_top_tb;

    logic clk = 0;
    logic reset = 1;

    logic [2:0]  state_dbg;
    logic [7:0]  pc_dbg;
    logic [15:0] ir_dbg;

    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .state_dbg(state_dbg),
        .pc_dbg(pc_dbg),
        .ir_dbg(ir_dbg)
    );

    // 100 MHz clock = 10 ns period
    always #5 clk = ~clk;

    initial begin
        #20;
        reset = 0;

        #200;
        $finish;
    end

endmodule
