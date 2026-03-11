/*****************************************************************************************
Notes:
    FIFO depth is 16
    Data width is 8
    To represent the occupancy of the FIFO, we need to count up to 16:
    FIFO occupancy width is 5 
    Address width is 4 (2^4 memory locations)
    Pointer width is 5 (4+1 for the extra bit to distinguish between full and empty states)
*******************************************************************************************/
module async_fifo (
    input logic reset,
    input logic wclk,
    input logic rclk,
    input logic write_en,
    input logic read_en,
    output logic [4:0] fifo_occu_in,
    output logic [4:0] fifo_occu_out,
    input logic [7:0] write_data_in,
    output logic [7:0] read_data_out
);

// Read and write pointers and addresses
logic [3:0] waddr, raddr; 
logic [4:0] wptr, rptr;
logic [4:0] rptr_sync; // write domain (synchronized to wclk)
logic [4:0] wptr_sync; // read domain (synchronized to rclk)

// Intermediate pointer signals
logic [4:0] rptr_r_next, wptr_w_next; // after bin2gray conversion
logic [4:0] rptr_r, wptr_w; // todo: why do we need this reg?
logic [4:0] rptr_w, wptr_r; // after first FF in synchronizer stage
logic [4:0] rptr_sync_gray, wptr_sync_gray; // before gray2bin conversion

// Status signals
logic full, empty; 

// Dual-port RAM instance
fifo_ram u_dual_port_ram (
        .data      (write_data_in),
        .rdaddress (raddr),
        .rdclock   (rclk),
        .rden      (read_en),
        .wraddress (waddr),
        .wrclock   (wclk),
        .wren      (write_en),
        .q         (read_data_out)
    );

logic [4:0] wptr_next;
assign wptr_next = wptr + 1;
// Write domain
always_ff @(posedge wclk) begin
    if (!reset)
        wptr <= 0;
    else if (write_en && !full)
        wptr <= wptr_next;
end
assign waddr = wptr[3:0];

// Read domain
always_ff @(posedge rclk) begin
    if (!reset) begin
        rptr <= 5'b0;
    end else if (read_en && !empty) begin // increment read pointer and address
        rptr <= rptr + 5'd1;
    end
end
assign raddr = rptr[3:0]; // address is the lower 4 bits of the pointer


// Calculate FIFO occupancy
// write domain
assign fifo_occu_in = (wptr[4] == rptr_sync[4]) ? wptr[3:0] - rptr_sync[3:0] : (5'd16 - (rptr_sync[3:0]-wptr[3:0]));

// read domain
assign fifo_occu_out = (rptr[4] == wptr_sync[4]) ? wptr_sync[3:0] - rptr[3:0] : (5'd16 - (rptr[3:0] - wptr_sync[3:0]));

// Calculate full and empty status
always_comb begin
    // write domain
    full = (wptr[4] != rptr_sync[4]) && (wptr[3:0] == rptr_sync[3:0]); // FIFO is full when write and read pointers are different but the MSB is different

    // read domain
    empty = (rptr == wptr_sync); // FIFO is empty when read and write pointers are equal
end

// Synchronize pointers accross clock domains
bin2gray u_calc_wptr_sync_gray(
    .bin_in(wptr),
    .gray_out(wptr_w_next)
);

bin2gray u_calc_rptr_sync_gray(
    .bin_in(rptr),
    .gray_out(rptr_r_next)
);

gray2bin u_calc_wptr_sync_bin(
    .gray_in(wptr_sync_gray),
    .bin_out(wptr_sync)
);

gray2bin u_calc_rptr_sync_bin(
    .gray_in(rptr_sync_gray),
    .bin_out(rptr_sync)
);

always_ff @(posedge wclk) begin
    if (!reset) begin
        wptr_w <= 5'b0;
        rptr_w <= 5'b0;
        rptr_sync_gray <= 5'b0;
    end else begin 
        wptr_w <= wptr_w_next;
        rptr_w <= rptr_r;
        rptr_sync_gray <= rptr_w;
    end
end

always_ff @(posedge rclk) begin
    if (!reset) begin
        rptr_r <= 5'b0;
        wptr_r <= 5'b0;
        wptr_sync_gray <= 5'b0;
    end else begin
        rptr_r <= rptr_r_next;
        wptr_r <= wptr_w;
        wptr_sync_gray <= wptr_r;
    end
end
endmodule