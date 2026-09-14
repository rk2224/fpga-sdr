module CORDIC(
 input logic clk,
 input logic rst,
 input logic data_valid,
 input logic en,
 input logic signed [26:0] re_signal,
 input logic signed [26:0] im_signal,
 output logic signed [18:0] z_angle
);
 
 logic [1:0] arith_en;
 logic cordic_en;
 logic signed [26:0] registers_re [1:0];
 logic signed [26:0] registers_im [1:0];
 logic signed [54:0] re;
 logic signed [54:0] im;
 logic signed [53:0] InIn1;
 logic signed [53:0] QnQn1;
 logic signed [53:0] QnIn1;
 logic signed [53:0] InQn1;
 

 always_ff @(posedge clk) begin
  if (rst) begin
    registers_re[0] <= '0;
    registers_re[1] <= '0;
    registers_im[0] <= '0;
    registers_im[1] <= '0;
    cordic_en <= '0;
    arith_en <= '0;
    re <= '0;
    im <= '0;
  end

  else begin
   cordic_en <= 1'b0;
   if (en) begin
    if (data_valid) begin
       registers_re[0] <= re_signal;
       registers_im[0] <= im_signal;
       registers_re[1] <= registers_re[0];
       registers_im[1] <= registers_im[0];
       if (arith_en < 2'd2) arith_en <= arith_en + 1;
       if (arith_en == 2'd2) begin
        re <= {InIn1[53], InIn1} + {QnQn1[53], QnQn1};
        im <= {QnIn1[53], QnIn1} - {InQn1[53], InQn1};
        cordic_en <= 1'b1;
       end
     end
    end
   end
  end
  
  CORDIC_Algo algorithm(
   .clk(clk),
   .rst(rst),
   .cordic_en(cordic_en),
   .re(re),
   .im(im),
   .z_angle(z_angle)
  );

 always_comb begin 
  InIn1 = registers_re[0]*registers_re[1];
  QnQn1 = registers_im[0]*registers_im[1];
  QnIn1 = registers_im[0]*registers_re[1];
  InQn1 = registers_re[0]*registers_im[1];
 end
 
 
 

endmodule
  

 

 
