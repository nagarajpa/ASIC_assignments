///////////////////////////////////////////////////////////
// Spiral matrix module.
// This module takes a matrix as input with dimensions of row and column 
//
// The matrix outputs the matrix elemenets in spiral form i.e it traces the rows and columns in 
//spiral fashion.
//    -> -> -> ->

///////////////////////////////////////////////////////////

module spiral #(
  parameter DATA_WIDTH = 8,
  parameter R_WIDTH  = 3,
  parameter C_WIDTH  = 3
)
(
  input  logic                  clk,
  input  logic                  rstn,
  input  logic [R_WIDTH-1:0]    row, //value of zero is forbidden
  input  logic [C_WIDTH-1:0]    col, //value of zero is forbidden

  input  logic [DATA_WIDTH-1:0] data_in,
  input  logic                  data_in_valid,
  output logic                  data_in_rdy,
  //input  logic                  data_in_last,

  output logic [DATA_WIDTH-1:0] data_out,
  output logic                  data_out_valid,
  input  logic                  data_out_rdy
);


  //parameter derived for max entries in row/column
  parameter MAX_R   = (1 << R_WIDTH);
  parameter MAX_C   = (1 << C_WIDTH);

  logic [R_WIDTH + C_WIDTH-1 :0] total_count, total_count_nxt;


  typedef enum {IDLE, WR_ROW, WR_COL, L2R, U2D, R2L, D2U} st_type;
  st_type state, next_state;


  logic [DATA_WIDTH-1:0] matrix_data[0:MAX_R-1][0:MAX_C-1];
  logic [DATA_WIDTH-1:0] matrix_data_nxt[0:MAX_R-1][0:MAX_C-1];


  logic [R_WIDTH-1:0] wr_addr_r, rd_addr_r, wr_addr_r_nxt, rd_addr_r_nxt;
  logic [C_WIDTH-1:0] wr_addr_c, rd_addr_c, wr_addr_c_nxt, rd_addr_c_nxt; 
  logic [R_WIDTH-1:0] row_reg, row_reg_nxt;
  logic [C_WIDTH-1:0] col_reg, col_reg_nxt;
  logic [R_WIDTH-1:0] row_reg_st, row_reg_st_nxt;
  logic [C_WIDTH-1:0] col_reg_st, col_reg_st_nxt;
  logic data_out_valid_nxt;


  always_ff @(posedge clk or negedge rstn)
  begin
    if (!rstn) begin
      data_in_rdy       <= '0;
      data_out_valid    <= '0;
      total_count       <= '0;
      for (int i =0; i < MAX_R; i++) begin
        for(int j =0; j < MAX_C; j++) begin
          matrix_data[i][j] <= '0;
        end
      end
      state             <= IDLE;
      wr_addr_r         <= '0;
      wr_addr_c         <= '0;
      rd_addr_r         <= '0;
      rd_addr_c         <= '0;
      row_reg           <= '0;
      col_reg           <= '0;
      row_reg_st        <= '0;
      col_reg_st        <= '0;
    end
    else  begin
      data_in_rdy       <= (next_state == IDLE || next_state == WR_ROW || next_state == WR_COL);
      data_out_valid    <= data_out_valid_nxt;//(next_state == L2R || next_state == U2D || next_state == R2L || next_state == D2U);
      total_count       <= total_count_nxt;
      for (int i =0; i < MAX_R; i++) begin
        for(int j =0; j < MAX_C; j++) begin
          matrix_data[i][j] <= matrix_data_nxt[i][j];
        end
      end
      state             <= next_state;
      wr_addr_r         <= wr_addr_r_nxt;
      wr_addr_c         <= wr_addr_c_nxt;
      rd_addr_r         <= rd_addr_r_nxt;
      rd_addr_c         <= rd_addr_c_nxt;
      row_reg           <= row_reg_nxt;
      col_reg           <= col_reg_nxt;
      row_reg_st        <= row_reg_st_nxt;
      col_reg_st        <= col_reg_st_nxt;
    end
  end


  assign data_out = matrix_data[rd_addr_r][rd_addr_c];



  always_comb begin
    for (int i =0; i < MAX_R; i++) begin
      for(int j =0; j < MAX_C; j++) begin
        matrix_data_nxt[i][j] = matrix_data[i][j];
      end
    end
    matrix_data_nxt[wr_addr_r][wr_addr_c] = data_in;
    next_state       =  state;
    wr_addr_r_nxt    =  wr_addr_r;
    wr_addr_c_nxt    =  wr_addr_c;
    rd_addr_r_nxt    =  rd_addr_r;
    rd_addr_c_nxt    =  rd_addr_c;
    total_count_nxt  =  total_count;
    row_reg_nxt      =  row_reg;
    col_reg_nxt      =  col_reg;
    row_reg_st_nxt      =  row_reg_st;
    col_reg_st_nxt      =  col_reg_st;
    data_out_valid_nxt  =  data_out_valid;

    case (state)
      IDLE: begin 
        if (data_in_valid && data_in_rdy) begin
          next_state       =  WR_COL;
          matrix_data_nxt[wr_addr_r][wr_addr_c] = data_in;
          wr_addr_c_nxt    = wr_addr_c + 1'b1; 
          total_count_nxt  = total_count + 1'b1;
          row_reg_nxt      = row;
          col_reg_nxt      = col;
        end
        if (data_in_valid && data_in_rdy && (wr_addr_c + 1'b1) == col) begin
          next_state       = WR_ROW;
          wr_addr_c_nxt    = '0;
          wr_addr_r_nxt    = wr_addr_r + 1'b1;
        end
        if (data_in_valid && data_in_rdy && ((wr_addr_r + 1'b1) == row) && ((wr_addr_c + 1'b1) == col)) begin
          next_state       = L2R;
          row_reg_st_nxt    = row_reg_st + 1'b1;
          data_out_valid_nxt = '1;
          wr_addr_c_nxt    = '0;
          wr_addr_r_nxt    = '0;
        end
      end
      WR_COL: begin
        if(data_in_valid && data_in_rdy && ((wr_addr_c + 1'b1) == col) && ((wr_addr_r+ 1'b1) == row)) begin
          next_state      = L2R;
          row_reg_st_nxt    = row_reg_st + 1'b1;
          data_out_valid_nxt = '1;
          wr_addr_c_nxt   = '0;
          wr_addr_r_nxt   = '0;
        end
        else if(data_in_valid && data_in_rdy && ((wr_addr_c + 1'b1) == col)) begin
          next_state      = WR_ROW;
          wr_addr_c_nxt   = '0;
          wr_addr_r_nxt   = wr_addr_r + 1'b1;
          total_count_nxt = total_count + 1'b1;
        end
        else if (data_in_valid && data_in_rdy) begin
          next_state     = WR_COL;
          wr_addr_c_nxt  = wr_addr_c + 1'b1;
          total_count_nxt = total_count + 1'b1;
        end
      end
      WR_ROW: begin
        if(data_in_valid && data_in_rdy && ((wr_addr_r + 1'b1) == row) && (wr_addr_c + 1'b1) == col) begin
          next_state      = L2R;
          data_out_valid_nxt = '1;
          row_reg_st_nxt    = row_reg_st + 1'b1;
          wr_addr_c_nxt   = '0;
          wr_addr_r_nxt   = '0;
        end
        else if (data_in_valid && data_in_rdy && (wr_addr_c + 1'b1) == col) begin
          next_state      = WR_ROW;
          wr_addr_c_nxt   = '0;
          wr_addr_r_nxt   = wr_addr_r + 1'b1;
          total_count_nxt = total_count + 1'b1;
        end
        else if (data_in_valid && data_in_rdy) begin
          next_state      = WR_COL;
          wr_addr_c_nxt   = wr_addr_c + 1'b1;
          total_count_nxt = total_count + 1'b1;
        end
      end    
      L2R: begin
        if (data_out_valid && data_out_rdy && ((rd_addr_c + 1'b1) == col_reg)) begin
          next_state      = U2D;
          col_reg_nxt     = col_reg - 1'b1;
          rd_addr_r_nxt   = rd_addr_r + 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        else if (data_out_valid && data_out_rdy) begin
          rd_addr_c_nxt   = rd_addr_c + 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        if ( total_count == '0) begin
          next_state         = IDLE;
          rd_addr_r_nxt      = '0;
          rd_addr_c_nxt      = '0;
          data_out_valid_nxt = '0;
        end
      end
      U2D: begin
        if (data_out_valid && data_out_rdy && ((rd_addr_r + 1'b1) == row_reg)) begin
          next_state      = R2L;
          row_reg_nxt     = row_reg - 1'b1;
          rd_addr_c_nxt   = rd_addr_c - 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        else if (data_out_valid && data_out_rdy) begin
          rd_addr_r_nxt   = rd_addr_r + 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        if ( total_count == '0) begin
          next_state      = IDLE;
          rd_addr_r_nxt      = '0;
          rd_addr_c_nxt      = '0;
          data_out_valid_nxt = '0;
        end
      end
      R2L: begin
        if (data_out_valid && data_out_rdy && ((rd_addr_c) == col_reg_st)) begin
          next_state      = D2U;
          col_reg_st_nxt  = col_reg_st + 1'b1;
          rd_addr_r_nxt   = rd_addr_r - 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        else if (data_out_valid && data_out_rdy) begin
          rd_addr_c_nxt   = rd_addr_c - 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        if ( total_count == '0) begin
          next_state      = IDLE;
          rd_addr_r_nxt      = '0;
          rd_addr_c_nxt      = '0;
          data_out_valid_nxt = '0;
        end
      end
      D2U: begin
        if (data_out_valid && data_out_rdy && ((rd_addr_r) == row_reg_st)) begin
          next_state      = L2R;
          row_reg_st_nxt  = row_reg_st + 1'b1;
          rd_addr_c_nxt   = rd_addr_c + 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        else if (data_out_valid && data_out_rdy) begin
          rd_addr_r_nxt   = rd_addr_r - 1'b1;
          total_count_nxt = total_count - 1'b1;
        end
        if ( total_count == '0) begin
          next_state      = IDLE;
          rd_addr_r_nxt      = '0;
          rd_addr_c_nxt      = '0;
          data_out_valid_nxt = '0;
        end
      end
    endcase

  end

endmodule
