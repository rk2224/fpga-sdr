module clkdivider(
 input logic clk,
 input logic rst,
 input logic [7:0] N, 
 output logic en
);
 
 logic [7:0] N_count;

 always_ff @(posedge clk) begin
  if (rst) begin
   en <= 1'b0;
   N_count <= 7'b0;
  end
  else begin
   if (N_count < N-1) begin
    N_count <= N_count + 1'b1;
    en <= 1'b0;
   end
   else begin
    N_count <= 8'b0; 
    en <= 1'b1;
   end
  end
 end
endmodule