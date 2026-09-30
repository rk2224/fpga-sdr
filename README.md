# FPGA-SDR

FPGA-based FM software-defined radio receiver with a custom analogue front end and real-time DSP.

The receiver covers the commercial FM broadcast band and performs channel selection and FM demodulation digitally on an Intel MAX10 FPGA. The analogue front end performs RF filtering, amplification and downconversion before digitisation by an external ADC.

The completed system successfully receives multiple live FM radio stations and outputs demodulated audio through a PWM-based audio stage.

## Analogue Front End

![Analogue front-end block diagram](images/analogue_frontend_diagram.png)

The analogue front end consists of a dipole antenna, FM band-pass filter, low-noise amplifier, analogue mixer, local oscillator and post-mixer low-pass filter.

An 85 MHz local oscillator translates the 87.5–108 MHz FM broadcast band to an intermediate-frequency range of approximately 2.5–23 MHz, allowing the complete band to be sampled by the ADC. 

## FPGA Digital Signal Processing Pipeline

The digitised IF signal is processed entirely in real time on the FPGA.

The signal is converted into complex I/Q samples using multiplication by a complex exponential, translating the spectrum into complex baseband. A tunable digital mixer is then used to select the desired FM station.

The I and Q channels pass through two stages of FIR filtering and decimation to reduce the sample rate while isolating the selected FM channel. A CORDIC-based phase detector is then used to recover the FM-modulated audio signal.

The recovered audio is converted to a PWM signal for output to an external analogue reconstruction filter and audio amplifier.

![FPGA Digital Signal Processing Pipeline](images/FPGA_DSP_pipeline.png)

## Hardware

- Terasic DE10-Lite FPGA board
- Intel MAX10 FPGA
- AD9226 12-bit ADC
- AD831 active mixer
- Si5351 local oscillator
- SPF5189Z LNA
- Custom FM band-pass filter
- Custom post-mixer low-pass filter
- Dipole antenna
- PWM audio output stage
- Audio amplifier and speaker


## Results

The completed receiver successfully receives approximately 10 FM broadcast stations at my test location.

Strong stations produce clear and intelligible audio with very little background noise, while weaker stations exhibit increased noise due to lower received signal strength.

The receiver was validated incrementally by testing the ADC interface, digital signal-processing stages, mixer frequency conversion and complete RF-to-audio signal chain.

## Implementation

The FPGA signal-processing pipeline was written in SystemVerilog.

Major DSP blocks include:

- Numerically controlled oscillator
- Complex digital mixer
- FIR filters
- Multistage decimation
- CORDIC-based FM demodulation
- PWM audio generation

The signal-processing blocks were implemented directly rather than using vendor DSP IP blocks.
