module nmea_parser (
  input  wire       clk,
  input  wire       rst,
  input  wire [7:0] in_char,
  input  wire       in_valid,
  output reg        lat_ready,
  output reg        lon_ready,
  output reg        sign_lat,           
  output reg        sign_lon,           
  output reg [7:0]  lat_len,            
  output reg [7:0]  lon_len,
  output reg [8*16-1:0] lat_vec,        
  output reg [8*16-1:0] lon_vec         
);

  reg [2:0] state;
  reg [7:0] field_idx;
  reg [7:0] lat_ptr, lon_ptr;

  reg [7:0] tag_buf0, tag_buf1, tag_buf2, tag_buf3, tag_buf4;
  reg [2:0] tag_ptr;
  reg       tag_ok;

  reg [7:0] lat_buf [0:15];
  reg [7:0] lon_buf [0:15];

  integer i;

  initial begin
    lat_vec = {8{8'd0}};
    lon_vec = {8{8'd0}};
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= 0; field_idx <= 0;
      lat_ptr <= 0; lon_ptr <= 0;
      lat_ready <= 0; lon_ready <= 0;
      sign_lat <= 0; sign_lon <= 0;
      lat_len <= 0; lon_len <= 0;
      tag_ptr <= 0; tag_ok <= 0;
      for (i=0; i<16; i=i+1) begin
        lat_buf[i] <= 8'd0; lon_buf[i] <= 8'd0;
      end
      lat_vec <= {128{1'b0}};
      lon_vec <= {128{1'b0}};
    end else begin
      lat_ready <= 0; lon_ready <= 0;
      if (in_valid) begin
        if (in_char == 8'h24) begin 
          state <= 1; field_idx <= 0; tag_ptr <= 0; tag_ok <= 0;
          lat_ptr <= 0; lon_ptr <= 0;
          lat_len <= 0; lon_len <= 0;
        end else begin
          case (state)
            1: begin 
              if (in_char == 8'h2C) begin
                tag_ok <= (tag_ptr==5 &&
                           tag_buf0=="G" && tag_buf1=="P" &&
                           tag_buf2=="R" && tag_buf3=="M" &&
                           tag_buf4=="C");
                state <= 2; field_idx <= 1;
              end else begin
                if (tag_ptr == 0) tag_buf0 <= in_char;
                else if (tag_ptr == 1) tag_buf1 <= in_char;
                else if (tag_ptr == 2) tag_buf2 <= in_char;
                else if (tag_ptr == 3) tag_buf3 <= in_char;
                else if (tag_ptr == 4) tag_buf4 <= in_char;
                tag_ptr <= (tag_ptr < 5) ? (tag_ptr + 1) : tag_ptr;
              end
            end
            2: begin 
              if (in_char == 8'h2C) begin
                field_idx <= field_idx + 1;
                if (tag_ok && field_idx == 2) begin
                  state <= 3; lat_ptr <= 0;
                end
              end
            end
            3: begin
              if (in_char == 8'h2C) begin
                lat_len <= lat_ptr; state <= 4;
              end else begin
                if (lat_ptr < 16) begin
                  lat_buf[lat_ptr] <= in_char; lat_ptr <= lat_ptr + 1;
                end
              end
            end
            4: begin 
              if (in_char == "S") sign_lat <= 1'b1;
              else if (in_char == "N") sign_lat <= 1'b0;
              if (in_char == 8'h2C) begin
                state <= 5; lon_ptr <= 0;
              end
            end
            5: begin 
              if (in_char == 8'h2C) begin
                lon_len <= lon_ptr; state <= 6;
              end else begin
                if (lon_ptr < 16) begin
                  lon_buf[lon_ptr] <= in_char; lon_ptr <= lon_ptr + 1;
                end
              end
            end
            6: begin 
              if (in_char == "W") sign_lon <= 1'b1;
              else if (in_char == "E") sign_lon <= 1'b0;
              
              lat_vec <= {
                lat_buf[15],lat_buf[14],lat_buf[13],lat_buf[12],
                lat_buf[11],lat_buf[10],lat_buf[9], lat_buf[8],
                lat_buf[7], lat_buf[6], lat_buf[5], lat_buf[4],
                lat_buf[3], lat_buf[2], lat_buf[1], lat_buf[0]
              };
              lon_vec <= {
                lon_buf[15],lon_buf[14],lon_buf[13],lon_buf[12],
                lon_buf[11],lon_buf[10],lon_buf[9], lon_buf[8],
                lon_buf[7], lon_buf[6], lon_buf[5], lon_buf[4],
                lon_buf[3], lon_buf[2], lon_buf[1], lon_buf[0]
              };
              lat_ready <= 1; lon_ready <= 1; state <= 7;
            end
            default: ; 
          endcase
        end
      end
    end
  end
endmodule

