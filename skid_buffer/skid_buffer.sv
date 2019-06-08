//SKID BUFFER is used to pipeline the AXI like interface.
//the axi valid-ready handshake channel can't be pipelined by simply adding the register slice on all signals.
//As there is a risk of overwriting the data, as the ready reaches 1 clock late.
//one solution is to not flop the ready signal and pass it directly to slave interface but this defeats the purpose as now ready becomes timing critical.
//The more common solution is to add an additional buffer for data more popularly known as skid buffer.



module skid_buffer
#(
    parameter WORD_WIDTH = 8 
)
(
    input   logic                        clk,
    input   logic                        rstn,

    // Slave interface
    input   logic                        s_valid,
    output  logic                        s_ready,
    input   logic    [WORD_WIDTH-1:0]    s_data,

    // Master interface
    output  logic                        m_valid,
    input   logic                        m_ready,
    output  logic    [WORD_WIDTH-1:0]    m_data
);

typedef enum {IDLE, BUSY, FULL} st_type;

st_type state, next_state;

logic [WORD_WIDTH-1:0] skid_reg, skid_reg_nxt;
logic [WORD_WIDTH-1:0] data_reg, data_reg_nxt;


always_ff  @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    state          <= IDLE;
    data_reg       <= '0;
    skid_reg       <= '0;
    m_valid        <= '0;
    s_ready        <= '1;
  end
  else begin
    state          <= next_state;
    data_reg       <= data_reg_nxt;
    skid_reg       <= skid_reg_nxt;
    m_valid        <= (next_state != IDLE);
    s_ready        <= (next_state != FULL);
  end
end


assign m_data  = data_reg;
//assign m_valid = (state != IDLE);
//assign s_ready = (state != FULL);

always_comb begin
  next_state   = state; 
  data_reg_nxt = data_reg;
  skid_reg_nxt = skid_reg;
  
  case (state) 
  //begin
    IDLE:
      if (s_valid) begin
        next_state     = BUSY;
        data_reg_nxt   = s_data;
        skid_reg_nxt   = s_data;
      end
      else if (!s_valid && m_ready) begin
        next_state = IDLE;
        data_reg_nxt   = data_reg;
        skid_reg_nxt   = skid_reg;
      end
    BUSY:
      if(s_valid && m_ready) begin //both master and slave are actively transferring data
        next_state     = BUSY;
        data_reg_nxt   = s_data;
        skid_reg_nxt   = s_data;
      end
      else if (s_valid && !m_ready) begin //slave is giving but master aint taking, hence we become full
        next_state     = FULL;
        data_reg_nxt   = data_reg;
        skid_reg_nxt   = s_data;
      end
      else if (!s_valid && m_ready) begin //slave is not giving but master consumed the date
        next_state = IDLE;
        data_reg_nxt  = data_reg;
        skid_reg_nxt   = skid_reg;
      end 
      else begin   //neither slave is giving data nor master is consuming data
        next_state     = state;
        data_reg_nxt  = data_reg;
        skid_reg_nxt  = skid_reg;
      end
    FULL:
      if (m_ready) begin
        next_state     = BUSY;
        data_reg_nxt   = skid_reg;
        skid_reg_nxt  = s_data;
      end
  endcase
  //end
end

endmodule

