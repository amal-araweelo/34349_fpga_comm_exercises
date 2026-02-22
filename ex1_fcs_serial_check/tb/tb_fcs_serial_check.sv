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

  task automatic simple_test_fixed_payload();

    // Fixed payload
    payload = 512'h0010_A47B_EA80_0012_3456_7890_0800_4500_002E_B3FE_0000_8011_0540_C0A8_002C_C0A8_0004_0400_0400_001A_2DE8_0001_0203_0405_0607_0809_0A0B_0C0D_0E0F_1011; // fixed payload for debugging
    // payload_neg = {~payload[479:448],payload[447:0]}; // only complement the MSB 32 bits of the payload (for debugging)
    crc = 32'hE6C53DB2;
    // crc_neg = ~crc; // for debugging
    frame = {payload, crc}; // frame to be fed to fcs_serial_check

    $display("Payload 32 MSB neg: 0x%h", payload_neg);
    $display("CRC neg: 0x%h", crc_neg);

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

    // Wait 31 cycles to ensure fcs_serial_check processes final bits
    repeat(31) begin
      // $display("fcs_error = b%b", i_fcs_if.cb.fcs_error);
      @(i_fcs_if.cb);
    end

    // Check result
    if (i_fcs_if.cb.fcs_error == 'b0)begin
      $display("TEST 1: CRC PASSED");
    end else begin
      $display("TEST 1: CRC FAILED \n");
      $display("Payload: 0x%h", payload);
      $display("CRC: 0x%h", crc);
      $display("Received frame: 0x%h", frame);
      $display("fcs_error: b%b", i_fcs_if.cb.fcs_error);
    end
  endtask

  task automatic simple_test_fixed_payload_wrong_crc();
      // Fixed payload
    payload = 512'h0010_A47B_EA80_0012_3456_7890_0800_4500_002E_B3FE_0000_8011_0540_C0A8_002C_C0A8_0004_0400_0400_001A_2DE8_0001_0203_0405_0607_0809_0A0B_0C0D_0E0F_1011; // fixed payload for debugging
    crc = 32'hE6C53DB1;
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

    // Wait 31 cycles to ensure fcs_serial_check has processed the final bits
    repeat(31) begin
      @(i_fcs_if.cb);
    end

    // Check result
    if (i_fcs_if.cb.fcs_error != 'b0)begin
      $display("TEST 2: CRC PASSED");
    end else begin
      $display("TEST 2: CRC FAILED \n");
      $display("Payload: 0x%h", payload);
      $display("CRC: 0x%h", crc);
      $display("Received frame: 0x%h", frame);
      $display("fcs_error: b%b", i_fcs_if.cb.fcs_error);
    end
  endtask

  // Debugger todo remove
  task automatic debug_crc_calc();
    payload = 480'h0010_A47B_EA80_0012_3456_7890_0800_4500_002E_B3FE_0000_8011_0540_C0A8_002C_C0A8_0004_0400_0400_001A_2DE8_0001_0203_0405_0607_0809_0A0B_0C0D_0E0F_1011;
    crc = fcs.calc_crc(payload);
    $display("CRC = %h", crc);
    $finish;
  endtask

  initial begin // run tests
    fcs.reset_seq();
    simple_test_fixed_payload();
    fcs.reset_seq();
    simple_test_fixed_payload_wrong_crc();
    // debug_test();
    $stop();
  end
endmodule
