module mixer(
 input logic clk,
 input logic rst,
 input logic [26:0] freq,
 input logic signed [11:0] I_samples,
 input logic signed [11:0] Q_samples,
 output logic signed [14:0] I_re,
 output logic signed [14:0] Q_im
);

 logic signed [9:0] sine_value;
 logic signed [9:0] cos_value;
 logic signed [21:0] I_cos;
 logic signed [21:0] I_sin;
 logic signed [21:0] Q_cos;
 logic signed [21:0] Q_sin;
 logic signed [22:0] im_sum;
 logic signed [22:0] re_sum;
 logic [23:0] nco_freq;


 phase_counter SINECOS(
  .clk(clk),
  .rst(rst),
  .freq(nco_freq),
  .cos_value(cos_value),
  .sine_value(sine_value)
 );
 
 always_ff @(posedge clk) begin

  if (rst) begin 
   I_re <= '0;
   Q_im <= '0;
  end

  else begin
   I_re <= re_sum >>> 8;
   Q_im <= im_sum >>> 8;
  end

 end
 
 always_comb begin
  I_cos = I_samples*cos_value;
  I_sin = I_samples*sine_value;
  Q_cos = Q_samples*cos_value;
  Q_sin = Q_samples*sine_value;
  if (freq > 27'd97_750_000) begin
   re_sum = {I_cos[21], I_cos} + {Q_sin[21], Q_sin};
   im_sum = {Q_cos[21], Q_cos} - {I_sin[21], I_sin};
  end
  else begin
    re_sum = {I_cos[21], I_cos} - {Q_sin[21], Q_sin};
    im_sum = {Q_cos[21], Q_cos} + {I_sin[21], I_sin};
  end
   if (freq >= 27'd97_750_000)
       nco_freq = freq - 27'd97_750_000;
   else
       nco_freq = 27'd97_750_000 - freq;
 end

endmodule
 
 
 
