module FIR1(
 input logic clk,
 input logic rst,
 input logic en,
 input logic signed [14:0] signal,
 output logic signed [20:0] filtered_signal
);

 logic signed [14:0] registers [49:0];
 logic signed [14:0] snapshot [49:0];
 logic signed [9:0] coefficients [49:0];
 logic busy;
 logic [5:0] counter;
 logic [5:0] conv_en;
 logic [5:0] address_en;
 logic signed [9:0] rom_q;
 logic signed [30:0] sum;
 integer i;
 integer j;
 integer k;

 FIR_rom FIR_coefficients(
  .clk(clk),
  .address(address_en),
  .q(rom_q)
 );

 always_ff @(posedge clk) begin 
 
  if (rst) begin
   conv_en <= '0;
   address_en <= '0;
   filtered_signal <= '0;
   busy <= 1'b0;
   counter <= '0;
   sum <= '0;
   for (i = 0; i < 50; i++) begin
    registers[i] <= '0;
    coefficients[i] <= '0;
    snapshot[i] <= '0;
   end
  end
  else begin
   if (conv_en > 0 && conv_en <= 50) begin
    coefficients[conv_en-1] <= rom_q;
   end
   registers[0] <= signal;

   for (j = 0; j < 49; j++) begin
    registers[j+1] <= registers[j];
   end
   
   if (conv_en < 6'd52) conv_en <= conv_en + 1;
   if (address_en < 6'd49) address_en <= address_en + 1;
   
   if (conv_en == 52) begin
    if (en && !busy) begin
      for (k = 0; k < 50; k++) begin
         snapshot[k] <= registers[k];
      end
      counter <= 6'd5;
      sum <= registers[0]*coefficients[0]+registers[1]*coefficients[1]+registers[2]*coefficients[2]+registers[3]*coefficients[3]+registers[4]*coefficients[4];
      busy <= 1'b1;
    end
    else if (busy) begin
     if (counter < 45) begin
      sum <= sum + snapshot[counter]*coefficients[counter]+snapshot[counter+1]*coefficients[counter+1]+snapshot[counter+2]*coefficients[counter+2]+snapshot[counter+3]*coefficients[counter+3]+snapshot[counter+4]*coefficients[counter+4];
      counter <= counter + 5;
     end
     else begin
      filtered_signal <= (sum + snapshot[45] * coefficients[4] + snapshot[46] * coefficients[3]+ snapshot[47] * coefficients[2] + snapshot[48] * coefficients[1] + snapshot[49] * coefficients[0]) >>> 10;
      sum <= '0;
      counter <= '0;
      busy <= 1'b0;
     end
    end


    end  
   end 
  
  end

 


endmodule 
