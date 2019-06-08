//`define DEBUG


module tb_skid_buffer ();


    parameter WORD_WIDTH = 8;
    localparam NUM_TRANS = 10000-1;

    logic                        clk;
    logic                        rstn;

    // Slave interface
    logic                        s_valid;
    logic                        s_ready;
    logic    [WORD_WIDTH-1:0]    s_data;

    // Master interface
    logic                        m_valid;
    logic                        m_ready;
    logic    [WORD_WIDTH-1:0]    m_data;

    logic s_valid_tmp, m_ready_tmp;
    logic done, test_passed = 1'b0;

    
    skid_buffer dut (.*);

    initial begin
      done <= 1'b0;
      clk <= 1'b0;
      rstn <= 1'b0;
      s_valid <= 1'b0;
      s_valid_tmp = 1'b0;
      m_ready <= 1'b0;
      s_data  <= '0;
      #25ns;
      rstn <= 1'b1;
      @(posedge clk);
      repeat (NUM_TRANS-2) begin
        write();
      end
      @(posedge clk);
      s_valid <= 1'b1;
      m_ready <= 1'b1;
      @(posedge clk);
      s_valid <= 1'b0;
      m_ready <= 1'b1;

      done <= 1'b1;
  
    end
  
    always begin
      #5 clk <= ~clk;
    end
    

    logic [WORD_WIDTH-1:0] in_data[NUM_TRANS+5];
    logic [WORD_WIDTH-1:0] out_data[NUM_TRANS+5];
    int i=0, j=0;

    task write();
      s_valid_tmp = $urandom();
      if (s_ready == 1'b0)begin
        s_valid  <= s_valid;
      end
      else begin
        s_valid    <= s_valid_tmp;
      end
      //#0ns;
      m_ready_tmp = $urandom();
      m_ready    <= m_ready_tmp;
      if (s_valid_tmp == 1'b1 && s_ready == 1'b1) begin
        s_data  <= $urandom();
      end
      else if (s_ready == 1'b0) begin
        s_data <= s_data;
      end
      else begin
        s_data <= 'X;
      end
      @(posedge clk);
    endtask
    
    always @(posedge clk) begin
      if (s_valid && s_ready) begin
        in_data[i] = s_data;
        `ifdef DEBUG
          $display("INFO:in data is %0h", in_data[i]);
        `endif
        ++i;

      end
      if (m_valid && m_ready) begin
        out_data[j] = m_data;
        `ifdef DEBUG
          $display("INFO:out data is %0h", out_data[j]);
        `endif
        ++j;
      end
    end


    initial begin
      wait  (done == 1'b1);
      //for (int m =0;m < in_data.size(); m++) begin
      for (int m =0;m < i-1; m++) begin
        if (in_data[m] == out_data[m]) begin
          test_passed = 1'b1;
          $display("INFO: DATA CHECK passed in data:%0h out data: %0h m:%0d", in_data[m], out_data[m], m);
        end
        else begin
          $error("INFO: DATA CHECK failed: in data:%0h out data: %0h m:%0d", in_data[m], out_data[m], m);
          test_passed = 1'b0;
        end
      end
      if (test_passed == 1'b1)
        $display("TEST PASSED");
      else
        $error("TEST FAILED");
    end




endmodule
