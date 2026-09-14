module FIR2(
 input logic clk,
 input logic rst,
 input logic en,
 input logic en2, 
 input logic signed [20:0] signal,
 output logic data_valid,
 output logic signed [26:0] filtered_signal
);

 logic signed [20:0] registers [49:0];
 logic signed [9:0] coefficients [49:0];
 logic signed [20:0] snapshot [49:0];
 logic [5:0] conv_en;
 logic busy;
 logic [5:0] address_en;
 logic [5:0] coeff_count;
 logic signed [9:0] rom_q;
 logic signed [36:0] sum;
 logic [5:0] counter; 
 integer i;
 integer j;
 integer k;

 FIR2_rom FIR_coefficients(
  .clk(clk),
  .address(address_en),
  .q(rom_q)
 );

 always_ff @(posedge clk) begin 
   if (rst) begin
    conv_en <= '0;
    address_en <= '0;
    filtered_signal <= '0;
    coeff_count <= '0;
    data_valid <= '0;
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
    if (address_en < 6'd49) address_en <= address_en + 1;
    if (coeff_count < 6'd50) coeff_count <= coeff_count + 1;
    if ((coeff_count > 0) && (coeff_count <= 6'd50)) coefficients[coeff_count-1] <= rom_q;
   
 

    if (en) begin
      registers[0] <= signal;

      for (j = 0; j < 49; j++) begin
       registers[j+1] <= registers[j];
      end
   
      if (conv_en < 6'd55) conv_en <= conv_en + 1;
    
   
      if (conv_en == 55) begin
       data_valid <= 1'b1;
       if (en2 && !busy) begin 
         for (k = 0; k < 50; k++) begin
          snapshot[k] <= registers[k];
         end
         counter <= 6'd1;
         sum <= registers[0]*coefficients[0];
         busy <= 1'b1;
       end 
      end
   end
   else if (busy) begin
     if (counter < 49) begin
      sum <= sum + snapshot[counter]*coefficients[counter];
      counter <= counter + 1;
     end
     else begin
      filtered_signal <= (sum + snapshot[49]*coefficients[49]) >>> 10;
      sum <= '0;
      counter <= '0;
      busy <= 1'b0;
     end
   end 
   
  

  end
 end
 
endmodule 
