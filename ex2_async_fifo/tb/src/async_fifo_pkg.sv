package async_fifo_pkg;

  class async_fifo_class;

    virtual async_fifo_if vif_w; // write domain if
    virtual async_fifo_if vif_r; // read domain if

    function new(virtual async_fifo_if vif_w, virtual async_fifo_if vif_r);
      this.vif_w = vif_w;
      this.vif_r = vif_r;
    endfunction

    // FIFO params
    localparam int FIFO_DEPTH = 16;
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;
    localparam int PTR_WIDTH = 5;

    /////////////////////// GENERATE RANDOM DATA //////////////////////////////////
    function logic [DATA_WIDTH-1:0] generate_random_data();
      logic [DATA_WIDTH-1:0] data;
      data = $urandom_range(0, 255);
      return data;
    endfunction

    /////////////////////// GENERATE PATTERN DATA /////////////////////////////////
    function logic [DATA_WIDTH-1:0] generate_pattern_data(input int index, input logic [1:0] pattern_type);
      logic [DATA_WIDTH-1:0] data;
      case (pattern_type)
        2'b00: data = index[7:0];              // Sequential pattern
        2'b01: data = 8'hAA;                   // Fixed pattern 0xAA
        2'b10: data = 8'h55;                   // Fixed pattern 0x55
        2'b11: data = (index % 2) ? 8'hFF : 8'h00; // Alternating pattern
        default: data = 8'h00;
      endcase
      return data;
    endfunction

    //////////////////////// RESET SEQUENCE ////////////////////////////////
    task automatic reset_seq();
      vif_w.reset <= 'b0;
      vif_w.write_en <= 'b0;
      vif_r.read_en <= 'b0;
      repeat(10) @(posedge vif_w.wclk);
      vif_w.reset <='b1;
      repeat(5) @(posedge vif_w.wclk);
    endtask

    //////////////////////// WRITE DATA TO FIFO ////////////////////////////////
    task automatic write_data(input logic [DATA_WIDTH-1:0] data);
      @(vif_w.cb_w);
      vif_w.cb_w.write_en <= 'b1;
      vif_w.cb_w.write_data_in <= data;
      @(vif_w.cb_w);
      vif_w.cb_w.write_en <= 'b0;
    endtask

    //////////////////////// READ DATA FROM FIFO ////////////////////////////////
    task automatic read_data(output logic [DATA_WIDTH-1:0] data);
      @(vif_r.cb_r);
      vif_r.cb_r.read_en <= 'b1;
      @(vif_r.cb_r);
      data = vif_r.cb_r.read_data_out;
      vif_r.cb_r.read_en <= 'b0;
    endtask

    //////////////////////// WRITE MULTIPLE DATA ////////////////////////////////
    task automatic write_multiple(input int count, input logic [1:0] pattern_type = 2'b00);
      for (int i = 0; i < count; i++) begin
        logic [DATA_WIDTH-1:0] data;
        if (pattern_type == 2'b00)
          data = generate_random_data();
        else
          data = generate_pattern_data(i, pattern_type);
        write_data(data);
      end
    endtask

    //////////////////////// READ MULTIPLE DATA ////////////////////////////////
    task automatic read_multiple(input int count, output logic [DATA_WIDTH-1:0] data_queue[$]);
      for (int i = 0; i < count; i++) begin
        logic [DATA_WIDTH-1:0] data;
        read_data(data);
        data_queue.push_back(data);
      end
    endtask

    //////////////////////// WAIT FOR SYNCHRONIZATION ////////////////////////////////
    task automatic wait_sync(input int cycles = 10);
      repeat(cycles) @(posedge vif_w.wclk);
      repeat(cycles) @(posedge vif_r.rclk);
    endtask

  endclass

endpackage
