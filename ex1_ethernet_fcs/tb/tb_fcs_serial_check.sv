import fcs_pkg::*;

module tb_fcs_serial_check;

  // Clock
  logic clk = 0;
  localparam int CLK_PERIOD = 10;

  always #(CLK_PERIOD/2) clk = ~clk;

  // Interface and class
  fcs_if i_fcs_if (clk);
  fcs_class fcs;

  initial
    fcs = new(i_fcs_if);

  // DUT instance
  fcs_serial_check dut (
                     .clk(i_fcs_if.clk),
                     .reset(i_fcs_if.reset),
                     .start_of_frame(i_fcs_if.start_of_frame),
                     .end_of_frame(i_fcs_if.end_of_frame),
                     .data_in(i_fcs_if.data_in),
                     .fcs_error(i_fcs_if.fcs_error)
                   );

  // Signals
  logic [fcs.PAYLOAD_LEN-1:0] payload;
  logic [31:0] crc;
  logic [31:0] crc_neg;
  logic [fcs.PAYLOAD_LEN-1:0] payload_neg;
  logic [fcs.PAYLOAD_LEN+31:0] frame;



  ///////////////////////////// TEST TASKS //////////////////////////////
  task automatic test_fixed_payload();

    // Fixed payload
    payload = 512'h0010_A47B_EA80_0012_3456_7890_0800_4500_002E_B3FE_0000_8011_0540_C0A8_002C_C0A8_0004_0400_0400_001A_2DE8_0001_0203_0405_0607_0809_0A0B_0C0D_0E0F_1011; // fixed payload for debugging
    // payload_neg = {~payload[479:448],payload[447:0]}; // only complement the MSB 32 bits of the payload (for debugging)
    crc = 32'hE6C53DB2;
    // crc_neg = ~crc; // for debugging
    frame = {payload, crc}; // frame to be fed to fcs_serial_check

    // Send serially
    i_fcs_if.cb.start_of_frame <= 'b1; // pulse start of frame
    i_fcs_if.cb.data_in <= frame[fcs.PAYLOAD_LEN + 31]; // first bit of payload with start of frame
    @(i_fcs_if.cb);
    i_fcs_if.cb.start_of_frame <= 'b0;

    // Remaining bits
    for (int i = fcs.PAYLOAD_LEN + 31 - 1; i >= 0; i--) begin
      i_fcs_if.cb.data_in      <= frame[i];  // feed bits from MSB to LSB
      i_fcs_if.cb.end_of_frame <= (i == 31); // first FCS bit
      @(i_fcs_if.cb);
      i_fcs_if.cb.end_of_frame <= 'b0;
    end
    @(i_fcs_if.cb); // wait one clock cycle for the final crc register update

    @(i_fcs_if.cb); // wait another cycle for fcs_error to be pulsed

    // Check result
    if (i_fcs_if.cb.fcs_error == 'b0)begin
      $display("TEST 2 (FIXED PAYLOAD, CORRECT FCS HEADER): PASS");
    end else begin
      $display("TEST 2 (FIXED PAYLOAD, CORRECT FCS HEADER): FAIL \n");
      $display("got fcs_error: b%b, expected fcs_error = b0", i_fcs_if.cb.fcs_error);
    end
  endtask

  task automatic test_fixed_payload_wrong_crc();
      // Fixed payload
    payload = 512'h0010_A47B_EA80_0012_3456_7890_0800_4500_002E_B3FE_0000_8011_0540_C0A8_002C_C0A8_0004_0400_0400_001A_2DE8_0001_0203_0405_0607_0809_0A0B_0C0D_0E0F_1011; // fixed payload for debugging
    crc = 32'hE6C53DB1;
    frame = {payload, crc}; // frame to be fed to fcs_serial_check

    // Send serially
    i_fcs_if.cb.start_of_frame <= 'b1; // pulse start of frame
    i_fcs_if.cb.data_in <= frame[fcs.PAYLOAD_LEN + 31]; // first bit of payload with start of frame
    @(i_fcs_if.cb);
    i_fcs_if.cb.start_of_frame <= 'b0;

    // Send all remaining bits
    for (int i = fcs.PAYLOAD_LEN + 31 - 1; i >= 0; i--) begin
      i_fcs_if.cb.data_in      <= frame[i];  // feed bits from MSB to LSB
      i_fcs_if.cb.end_of_frame <= (i == 31); // first FCS bit
      @(i_fcs_if.cb);
      i_fcs_if.cb.end_of_frame <= 'b0;
    end
    @(i_fcs_if.cb); // wait one clock cycle for the final crc register update

    @(i_fcs_if.cb); // wait another cycle for fcs_error to be pulsed

    // Check result
    if (i_fcs_if.cb.fcs_error == 'b1)begin
      $display("TEST 2 (FIXED PAYLOAD, WRONG FCS HEADER): PASS");
    end else begin
      $display("TEST 2 (FIXED PAYLOAD, WRONG FCS HEADER): FAIL");
      $display("got fcs_error: b%b, expected fcs_error = b1", i_fcs_if.cb.fcs_error);
    end
  endtask

  task automatic test_random_payload();
    // Fixed payload
    payload = fcs.generate_payload(); // random payload for testing
    crc = fcs.calc_crc(payload);
    frame = {payload, crc}; // frame to be fed to fcs_serial_check

    // Send serially
    i_fcs_if.cb.start_of_frame <= 'b1; // pulse start of frame
    i_fcs_if.cb.data_in <= frame[fcs.PAYLOAD_LEN + 31]; // first bit of payload with start of frame
    @(i_fcs_if.cb);
    i_fcs_if.cb.start_of_frame <= 'b0;

    // Remaining bits
    for (int i = fcs.PAYLOAD_LEN + 31 - 1; i >= 0; i--) begin
      i_fcs_if.cb.data_in      <= frame[i];  // feed bits from MSB to LSB
      i_fcs_if.cb.end_of_frame <= (i == 31); // first FCS bit
      @(i_fcs_if.cb);
      i_fcs_if.cb.end_of_frame <= 'b0;
    end
    @(i_fcs_if.cb); // wait one clock cycle for the final crc register update

    @(i_fcs_if.cb); // wait another cycle for fcs_error to be pulsed

    // Check result
    if (i_fcs_if.cb.fcs_error == 'b0)begin
      $display("TEST 3 (RANDOM PAYLOAD, CORRECT FCS HEADER): PASS");
    end else begin
      $display("TEST 3 (RANDOM PAYLOAD, CORRECT FCS HEADER): FAIL \n");
      $display("got fcs_error: b%b, expected fcs_error = b0", i_fcs_if.cb.fcs_error);
    end
  endtask

  task automatic test_random_payload_wrong_crc();
    // Fixed payload
    payload = fcs.generate_payload(); // random payload for testing
    crc = fcs.calc_crc(payload);
    crc[31:30] = ~crc[31:30]; // introduce error in the FCS
    frame = {payload, crc}; // frame to be fed to fcs_serial_check

    // Send serially
    i_fcs_if.cb.start_of_frame <= 'b1; // pulse start of frame
    i_fcs_if.cb.data_in <= frame[fcs.PAYLOAD_LEN + 31]; // first bit of payload with start of frame
    @(i_fcs_if.cb);
    i_fcs_if.cb.start_of_frame <= 'b0;

    // Remaining bits
    for (int i = fcs.PAYLOAD_LEN + 31 - 1; i >= 0; i--) begin
      i_fcs_if.cb.data_in      <= frame[i];  // feed bits from MSB to LSB
      i_fcs_if.cb.end_of_frame <= (i == 31); // first FCS bit
      @(i_fcs_if.cb);
      i_fcs_if.cb.end_of_frame <= 'b0;
    end
    @(i_fcs_if.cb); // wait one clock cycle for the final crc register update

    @(i_fcs_if.cb); // wait another cycle for fcs_error to be pulsed

    // Check result
    if (i_fcs_if.cb.fcs_error == 'b1)begin
      $display("TEST 4 (RANDOM PAYLOAD, WRONG FCS HEADER): PASS");
    end else begin
      $display("TEST 4 (RANDOM PAYLOAD, WRONG FCS HEADER): FAIL \n");
      $display("got fcs_error: b%b, expected fcs_error = b1", i_fcs_if.cb.fcs_error);
    end
  endtask


  ///////////////////////////// RUN ALL TESTS //////////////////////////////
  initial begin // run tests
    fcs.reset_seq();
    test_fixed_payload();
    test_fixed_payload_wrong_crc();
    test_random_payload();
    test_random_payload_wrong_crc();
    $stop();
  end
endmodule
