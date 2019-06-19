module tb_spiral ();


  parameter DATA_WIDTH = 8;
  parameter R_WIDTH  = 3;
  parameter C_WIDTH  = 3;
  
  logic                  clk;
  logic                  rstn;
  logic [R_WIDTH-1:0]    row;
  logic [C_WIDTH-1:0]    col;
  logic [DATA_WIDTH-1:0] data_in;
  logic                  data_in_valid;
  logic                  data_in_rdy;
  logic [DATA_WIDTH-1:0] data_out;
  logic                  data_out_valid;
  logic                  data_out_rdy;



  spiral dut(.*);


  logic done;

  initial begin
    done <= 1'b0;
    clk  <= 1'b0;
    rstn <= 1'b0;
    data_out_rdy <= 1'b1;
    repeat (10) begin
      @(posedge clk);
    end
    rstn <= 1'b1;
    @(posedge clk);
    write(3'b100,3'b100);
    @(posedge clk);
  end


    
  always begin
    #5 clk <= ~clk;
  end
  

  task write(input logic [R_WIDTH-1:0] row_t, input logic [C_WIDTH-1:0] col_t);
    row = row_t;
    col = col_t;
    for(int i =0; i < row; ++i) begin
      for(int j=0; j < col; ++i) begin
        data_in_valid <= 1'b1;
        data_in       <= $urandom();
        @(posedge clk);
        wait (data_in_rdy == 1'b1);
      end
    end  
  endtask

  
  
  endmodule
