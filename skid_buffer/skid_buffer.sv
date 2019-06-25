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



/////////////////////////////////////////////
//FV

//s_ready should never be asserted if the buffer is full
no_s_ready_when_full: assert property (
  @(posedge clk) disable iff(!rstn)
  !(state == FULL && s_ready)
);

//m_valid should never be de-asserted if the buffer is full
m_valid_must_when_full: assert property (
  @(posedge clk) disable iff(!rstn)
  ((state == FULL) |=> m_valid)
);

//data output should never change if m_ready isnt available
m_data_stable: assert property (
  @(posedge clk) disable iff(!rstn)
  ((!m_ready && m_valid) |=> $stable(m_data))
);


//full flow operation
flow_operation: assert property (
  @(posedge clk) disable iff (!rstn)
  (m_valid && m_ready && s_valid && s_ready)[*2] |-> (m_data == $past(s_data)) 
);


//reset should clear valids.
RESET_CLEARS_IVALID: assert property (
	@(posedge clk) (!rstn |=> !m_valid)
);

//property IDATA_HELD_WHEN_NOT_READY;
//	@(posedge clk) disable iff (!rstn)
//	s_valid && !s_ready |=> s_valid && $stable(i_data);
//endproperty
//
//assert IDATA_HELD_WHEN_NOT_READY;
// Rule #1:
//	Once o_valid goes high, the data cannot change until the
//	clock after m_ready
IDATA_HELD_WHEN_NOT_READY: assert property (@(posedge clk)
	disable iff (!rstn)
	m_valid && !m_ready
	|=> (m_valid && $stable(m_data)));



cover property (@(posedge clk)
		disable iff (!rstn)
		(!m_valid)
		##1 m_valid &&  s_ready [*3]
		##1 m_valid && !s_ready
		##1 m_valid &&  s_ready [*2]
		##1 m_valid && !s_ready [*2]
		##1 m_valid &&  s_ready [*3]
		// Wait for the design to clear
		##1 m_valid && s_ready [*0:5]);



/////////////////////////////////////////////

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
        next_state     = IDLE;
        data_reg_nxt   = data_reg;
        skid_reg_nxt   = skid_reg;
      end 
      else begin   //neither slave is giving data nor master is consuming data
        next_state     = state;
        data_reg_nxt   = data_reg;
        skid_reg_nxt   = skid_reg;
      end
    FULL:
      if (m_ready) begin
        next_state    = BUSY;
        data_reg_nxt  = skid_reg;
        skid_reg_nxt  = s_data;
      end
  endcase
  //end
end





endmodule

