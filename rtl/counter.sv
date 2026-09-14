module phase_counter(
 input logic clk,
 input logic rst,
 input logic [23:0] freq,
 output logic signed [9:0] cos_value,
 output logic signed [9:0] sine_value
);

 logic [31:0] phase_address;
 logic [31:0] counter_increment;
 logic [9:0] address;

 localparam logic [63:0] TWO_POW_32 = 64'd1 << 32;
 localparam int fs = 65_000_000;

 assign counter_increment = (TWO_POW_32*freq)/ fs;

 always_ff @(posedge clk) begin 
  if (rst) phase_address <= 32'd0;
  else phase_address <= phase_address + counter_increment;
 end
 
 assign address = phase_address[31:22]; 
 
 rom ROM_sine(
  .clk(clk),
  .address(address),
  .q(sine_value)
 );

 rom ROM_cos(
  .clk(clk),
  .address(address+10'd256),
  .q(cos_value)
 );

endmodule
 
 

