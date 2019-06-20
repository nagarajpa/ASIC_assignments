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



  spiral #(DATA_WIDTH, R_WIDTH, C_WIDTH) dut(.*);


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
    
    write_new(3'b111,3'b101);
    @(posedge clk);
    wait (data_in_rdy == 1'b1);
    write_new(3'b010, 3'b110);
    @(posedge clk);
    wait (data_in_rdy == 1'b1);
    write_new(3'b001, 3'b100);
    @(posedge clk);
    wait (data_in_rdy == 1'b1);
    write_new(3'b111, 3'b001);
    @(posedge clk);
    wait (data_in_rdy == 1'b1);
    write_new(3'b111, 3'b010);
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


  task write_new (input logic [R_WIDTH-1:0] rowt, input logic [C_WIDTH-1:0] colt);
    //logic tmp;
    col <= colt;
    row <= rowt;

    for (logic [R_WIDTH-1:0] i=0;i < rowt; i++ ) begin
      for(logic [C_WIDTH-1:0] j=0; j < colt; j++) begin
        //tmp = $urandom(); 
        data_in_valid <= 1'b1;//$urandom(); //tmp;

        //if (tmp == 1'b1) 
          data_in       <= $urandom();
        //else
        //  data_in     <= data_in;
        @(posedge clk);
        wait (data_in_rdy == 1'b1);
      end
    end
    data_in_valid <= '0;
  endtask
  
  endmodule
