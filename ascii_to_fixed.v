module ascii_to_fixed (
  input  wire        clk,
  input  wire        rst,
  input  wire        in_valid,
  input  wire        is_lon,          
  input  wire [8*16-1:0] ascii_vec,   
  input  wire [7:0]  length,         
  input  wire        sign,            
  output reg  [31:0] deg_q16_16,
  output reg         out_valid
);

  wire [7:0] b0 = ascii_vec[8*16-1 -: 8];
  wire [7:0] b1 = ascii_vec[8*15-1 -: 8];
  wire [7:0] b2 = ascii_vec[8*14-1 -: 8];
  wire [7:0] b3 = ascii_vec[8*13-1 -: 8];
  wire [7:0] b4 = ascii_vec[8*12-1 -: 8];
  wire [7:0] b5 = ascii_vec[8*11-1 -: 8];
  wire [7:0] b6 = ascii_vec[8*10-1 -: 8];
  wire [7:0] b7 = ascii_vec[8*9 -1 -: 8];
  wire [7:0] b8 = ascii_vec[8*8 -1 -: 8];
  wire [7:0] b9 = ascii_vec[8*7 -1 -: 8];

  reg [31:0] dd, mm_int, frac;
  reg [31:0] mm_frac_q16, mm_total_q16, mm_div60_q16, dd_q16, q_deg;
  reg        busy;

  function [7:0] to_digit;
    input [7:0] ch;
    begin
      to_digit = (ch >= "0" && ch <= "9") ? (ch - "0") : 8'd0;
    end
  endfunction

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      deg_q16_16 <= 0; out_valid <= 0; busy <= 0;
      dd <= 0; mm_int <= 0; frac <= 0;
      mm_frac_q16 <= 0; mm_total_q16 <= 0; mm_div60_q16 <= 0; dd_q16 <= 0; q_deg <= 0;
    end else begin
      out_valid <= 0;
      if (in_valid && !busy) begin
        busy <= 1'b1;

        // parse
        if (!is_lon) begin
          dd     <= to_digit(b0)*10 + to_digit(b1);
          mm_int <= to_digit(b2)*10 + to_digit(b3);
          frac   <= to_digit(b5)*1000 + to_digit(b6)*100 + to_digit(b7)*10 + to_digit(b8);
        end else begin
          dd     <= to_digit(b0)*100 + to_digit(b1)*10 + to_digit(b2);
          mm_int <= to_digit(b3)*10 + to_digit(b4);
          frac   <= to_digit(b6)*1000 + to_digit(b7)*100 + to_digit(b8)*10 + to_digit(b9);
        end

        mm_frac_q16 <= (frac * 32'd65536) / 32'd10000;
        mm_total_q16 <= (mm_int << 16) + mm_frac_q16;
        mm_div60_q16 <= mm_total_q16 / 32'd60;
        dd_q16 <= (dd << 16);
        q_deg <= dd_q16 + mm_div60_q16;

        deg_q16_16 <= (sign ? -q_deg : q_deg);
        out_valid <= 1;
        busy <= 1'b0;
      end
    end
  end
endmodule

