module IQdownconverter(
 input logic clk,
 input logic rst, 
 input logic signed [11:0] signal,
 output logic signed [11:0] I_sample,
 output logic signed [11:0] Q_sample
);
  
 logic signed [9:0] cos_value;
 logic signed [9:0] sine_value; 
 logic signed [21:0] I_sample_IM;
 logic signed [21:0] Q_sample_IM;
 logic [23:0] freq;
 assign freq = 24'd12750000;
 
 phase_counter SINECOS(
  .clk(clk),
  .rst(rst),
  .freq(freq),
  .cos_value(cos_value),
  .sine_value(sine_value)
 );

 always_ff @(posedge clk) begin
  if (rst) begin
   I_sample <= '0;
   Q_sample <= '0;
  end
  else begin
   I_sample <= I_sample_IM >>> 9;
   Q_sample <= Q_sample_IM >>> 9;
  end
 end 

 always_comb begin
  I_sample_IM = signal * cos_value;
  Q_sample_IM = signal * (-sine_value);
 end


endmodule