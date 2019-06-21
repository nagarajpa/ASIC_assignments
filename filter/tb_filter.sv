module tb_filter();
  // 2^M is the number of samples used in the filter
  parameter M = 2;
  // N is the number of bits of the input and output samples
  parameter N = 8;
    

  logic         clk; // posedge
  logic         rstn; // asynchronous, active low
  logic [N-1:0] sample;
  logic         sample_valid; // active high
  logic [N-1:0] average;
  logic         average_valid; // active high

  filter #(M, N) dut (.*);


  logic done;

  initial begin
    done <= 1'b0;
    clk  <= 1'b0;
    rstn <= 1'b0;
    sample_valid <= 1'b0;
    repeat (10) begin
      @(posedge clk);
    end
    rstn <= 1'b1;
    @(posedge clk);
    
    write_new(4);
    @(posedge clk);
    write_new(10);
    @(posedge clk);
    write_new(2);
    @(posedge clk);
    write_new(3);
    @(posedge clk);

  
  end


    
  always begin
    #5 clk <= ~clk;
  end



  task write_new (input int count);
    for (int i=0; i < count; i++) begin
      sample_valid <= 1'b1;
      sample       <= $urandom();
      @(posedge clk);
    end
    sample_valid  <= 1'b0;
  endtask  

endmodule
