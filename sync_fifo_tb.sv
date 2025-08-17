class generator;
  rand bit wr_en;
  rand bit rd_en;
  rand bit [15:0] wr_data;

  // constraint: if write enable = 0, data doesn’t matter
  constraint wr_c { if (!wr_en) wr_data == '0; }
endclass

// ---------------- SCOREBOARD -----------------
class scoreboard;
  bit [15:0] expected_q[$];  // dynamic queue for expected values

  // Store written data
  function void write(bit [15:0] data);
    expected_q.push_back(data);
  endfunction

  // Compare read data
  function void read(bit [15:0] data);
    if (expected_q.size() == 0) begin
      $display("[%0t] [SCOREBOARD] ERROR: Read attempted but queue empty!", $time);
    end else begin
      bit [15:0] exp = expected_q.pop_front();
      if (exp !== data) begin
        $display("[%0t] [SCOREBOARD] MISMATCH exp=0x%0h got=0x%0h", $time, exp, data);
      end else begin
        $display("[%0t] [SCOREBOARD] MATCH exp=0x%0h got=0x%0h", $time, exp, data);
      end
    end
  endfunction
endclass
// ------------------------------------------------

module tb;
  generator gen;
  scoreboard sb;

  parameter d = 8;
  parameter w = 16;

  bit clk, rst, wr_en, rd_en, full, empty;
  bit [w-1:0] wr_data, rd_data;

  sync_fifo #(d, w) dut (
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst = 1;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;
    sb = new();   // create scoreboard
    #12 rst = 0; 
  end

  initial begin
    gen = new();
    repeat (20) begin
      @(posedge clk);
      void'(gen.randomize()); // safe randomize
      wr_en   = gen.wr_en;
      rd_en   = gen.rd_en;
      wr_data = gen.wr_data;

      // send write transactions to scoreboard
      if (wr_en && !full) begin
        sb.write(wr_data);
      end

      // check read transactions against scoreboard
      if (rd_en && !empty) begin
        sb.read(rd_data);
      end
    end
    #100 $finish;
  end

  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    $monitor("[%0t] [FIFO] wr_en=%0b wr_data=0x%0d  rd_en=%0b rd_data=0x%0d empty=%0b full=%0b",
             $time, wr_en, wr_data, rd_en, rd_data, empty, full);
  end
endmodule
