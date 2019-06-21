////////////////////////////////////////////////////////
// Simple moving average filter calculator.
// Calculates the average of last 2**M samples that have been input.

// design uses flops for storage as the input cant be backpressured.




////////////////////////////////////////////////////////
module filter #(
    // 2^M is the number of samples used in the filter
    parameter M = 2,
    // N is the number of bits of the input and output samples
    parameter N = 16
) (
    input  logic         clk, // posedge
    input  logic         rstn, // asynchronous, active low
    input  logic [N-1:0] sample,
    input  logic         sample_valid, // active high
    output logic [N-1:0] average,
    output logic         average_valid // active high
);

parameter NUM_SAMPLES = 2**M;


logic [N-1:0] mem_data[0:2**M-1];
logic [M+N-1:0]        sum, sum_nxt;

logic [M-1:0] wr_addr, wr_addr_nxt, rd_addr, rd_addr_nxt;
logic [M-1:0] count, count_nxt;
logic count_reached;
logic [N-1:0] old_sample, old_sample_nxt;

always_ff @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    wr_addr       <= '0;
    rd_addr       <= '1;
    count_reached <= '0;
    sum           <= '0;
    average_valid <= '0;
    old_sample    <= '0;
    for (int i = 0; i < NUM_SAMPLES; i++) begin
      mem_data[i] <= '0;
    end
  end
  else begin
    wr_addr       <= wr_addr_nxt;
    rd_addr       <= rd_addr_nxt;
    count_reached <= ((rd_addr == '0) || count_reached);
    sum           <= sum_nxt;
    average_valid <=  ((count_reached || rd_addr == '0) && sample_valid);
    old_sample    <= old_sample_nxt; 
    for (int i = 0; i < NUM_SAMPLES; i++) begin
      mem_data[i] <= mem_data[i];
    end
    if(sample_valid) begin
      mem_data[wr_addr] <= sample;
    end
  end
end

assign wr_addr_nxt = sample_valid ? (wr_addr+1'b1) : wr_addr;
assign old_sample_nxt  =  average_valid ? mem_data[rd_addr] : old_sample;

always_comb begin
  rd_addr_nxt = rd_addr;
  // rd_addr is doubled as down counter to count 2**M samples - the initial wait period
  //rd_addr decrements if count is not reached and increments with sample valid when count has reached
  if (count_reached) begin
    if (sample_valid) begin
      rd_addr_nxt = rd_addr + 1'b1;
    end
    else begin
      rd_addr_nxt = rd_addr;
    end
  end
  else begin
    if (sample_valid && (rd_addr != '0)) begin
      rd_addr_nxt = rd_addr -1'b1;
    end
    else begin
      rd_addr_nxt = rd_addr;
    end
  end
end




assign sum_nxt     = sample_valid? (sum + ({N{sample_valid}} & sample) - old_sample_nxt): sum; 

assign average     = sum >> M;



endmodule
