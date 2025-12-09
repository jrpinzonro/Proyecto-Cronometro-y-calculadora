module uart_rx #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD     = 9600
)(
  input  wire clk,
  input  wire rst,
  input  wire rx,           
  output reg  [7:0] data,   
  output reg        valid   
);

  localparam integer BAUD_DIV = CLK_FREQ / BAUD;
  localparam integer MID_SAMPLE = BAUD_DIV/2;

  reg [15:0] cnt;
  reg [3:0]  bit_idx;
  reg        busy;
  reg        rx_sync1, rx_sync2;
  reg [7:0]  shreg;

  always @(posedge clk) begin
    rx_sync1 <= rx;
    rx_sync2 <= rx_sync1;
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      cnt <= 0; bit_idx <= 0; busy <= 0; shreg <= 0; data <= 0; valid <= 0;
    end else begin
      valid <= 0;
      if (!busy) begin
        if (rx_sync2 == 1'b0) begin
          busy <= 1'b1; cnt <= MID_SAMPLE; bit_idx <= 0;
        end
      end else begin
        if (cnt == BAUD_DIV-1) begin
          cnt <= 0;
          if (bit_idx == 0) begin
            if (rx_sync2 != 1'b0) busy <= 1'b0; // error
            bit_idx <= bit_idx + 1;
          end else if (bit_idx >= 1 && bit_idx <= 8) begin
            shreg <= {rx_sync2, shreg[7:1]};
            bit_idx <= bit_idx + 1;
          end else if (bit_idx == 9) begin
            data <= shreg; valid <= 1'b1; busy <= 1'b0;
          end
        end else begin
          cnt <= cnt + 1;
        end
      end
    end
  end

endmodule

