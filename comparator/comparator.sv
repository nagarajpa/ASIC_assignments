//comparator that outputs the index of the input that is max
//the number of inputs and width of inputs are configurable
// the Binary tree implements is faster version as the comparisons are done is parallel.

module comparator 
#(
  parameter DATA_WIDTH  = 16,
  parameter BINARY_TREE = 1,
  parameter NUM_INPUTS  = 16
)
(
  input  logic [DATA_WIDTH-1 : 0]         cmp_ip[NUM_INPUTS],
  output logic [$clog2(NUM_INPUTS)-1 :0]  out
);

  generate if (BINARY_TREE == 0) begin
  
    always_comb begin
      out      = '0;
      for (int i =0; i < NUM_INPUTS; ++i) begin
        if (cmp_ip[i] > cmp_ip[out]) begin
          out      = i;
        end
      end
    end
  
  end else begin
    
    logic [$clog2(NUM_INPUTS)-1 : 0] out_stg[$clog2(NUM_INPUTS) + 1][NUM_INPUTS];
    logic [DATA_WIDTH-1 : 0]         cmp_stg[$clog2(NUM_INPUTS) + 1][NUM_INPUTS];
    
    
    always_comb begin
      for (int i = 0; i < NUM_INPUTS; i++) begin
        cmp_stg[0][i]  = cmp_ip[i];
        out_stg[0][i]  = i;
      end
    end
    
    
    always_comb begin
      for (int i = 0;i < $clog2(NUM_INPUTS); i++) begin
        for (int j = 0;j < NUM_INPUTS; ++j) begin
          out_stg[i+1][j]    = 'X;
          cmp_stg[i+1][j]    = 'X;
        end
      end
    
    
      for (int i = 0;i < $clog2(NUM_INPUTS); i++) begin
        for (int j = 0;j < (NUM_INPUTS/2**i); j= j+2) begin
          if (cmp_stg[i][j] > cmp_stg[i][j+1]) begin
            out_stg[i+1][j/2]    = out_stg[i][j];
            cmp_stg[i+1][j/2]    = cmp_stg[i][j];
          end else begin
            out_stg[i+1][j/2]    = out_stg[i][j+1];
            cmp_stg[i+1][j/2]    = cmp_stg[i][j+1];
          end
        end
      end
      out   = out_stg[$clog2(NUM_INPUTS)][0];
    end
  end
  endgenerate



`ifndef SYNTHESIS
  logic [DATA_WIDTH-1 : 0] max_check;

  //FV assertions
  always @(*) begin
    max_check  =  '0; 
    for (int i =0; i < NUM_INPUTS; ++i) begin
      if (cmp_ip[i] > max_check)
        max_check = cmp_ip[i];
    end
    assert  (
      max_check == cmp_ip[out]
    ); 

  end
`endif



endmodule

