module tb_counter
();
  parameter WIDTH = 8;

  logic clk;
  logic rstn;
  logic [WIDTH-1:0] counter;


  counter counter1(.*);

  initial begin
    clk = 1'b0;
    rstn = 1'b0;
    #25ns;
    rstn = 1'b1;

  end

  always begin
    #5 clk = ~clk;
  end



endmodule
