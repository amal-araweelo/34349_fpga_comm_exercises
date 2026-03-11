interface async_fifo_if(
    input logic wclk,
    input logic rclk
);

    logic reset;
    logic write_en;
    logic read_en;

    logic [7:0] write_data_in;
    logic [7:0] read_data_out;

    logic [4:0] fifo_occu_in;
    logic [4:0] fifo_occu_out;

endinterface