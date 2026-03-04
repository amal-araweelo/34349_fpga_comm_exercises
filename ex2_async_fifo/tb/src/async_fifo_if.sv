/**
 * Asynchronous FIFO Interface
 * Encapsulates all signals for the async_fifo module
 */

interface async_fifo_if (
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

    // Modport for writing
    modport writer (
        output write_en,
        output write_data_in,
        input fifo_occu_in,
        input reset
    );

    // Modport for reading
    modport reader (
        output read_en,
        input read_data_out,
        input fifo_occu_out,
        input reset
    );

    // Modport for monitor/verification
    modport monitor (
        input write_en,
        input write_data_in,
        input read_en,
        input read_data_out,
        input fifo_occu_in,
        input fifo_occu_out,
        input reset
    );

endinterface
