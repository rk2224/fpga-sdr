module CORDIC_Algo(
  input logic clk,
  input logic rst,
  input logic cordic_en,
  input logic signed [54:0] re,
  input logic signed [54:0] im, 
  output logic signed [18:0] z_angle
);

 logic signed [54:0] x;
 logic signed [54:0] y;
 logic signed [18:0] z;
 logic [3:0] running;
 logic [2:0] quadrant;
 logic first_value;
 logic [3:0] iteration_number;
 logic signed [18:0] angle;

 CORDIC_values angle_lut (
  .iteration_number(iteration_number),
  .angle(angle)
 );
 
 always_ff @(posedge clk) begin
  if (rst) begin
   x <= '0;
   y <= '0;
   z <= '0;
   quadrant <= '0;
   z_angle <= '0;
   first_value <= '0;
   iteration_number <= '0;
   running <= '0;
  end
  else begin
   if (!first_value && cordic_en) begin
    z <= '0;
    if ((re >= 0) && (im >= 0)) begin
     x <= re;
     y <= im;
     quadrant <= 3'd1;
    end
    else if ((re < 0) && (im >= 0)) begin
     x <= -re;
     y <= im;
     quadrant <= 3'd2;
    end
    else if ((re < 0) && (im < 0)) begin
     x <= -re;
     y <= -im;
     quadrant <= 3'd3;
    end
    else if ((re >= 0) && (im < 0)) begin
     x <= re;
     y <= -im;
     quadrant <= 3'd4;
    end
   
    first_value <= 1; 
    running <= 4'd10;
   end
   if (first_value && (running > 0)) begin
    if (iteration_number < 4'd10) begin 
     iteration_number <= iteration_number + 1;
     if (y > 0) begin
     x <= x + (y >>> iteration_number);
     y <= y - (x >>> iteration_number);
     z <= z + angle;
     end
     else if (y < 0) begin
     x <= x - (y >>> iteration_number);
     y <= y + (x >>> iteration_number);
     z <= z - angle;
     end
     running <= running - 1;
    end
   end
    if (iteration_number == 4'd10) begin
     if (quadrant == 3'd1) begin
      z_angle <= z;
     end 
     if (quadrant == 3'd2) begin
      z_angle <= 205887 - z;
     end 
     if (quadrant == 3'd3) begin
      z_angle <= z - 205887;
     end 
     if (quadrant == 3'd4) begin
      z_angle <= -z;
     end 

     first_value <= 0;
     iteration_number <= 0;
    end
   end
  end
 

endmodule
 

