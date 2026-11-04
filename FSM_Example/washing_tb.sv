module washing_machine_tb;

    logic clk;
    logic reset;
    logic start;

    logic fill_valve;
    logic wash_motor;
    logic drain_pump;
    logic spin_motor;
    logic done;

    // Instantiate DUT
    washing_machine dut (
        .clk(clk),
        .reset(reset),
        .start(start),

        .fill_valve(fill_valve),
        .wash_motor(wash_motor),
        .drain_pump(drain_pump),
        .spin_motor(spin_motor),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        start = 0;

        // Reset
        #10;
        reset = 0;

        // Start washing machine
        #10;
        start = 1;

        #10;
        start = 0;

        // Allow the complete washing cycle
        #450;

        $stop;

    end

endmodule