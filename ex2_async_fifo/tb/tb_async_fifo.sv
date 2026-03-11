module tb_async_fifo;

logic wclk = 0;
logic rclk = 0;

always #5  wclk = ~wclk;
always #7  rclk = ~rclk;

async_fifo_if bus(wclk, rclk);

async_fifo dut(
    .reset(bus.reset),
    .wclk(wclk),
    .rclk(rclk),
    .write_en(bus.write_en),
    .read_en(bus.read_en),
    .fifo_occu_in(bus.fifo_occu_in),
    .fifo_occu_out(bus.fifo_occu_out),
    .write_data_in(bus.write_data_in),
    .read_data_out(bus.read_data_out)
);

initial begin

    logic [7:0] data;
    bus.reset = 0;
    bus.write_en = 0;
    bus.read_en = 0;

    repeat(5) @(posedge wclk);
    bus.reset = 1;
    repeat(5) @(posedge wclk);

    // write a value to FIFO
    bus.write_data_in = 8'hA5;

    bus.write_en = 1;
    @(posedge wclk);
    bus.write_en = 0;

    // wait for sync
    repeat(10) @(posedge wclk);
    repeat(10) @(posedge rclk);

    $display("write occupancy = %0d", bus.fifo_occu_in);
    $display("read occupancy  = %0d", bus.fifo_occu_out);

    // READ VALUE
    bus.read_en = 1;
    @(posedge rclk);
    bus.read_en = 0;
    // wait two clock cycles 
    @(posedge rclk); // reg -> memory
    @(posedge rclk); // memory -> q
    data = bus.read_data_out;

    // RESULT
    if (data == 8'hA5)
        $display("PASS: data correct");
    else
        $display("FAIL: expected A5 got %h", data);
    $stop;
end

endmodule