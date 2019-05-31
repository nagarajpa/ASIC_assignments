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

endmodule
