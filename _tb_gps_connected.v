`timescale 1ns/1ps
module tb_gps_connected;
  reg clk = 0;
  reg rst = 1;
  always #10 clk = ~clk; // 50 MHz

  integer i;
  integer k;
  integer j;
  integer timeout;

  reg tx_line = 1;

  wire [7:0] rx_byte;
  wire       rx_valid;

  uart_rx #(.CLK_FREQ(50_000_000), .BAUD(9600)) U_RX (
    .clk(clk),
    .rst(rst),
    .rx(tx_line),
    .data(rx_byte),
    .valid(rx_valid)
  );

  wire        lat_ready, lon_ready;
  wire        sign_lat, sign_lon;
  wire [7:0]  lat_len, lon_len;
  wire [8*16-1:0] lat_vec, lon_vec;

  nmea_parser U_P (
    .clk(clk),
    .rst(rst),
    .in_char(rx_byte),
    .in_valid(rx_valid),
    .lat_ready(lat_ready),
    .lon_ready(lon_ready),
    .sign_lat(sign_lat),
    .sign_lon(sign_lon),
    .lat_len(lat_len),
    .lon_len(lon_len),
    .lat_vec(lat_vec),
    .lon_vec(lon_vec)
  );

  wire [31:0] lat_q; wire lat_q_valid;
  wire [31:0] lon_q; wire lon_q_valid;

  ascii_to_fixed U_LAT (
    .clk(clk),
    .rst(rst),
    .in_valid(lat_ready),
    .is_lon(1'b0),
    .ascii_vec(lat_vec),
    .length(lat_len),
    .sign(sign_lat),
    .deg_q16_16(lat_q),
    .out_valid(lat_q_valid)
  );

  ascii_to_fixed U_LON (
    .clk(clk),
    .rst(rst),
    .in_valid(lon_ready),
    .is_lon(1'b1),
    .ascii_vec(lon_vec),
    .length(lon_len),
    .sign(sign_lon),
    .deg_q16_16(lon_q),
    .out_valid(lon_q_valid)
  );

  wire [8*32-1:0] lat_out_vec; wire lat_str_valid;
  wire [8*32-1:0] lon_out_vec; wire lon_str_valid;

  formatter U_FMT_LAT (
    .clk(clk),
    .rst(rst),
    .q16_16(lat_q),
    .in_valid(lat_q_valid),
    .label0("l"),
    .label1("a"),
    .label2("t"),
    .label3(":"),
    .out_vec(lat_out_vec),
    .out_valid(lat_str_valid)
  );

  formatter U_FMT_LON (
    .clk(clk),
    .rst(rst),
    .q16_16(lon_q),
    .in_valid(lon_q_valid),
    .label0("l"),
    .label1("o"),
    .label2("n"),
    .label3(":"),
    .out_vec(lon_out_vec),
    .out_valid(lon_str_valid)
  );

  task send_uart_byte(input [7:0] b);
    integer ii;
    begin
      tx_line <= 1'b0; #(104_166); // start bit
      for (ii = 0; ii < 8; ii = ii + 1) begin
        tx_line <= b[ii]; #(104_166);
      end
      tx_line <= 1'b1; #(104_166); // stop bit
    end
  endtask

  task send_gprmc_example;
    begin
      reg [8*128-1:0] line;
      reg [7:0] ch;
      line = "$GPRMC,123519,A,4807.038,N,01131.000,E,0.0,0.0,230394,,*00\r\n";
      for (k = 0; k < 128; k = k + 1) begin
        ch = line[8*128-1-8*k -: 8];
        if (ch == 8'd0) begin
          k = 128; // fin de cadena
        end else begin
          send_uart_byte(ch);
        end
      end
    end
  endtask

  task print_vec(input [8*32-1:0] v);
    reg [7:0] ch;
    begin
      for (j = 0; j < 32; j = j + 1) begin
        ch = v[8*(32-j)-1 -: 8];
        if (ch != 8'd0) $write("%s", ch);
      end
    end
  endtask

  initial begin
    $dumpfile("gps.vcd");
    $dumpvars(0, tb_gps_connected);
    #100 rst = 0;

    send_gprmc_example();

    timeout = 0;
    while (!lat_str_valid && timeout < 20000000) begin
      #1000; timeout = timeout + 1;
    end
    if (lat_str_valid) begin
      $write("LAT: "); print_vec(lat_out_vec); $write("\n");
    end else $write("LAT: no disponible (timeout)\n");

    timeout = 0;
    while (!lon_str_valid && timeout < 20000000) begin
      #1000; timeout = timeout + 1;
    end
    if (lon_str_valid) begin
      $write("LON: "); print_vec(lon_out_vec); $write("\n");
    end else $write("LON: no disponible (timeout)\n");

    #100000 $finish;
  end

endmodule

