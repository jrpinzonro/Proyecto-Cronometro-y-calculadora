module formatter (
  input  wire        clk,
  input  wire        rst,
  input  wire [31:0] q16_16,
  input  wire        in_valid,
  input  wire [7:0]  label0,
  input  wire [7:0]  label1,
  input  wire [7:0]  label2,
  input  wire [7:0]  label3,
  output reg  [8*32-1:0] out_vec,
  output reg         out_valid
);

  reg [31:0] val;
  reg        neg;
  reg [31:0] int_part, frac_part, frac_dec;
  reg [31:0] d2, d1, d0;
  reg [31:0] f5,f4,f3,f2,f1,f0;

  function [7:0] to_char;
    input [31:0] d;
    begin
      to_char = "0" + d[3:0];
    end
  endfunction

  task putc;
    input integer pos;
    input [7:0] ch;
    begin
      out_vec[8*(32-pos)-1 -: 8] = ch;
    end
  endtask

  integer i;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      out_valid <= 0;
      out_vec <= {256{1'b0}};
    end else begin
      out_valid <= 0;
      if (in_valid) begin
        // calcula partes
        neg = q16_16[31];
        val = neg ? -q16_16 : q16_16;
        int_part = val >> 16;
        frac_part = val & 32'hFFFF;
        frac_dec = (frac_part * 32'd1_000_000) / 32'd65536;

        d2 = (int_part/100)%10;
        d1 = (int_part/10)%10;
        d0 = int_part%10;

        f5 = (frac_dec/100000)%10;
        f4 = (frac_dec/10000)%10;
        f3 = (frac_dec/1000)%10;
        f2 = (frac_dec/100)%10;
        f1 = (frac_dec/10)%10;
        f0 = frac_dec%10;

        out_vec <= {256{1'b0}};

        putc(0,label0); putc(1,label1); putc(2,label2); putc(3,label3);
        putc(4,8'h20);
        putc(5,(neg ? "-" : "+"));
        putc(6,to_char(d2));
        putc(7,to_char(d1));
        putc(8,to_char(d0));
        putc(9,".");
        putc(10,to_char(f5));
        putc(11,to_char(f4));
        putc(12,to_char(f3));
        putc(13,to_char(f2));
        putc(14,to_char(f1));
        putc(15,to_char(f0));
        putc(16,8'h0A);

        out_valid <= 1;
      end
    end
  end
endmodule

