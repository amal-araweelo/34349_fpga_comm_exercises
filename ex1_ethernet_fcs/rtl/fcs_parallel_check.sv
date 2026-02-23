module fcs_parallel_check (
    input  logic        clk,
    input  logic        reset,
    input  logic        start_of_frame,
    input  logic        end_of_frame,
    input  logic [7:0]  data_in,
    output logic        fcs_error
);

  logic [31:0] crc_r;

  logic        in_frame;
  logic [3:0]  start_cntr;      // 32 bits = 4 bytes
  logic [3:0]  fcs_byte_cntr;   // 4 FCS bytes
  logic        fcs_error_r;

  logic [7:0]  data_proc;

  // Ouput assignment
  assign fcs_error = fcs_error_r;

  // Compute feedback bits
  always_comb begin
    data_proc = data_in; // default to no negation
    if (start_cntr < 4 && start_cntr != 0)
      data_proc = ~data_in;  // negate payload byte
    else if (start_of_frame)
      data_proc = ~data_in; // negate first byte of payload
    else if (fcs_byte_cntr < 4)
      data_proc = ~data_in; // negate FCS byte
    else if (end_of_frame)
      data_proc = ~data_in; // negate first byte of FCS
  end


  always_ff @(posedge clk) begin

    fcs_error_r <= 1'b0; // pulses for one clock cycle at the end of frame if there is an error

    if (!reset) begin
      crc_r         <= 32'b0;
      start_cntr    <= 4;
      fcs_byte_cntr <= 4;
      in_frame      <= 1'b0;
      fcs_error_r   <= 1'b0;
    end
    else begin
      // Start of frame (reset counter and enable in frame)
      if (start_of_frame) begin
        in_frame   <= 1'b1;
        start_cntr <= 3;
      end

      if (end_of_frame)
        fcs_byte_cntr <= fcs_byte_cntr - 1;

      if (start_of_frame || in_frame) begin // while processing frame

        // 8-bit parallel update
        crc_r[0] <= crc_r[24] ^ crc_r[30] ^ data_proc[0];
        crc_r[1] <= crc_r[24] ^ crc_r[25] ^ crc_r[30] ^ crc_r[31] ^ data_proc[1];
        crc_r[2] <= crc_r[24] ^ crc_r[25] ^ crc_r[26] ^ crc_r[30] ^ crc_r[31] ^ data_proc[2];
        crc_r[3] <= crc_r[25] ^ crc_r[26] ^ crc_r[27] ^ crc_r[31] ^ data_proc[3];
        crc_r[4] <= crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30] ^ data_proc[4];
        crc_r[5] <= crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ data_proc[5];
        crc_r[6] <= crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ data_proc[6];
        crc_r[7] <= crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ crc_r[31] ^ data_proc[7];
        crc_r[8] <= crc_r[0] ^ crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28];
        crc_r[9] <= crc_r[1] ^ crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29];
        crc_r[10] <= crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ crc_r[2];
        crc_r[11] <= crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28] ^ crc_r[3];
        crc_r[12] <= crc_r[24] ^ crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ crc_r[4];
        crc_r[13] <= crc_r[25] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ crc_r[5];
        crc_r[14] <= crc_r[26] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30] ^ crc_r[31] ^ crc_r[6];
        crc_r[15] <= crc_r[27] ^ crc_r[28] ^ crc_r[29] ^ crc_r[31] ^ crc_r[7];
        crc_r[16] <= crc_r[24] ^ crc_r[28] ^ crc_r[29] ^ crc_r[8];
        crc_r[17] <= crc_r[25] ^ crc_r[29] ^ crc_r[30] ^ crc_r[9];
        crc_r[18] <= crc_r[10] ^ crc_r[26] ^ crc_r[30] ^ crc_r[31];
        crc_r[19] <= crc_r[11] ^ crc_r[27] ^ crc_r[31];
        crc_r[20] <= crc_r[12] ^ crc_r[28];
        crc_r[21] <= crc_r[13] ^ crc_r[29];
        crc_r[22] <= crc_r[14] ^ crc_r[24];
        crc_r[23] <= crc_r[15] ^ crc_r[24] ^ crc_r[25] ^ crc_r[30];
        crc_r[24] <= crc_r[16] ^ crc_r[25] ^ crc_r[26] ^ crc_r[31];
        crc_r[25] <= crc_r[17] ^ crc_r[26] ^ crc_r[27];
        crc_r[26] <= crc_r[18] ^ crc_r[24] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30];
        crc_r[27] <= crc_r[19] ^ crc_r[25] ^ crc_r[28] ^ crc_r[29] ^ crc_r[31];
        crc_r[28] <= crc_r[20] ^ crc_r[26] ^ crc_r[29] ^ crc_r[30];
        crc_r[29] <= crc_r[21] ^ crc_r[27] ^ crc_r[30] ^ crc_r[31];
        crc_r[30] <= crc_r[22] ^ crc_r[28] ^ crc_r[31];
        crc_r[31] <= crc_r[23] ^ crc_r[29];

        // Decrement start and FCS byte counters 
        if (start_cntr < 4 && start_cntr != 0) // when processing first 4 payload bytes
          start_cntr <= start_cntr - 1;

        if (fcs_byte_cntr < 4)  // when processing 4 FCS bytes
          fcs_byte_cntr <= fcs_byte_cntr - 1;

        if (fcs_byte_cntr == 0) begin // after processing all 4 FCS bytes, check if crc is correct and pulse fcs_error if not
          fcs_error_r <= (crc_r == 32'h0000_0000) ? 1'b0 : 1'b1;
          in_frame <= 1'b0;

          // prepare for next frame
          crc_r         <= 32'b0;
          start_cntr    <= 4;
          fcs_byte_cntr <= 4;
        end
        
      end
    end
  end

endmodule