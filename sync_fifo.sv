module sync_fifo #(parameter depth = 8, dwidth = 16) 
  (
    input clk, rst, wr_en, rd_en,
    input [dwidth-1:0]wr_data,
    output reg [dwidth-1:0] rd_data,
    output full, empty
  );
  reg [$clog2(depth):0] w_ptr;
  reg [$clog2(depth):0] r_ptr;
  
  reg [dwidth-1:0] fifo[depth];
  
  always @(posedge clk) begin
    if (rst) begin
      w_ptr <= 0;
    end
    else begin
      if (wr_en && !full) begin
        fifo[w_ptr] <= wr_data;
        w_ptr <= w_ptr+1;
      end
    end
  end 
  
  always @(posedge clk) begin
    if (rst) begin
      r_ptr <= 0;
    end
    else begin
      if (rd_en && !empty) begin
        rd_data <= fifo[r_ptr];
        r_ptr <= r_ptr+1;
      end
    end
  end
  
  assign full = {~w_ptr[$clog2(depth)],w_ptr[$clog2(depth)-1:0]}=={r_ptr};
  assign empty = w_ptr==r_ptr;
  
endmodule
