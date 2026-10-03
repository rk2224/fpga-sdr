module SDRProject_top( 
    input  logic        MAX10_CLK1_50, 
    input  logic [1:0]  KEY, 
    input  logic [9:0]  SW,

    input  logic [11:0] ADC_IN,

    output logic        CLOCK,

    output logic        PWM_OUT, 
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4 
); 



    logic clk; 
    logic pll_locked; 
    logic rst; 

    assign rst = ~KEY[0] | ~pll_locked; 

    pll_65mhz PLL ( 
        .inclk0 (MAX10_CLK1_50), 
        .areset (~KEY[0]), 
        .c0     (clk), 
        .locked (pll_locked) 
    ); 

    assign CLOCK = clk;


    logic [11:0] adc_raw;

    localparam signed [12:0] ADC_CENTRE = 13'sd2022;

    localparam integer ADC_GAIN_SHIFT = 9;

    logic signed [12:0] adc_centered;
    logic signed [17:0] adc_centered_ext;
    logic signed [17:0] adc_scaled;

    logic signed [11:0] ADC_sample;


    always_ff @(posedge clk) begin
        if (rst)
            adc_raw <= 12'd2022;
        else
            adc_raw <= ADC_IN;
    end


    assign adc_centered =
        $signed({1'b0, adc_raw}) - ADC_CENTRE;


    assign adc_centered_ext =
        {{5{adc_centered[12]}}, adc_centered};


    assign adc_scaled =
        adc_centered_ext <<< ADC_GAIN_SHIFT;


    always_comb begin

        if (adc_scaled > 18'sd2047)
            ADC_sample = 12'sd2047;

        else if (adc_scaled < -18'sd2048)
            ADC_sample = -12'sd2048;

        else
            ADC_sample = adc_scaled[11:0];

    end



    logic en; 
    logic en2; 

    logic [26:0] freq; 
    logic [10:0] disp_freq; 

    logic key_prev; 
    logic tune_pulse; 


    always_ff @(posedge clk) begin 
        if (rst) begin 
            key_prev   <= 1'b1; 
            tune_pulse <= 1'b0; 
        end 
        else begin 
            key_prev   <= KEY[1]; 
            tune_pulse <= key_prev && ~KEY[1]; 
        end 
    end 


    always_ff @(posedge clk) begin 

        if (rst) begin 
            disp_freq <= 11'd913; 
            freq      <= 27'd91_300_000; 
        end 

        else begin 

            if (tune_pulse) begin 

                if (SW[9] && disp_freq > 875) begin 

                    disp_freq <= disp_freq - 1; 
                    freq      <= freq - 27'd100_000; 

                end 

                else if (~SW[9] && disp_freq < 1080) begin 

                    disp_freq <= disp_freq + 1; 
                    freq      <= freq + 27'd100_000; 

                end 

            end 

        end 

    end


    logic signed [11:0] I_sample; 
    logic signed [11:0] Q_sample; 

    logic signed [14:0] Mixer_Re; 
    logic signed [14:0] Mixer_Im; 

    logic signed [20:0] FIR1_Re; 
    logic signed [20:0] FIR1_Im; 

    logic signed [26:0] FIR2_Re; 
    logic signed [26:0] FIR2_Im; 

    logic signed [18:0] z_angle; 

    logic data_valid_re; 
    logic data_valid_im; 



    IQdownconverter IQ_CONVERTER ( 
        .clk      (clk), 
        .rst      (rst), 
        .signal   (ADC_sample), 
        .I_sample (I_sample), 
        .Q_sample (Q_sample) 
    ); 



    mixer init_mixer ( 
        .clk       (clk), 
        .rst       (rst), 
        .freq      (freq), 
        .I_samples (I_sample), 
        .Q_samples (Q_sample), 
        .I_re      (Mixer_Re), 
        .Q_im      (Mixer_Im) 
    ); 



    FIR1 re_fir1 ( 
        .clk             (clk), 
        .rst             (rst), 
        .en              (en), 
        .signal          (Mixer_Re), 
        .filtered_signal (FIR1_Re) 
    ); 


    FIR1 im_fir1 ( 
        .clk             (clk), 
        .rst             (rst), 
        .en              (en), 
        .signal          (Mixer_Im), 
        .filtered_signal (FIR1_Im) 
    ); 




    FIR2 re_fir2 ( 
        .clk             (clk), 
        .rst             (rst), 
        .en              (en), 
        .en2             (en2), 
        .signal          (FIR1_Re), 
        .data_valid      (data_valid_re), 
        .filtered_signal (FIR2_Re) 
    ); 


    FIR2 im_fir2 ( 
        .clk             (clk), 
        .rst             (rst), 
        .en              (en), 
        .en2             (en2), 
        .signal          (FIR1_Im), 
        .data_valid      (data_valid_im), 
        .filtered_signal (FIR2_Im) 
    ); 




    CORDIC CORDICALGO ( 
        .clk        (clk), 
        .rst        (rst), 
        .data_valid (data_valid_re), 
        .en         (en2), 
        .re_signal  (FIR2_Re), 
        .im_signal  (FIR2_Im), 
        .z_angle    (z_angle) 
    ); 



    clkdivider decimation5MHZ ( 
        .clk (clk), 
        .rst (rst), 
        .N   (8'd13), 
        .en  (en) 
    ); 


    clkdivider decimation500kHZ ( 
        .clk (clk), 
        .rst (rst), 
        .N   (8'd130), 
        .en  (en2) 
    ); 



    pwm_audio pwmoutput ( 
        .clk      (clk), 
        .rst      (rst), 
        .data_in  (z_angle), 
        .pwm_out  (PWM_OUT) 
    ); 



    logic [3:0] BCD0, BCD1, BCD2, BCD3, BCD4;


    bin2bcd_16 BIN ( 
        .x    (disp_freq), 
        .BCD0 (BCD0), 
        .BCD1 (BCD1), 
        .BCD2 (BCD2), 
        .BCD3 (BCD3), 
        .BCD4 (BCD4) 
    ); 


    hexto7seg SEG0 (.out(HEX0), .in(BCD0)); 
    hexto7seg SEG1 (.out(HEX1), .in(BCD1)); 
    hexto7seg SEG2 (.out(HEX2), .in(BCD2)); 
    hexto7seg SEG3 (.out(HEX3), .in(BCD3)); 
    hexto7seg SEG4 (.out(HEX4), .in(BCD4)); 


endmodule