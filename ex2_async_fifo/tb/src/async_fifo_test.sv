/**
 * Asynchronous FIFO Testbench
 * Tests basic functionality: write, read, full, empty, occupancy
 */

`timescale 1ns / 1ps

module async_fifo_test;

    // Clock signals
    logic wclk;
    logic rclk;

    // Test signals
    int errors;
    int test_count;

    // Instantiate interface
    async_fifo_if fifo_if (
        .wclk (wclk),
        .rclk (rclk)
    );

    // Instantiate DUT
    async_fifo dut (
        .reset           (fifo_if.reset),
        .wclk            (wclk),
        .rclk            (rclk),
        .write_en        (fifo_if.write_en),
        .read_en         (fifo_if.read_en),
        .fifo_occu_in    (fifo_if.fifo_occu_in),
        .fifo_occu_out   (fifo_if.fifo_occu_out),
        .write_data_in   (fifo_if.write_data_in),
        .read_data_out   (fifo_if.read_data_out)
    );

    // Clock generation
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;  // 100 MHz
    end

    initial begin
        rclk = 0;
        forever #7 rclk = ~rclk;  // ~71 MHz (different clock domain)
    end

    // Test wrapper task
    task automatic assert_equal(logic [7:0] actual, logic [7:0] expected, string msg);
        if (actual != expected) begin
            $error("FAIL: %s. Expected: %d, Got: %d", msg, expected, actual);
            errors++;
        end else begin
            $display("PASS: %s", msg);
        end
        test_count++;
    endtask

    task automatic assert_equal_int(int actual, int expected, string msg);
        if (actual != expected) begin
            $error("FAIL: %s. Expected: %d, Got: %d", msg, expected, actual);
            errors++;
        end else begin
            $display("PASS: %s", msg);
        end
        test_count++;
    endtask

    // Main test
    initial begin
        errors = 0;
        test_count = 0;

        $display("=== Asynchronous FIFO Testbench ===");

        // Test 1: Reset behavior
        $display("\n--- Test 1: Reset Behavior ---");
        fifo_if.reset <= 1'b0;
        #100;
        fifo_if.reset <= 1'b1;
        #20;
        assert_equal_int(fifo_if.fifo_occu_in, 0, "Write domain occupancy after reset");
        assert_equal_int(fifo_if.fifo_occu_out, 0, "Read domain occupancy after reset");

        // Test 2: Single write
        $display("\n--- Test 2: Single Write ---");
        fifo_if.write_en = 1'b0;
        fifo_if.read_en = 1'b0;
        #20;
        fifo_if.write_data_in = 8'hAA;
        fifo_if.write_en = 1'b1;
        @(posedge wclk);
        @(posedge wclk);
        #50;
        fifo_if.write_en = 1'b0;
        #100;  // Wait for synchronization
        assert_equal_int(fifo_if.fifo_occu_out, 1, "Occupancy after 1 write");

        // Test 3: Read written data
        $display("\n--- Test 3: Read Written Data ---");
        @(posedge rclk);
        fifo_if.read_en = 1'b1;
        @(posedge rclk);
        fifo_if.read_en = 1'b0;
        #20;
        assert_equal(fifo_if.read_data_out, 8'hAA, "Read back correct data");
        #100;
        assert_equal_int(fifo_if.fifo_occu_out, 0, "Occupancy returns to 0 after read");

        // Test 4: Fill FIFO to full
        $display("\n--- Test 4: Fill FIFO to Full ---");
        fifo_if.write_en = 1'b0;
        fifo_if.read_en = 1'b0;
        #50;
        for (int i = 0; i < 16; i++) begin
            fifo_if.write_data_in = 8'h00 + i;
            fifo_if.write_en = 1'b1;
            @(posedge wclk);
        end
        fifo_if.write_en = 1'b0;
        #50;
        $display("Write domain occupancy: %d", fifo_if.fifo_occu_in);

        // Wait for synchronization
        #500;
        $display("Read domain occupancy after sync: %d", fifo_if.fifo_occu_out);
        assert_equal_int(fifo_if.fifo_occu_out, 16, "FIFO full - occupancy = 16");

        // Test 5: Read all data
        $display("\n--- Test 5: Read All Data ---");
        for (int i = 0; i < 16; i++) begin
            @(posedge rclk);
            fifo_if.read_en = 1'b1;
            assert_equal(fifo_if.read_data_out, 8'h00 + i, $sformatf("Read data[%d]", i));
        end
        fifo_if.read_en = 1'b0;
        #100;
        assert_equal_int(fifo_if.fifo_occu_out, 0, "FIFO empty after reading all");

        // Test 6: Simultaneous write and read
        $display("\n--- Test 6: Simultaneous Write and Read ---");
        for (int i = 0; i < 20; i++) begin
            fifo_if.write_data_in = 8'h10 + i;
            fifo_if.write_en = 1'b1;
            fifo_if.read_en = 1'b1;
            @(posedge wclk);
            @(posedge rclk);
        end
        fifo_if.write_en = 1'b0;
        fifo_if.read_en = 1'b0;
        #100;
        $display("Occupancy during simultaneous ops: Write=%d, Read=%d", 
                 fifo_if.fifo_occu_in, fifo_if.fifo_occu_out);

        // Final report
        $display("\n=== Test Summary ===");
        $display("Total tests: %d", test_count);
        $display("Errors: %d", errors);
        if (errors == 0) begin
            $display("✓ All tests PASSED!");
        end else begin
            $display("✗ %d test(s) FAILED!", errors);
        end

        #100;
        $finish;
    end

endmodule
