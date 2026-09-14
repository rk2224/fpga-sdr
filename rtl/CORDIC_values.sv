module CORDIC_values(
 input logic [3:0] iteration_number,
 output logic signed [18:0] angle
);

 always_comb begin
   case(iteration_number)
    4'h0: angle = 16'd51472;
    4'h1: angle = 16'd30386;
    4'h2: angle = 16'd16055;
    4'h3: angle = 16'd8150;
    4'h4: angle = 16'd4091;
    4'h5: angle = 16'd2047;
    4'h6: angle = 16'd1024;
    4'h7: angle = 16'd512;
    4'h8: angle = 16'd256;
    4'h9: angle = 16'd128;
    default: angle = 16'd0;
   endcase
 end

endmodule
    
    
