module fcs_serial_check (
    input  logic clk,             // system clock
    input  logic reset,           // synchronous, active low reset
    input  logic start_of_frame,  // arrival of the first bit.
    input  logic end_of_frame,    // arrival of the first bit in FCS.
    input  logic data_in,         // serial input data.
    output logic fcs_error       // indicates an error.
  );

  logic [31:0] crc_r;
  logic        in_frame;
  logic [6:0]  start_cntr;
  logic [6:0]  fcs_bit_cntr;
  logic        fcs_error_r;
  logic fb;


  // Compute feedback bit
  always_comb begin
    if (start_cntr < 'd32 && start_cntr != 'd0) begin
      fb = ~data_in ^ crc_r[31];  // negate payload bits
    end else if (start_of_frame) begin
      fb = ~data_in ^ crc_r[31]; // negate first bit of payload
    end else if (fcs_bit_cntr < 'd32) begin
      fb = ~data_in ^ crc_r[31]; // negate FCS bits
    end else if (end_of_frame) begin
      fb = ~data_in ^ crc_r[31]; // negate first bit of FCS
    end else begin
      fb = data_in ^ crc_r[31];  // no negation for the rest
    end
  end

  // Ouput assignment
  assign fcs_error = fcs_error_r; // pulses for one clock cycle at the end of frame if there is an error

  always_ff @(posedge clk) begin
    
    fcs_error_r <= 'b0; // default to no error, will be set at the end of frame

    if (!reset) begin
      crc_r        <= 'b0;
      start_cntr   <= 'd32;
      fcs_bit_cntr <= 'd32;
      in_frame     <= 'b0;
      fcs_error_r  <= 'b0;
    end else begin

      // Start of frame (reset counter and enable in frame)
      if (start_of_frame) begin
          in_frame <= 'b1;
          start_cntr <= 'd31;
      end

      // End of frame
      if (end_of_frame) begin
        fcs_bit_cntr <= fcs_bit_cntr - 'd1;
      end

      // Generator polynomial: x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
      if (start_of_frame || in_frame) begin // while processing frame
        crc_r[31] <= crc_r[30]; // CRC shift register
        crc_r[30] <= crc_r[29];
        crc_r[29] <= crc_r[28];
        crc_r[28] <= crc_r[27];
        crc_r[27] <= crc_r[26];
        crc_r[26] <= crc_r[25] ^ crc_r[31];
        crc_r[25] <= crc_r[24];
        crc_r[24] <= crc_r[23];
        crc_r[23] <= crc_r[22] ^ crc_r[31];
        crc_r[22] <= crc_r[21] ^ crc_r[31];
        crc_r[21] <= crc_r[20];
        crc_r[20] <= crc_r[19];
        crc_r[19] <= crc_r[18];
        crc_r[18] <= crc_r[17];
        crc_r[17] <= crc_r[16];
        crc_r[16] <= crc_r[15] ^ crc_r[31];
        crc_r[15] <= crc_r[14];
        crc_r[14] <= crc_r[13];
        crc_r[13] <= crc_r[12];
        crc_r[12] <= crc_r[11] ^ crc_r[31];
        crc_r[11] <= crc_r[10] ^ crc_r[31];
        crc_r[10] <= crc_r[9]  ^ crc_r[31];
        crc_r[9]  <= crc_r[8];
        crc_r[8]  <= crc_r[7] ^ crc_r[31];
        crc_r[7]  <= crc_r[6] ^ crc_r[31];
        crc_r[6]  <= crc_r[5];
        crc_r[5]  <= crc_r[4] ^ crc_r[31];
        crc_r[4]  <= crc_r[3] ^ crc_r[31];
        crc_r[3]  <= crc_r[2];
        crc_r[2]  <= crc_r[1] ^ crc_r[31];
        crc_r[1]  <= crc_r[0] ^ crc_r[31];
        crc_r[0]  <= fb;

        // Decrement start bit counter only when we are in the payload part of the frame
        if (start_cntr < 'd32 && start_cntr != 'd0) start_cntr <= start_cntr - 'd1;
        else if (start_cntr == 'd1) start_cntr <= 'd0; // keep at 0

        // Decrement FCS bit counter only when we are in the FCS part of the frame
        if (fcs_bit_cntr < 'd32) fcs_bit_cntr <= fcs_bit_cntr - 'd1;
        else if (fcs_bit_cntr == 'd1) fcs_bit_cntr <= 'd0;

        // Check for FCS error at the end of frame
        if (fcs_bit_cntr == 'd0) begin
          fcs_error_r <= (crc_r == 32'h0000_0000) ? 'b0: 'b1;
          in_frame <='b0;

          // prepare for next frame
          crc_r <= '0;
          start_cntr   <= 'd32;
          fcs_bit_cntr <= 'd32;
        end
      end
    end
  end
endmodule
