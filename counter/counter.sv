/////////////////////////////////////
//   Counter module
//
//  Counter that counts all the counts except multiples of 3
// that is the sequence is 0,1,2,4,5,7,8.....254,0 and so on
////////////////////////////////////



module counter
#(
  parameter WIDTH = 8
)
(
  input logic clk,
  input logic rstn,
  output logic [WIDTH-1:0] counter
);

logic [1:0] count;
logic [WIDTH-1:0] counter_mod;

always_ff @(posedge clk or negedge rstn)
begin
  if (!rstn) begin
    count <= '0;
  end
  else if (counter == 8'd254)begin
    count <= '0;
  end
  else if (count == 2'b10) begin
    count <= 2'b01;
  end
  else begin
    count <= count + 1;
  end
end


always_ff @(posedge clk or negedge rstn)
begin
  if (!rstn) begin
    counter <= '0;
  end
  else if (count == 2'b10) begin
    counter <= counter + 2;
  end
  else begin 
    counter <= counter +1;
  end
end

//FV
assert property (
  @(posedge clk) disable iff(!rstn || counter == '0)
  (counter % 3 != '0)
);

endmodule
