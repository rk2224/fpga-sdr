# FPGA-SDR

FPGA-based FM software-defined radio receiver with a custom analogue front end and real-time DSP implemented on an Intel MAX10 FPGA.

The receiver covers the commercial **87.5–108 MHz FM broadcast band**, performs analogue RF downconversion and digitisation, and then carries out station selection, filtering and FM demodulation digitally on the FPGA.

The completed system successfully receives multiple live FM radio stations and outputs demodulated audio through a PWM-based audio stage.

## Demo

### Live FM Reception

The video below demonstrates real-time frequency selection across the FM broadcast band and reception of multiple live stations.

[▶ Watch the live FM reception demo](https://www.youtube.com/watch?v=UVz3SpmBF10)

## Analogue Front End

![Analogue front-end block diagram](images/analogue_frontend_diagram.png)

The analogue front end receives the FM broadcast band using a dipole antenna before filtering and amplifying the signal.

An **85 MHz local oscillator** is used with an analogue mixer to translate the **87.5–108 MHz** RF spectrum to an intermediate-frequency range of approximately **2.5–23 MHz**.

The resulting signal is low-pass filtered before being sampled by an **AD9226 12-bit ADC at 65 MS/s**.

The analogue chain consists of:

- Dipole antenna
- Custom FM band-pass filter
- Low-noise amplifier
- AD831 active mixer
- 85 MHz local oscillator
- Custom post-mixer low-pass / anti-aliasing filter
- AD9226 12-bit ADC
  
---

## FPGA Digital Signal Processing Pipeline

The digitised IF signal is processed entirely in real time on the FPGA.

The signal is converted into complex I/Q samples using multiplication by a complex exponential, translating the spectrum into complex baseband. A tunable digital mixer is then used to select the desired FM station.

The I and Q channels pass through two stages of FIR filtering and decimation to reduce the sample rate while isolating the selected FM channel. A CORDIC-based phase detector is then used to recover the FM-modulated audio signal.

The recovered audio is converted to a PWM signal for output to an external analogue low-pass filter and audio amplifier before driving a speaker.

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
- NanoVNA H4
- Oscilloscope (100kHz bandwidth)
- Digital multimeter

## RF Filter Characterisation

### FM Band-Pass Filter

A custom LC band-pass filter was designed to pass the **87.5–108 MHz FM broadcast band** while attenuating unwanted out-of-band signals before amplification and mixing.

The filter was constructed using Manhattan-style construction with discrete components mounted on copper-clad board and was characterised using a NanoVNA.

<p align="center">
  <img src="images/fm_bpf_hardware.png" width="500">
</p>

A high-resolution S21 sweep around the FM band shows that the desired passband is achieved with relatively low insertion loss across most of the band.

<p align="center">
  <img src="images/fm_bpf_passband.png" width="700">
</p>

A wider frequency sweep revealed additional unwanted resonances at higher frequencies. These are caused by practical non-idealities such as component parasitics, interconnect inductance and capacitance, and the physical construction of the discrete RF filter.

![FM band-pass filter wideband response](images/fm_bpf_wideband.png)

### Additional RF Low-Pass Filter

To suppress the unwanted high-frequency responses observed in the wideband measurement, an additional RF low-pass filter was cascaded with the FM band-pass filter.

The low-pass stage was designed to preserve the required FM broadcast band while providing substantially greater attenuation at higher frequencies.

<p align="center">
  <img src="images/fm_bpf_lpf_hardware.jpeg" width="600">
</p>

The cascaded filter network was characterised directly using a NanoVNA. The image below shows the measured response of the combined FM band-pass and RF low-pass filtering stages during testing.

<p align="center">
  <img src="images/vna_bpf_lpf_measurement.jpeg" width="700">
</p>

The measured S21 data was then exported from the NanoVNA and plotted in MATLAB for clearer quantitative comparison.

![BPF versus BPF plus RF low-pass filter](images/fm_bpf_lpf_comparison.png)

The combined filter response retains the desired **87.5–108 MHz** passband while significantly reducing the unwanted high-frequency resonances.

This provided a cleaner RF spectrum to the following receiver stages and reduced the risk of unwanted out-of-band signals entering the mixer.

### Post-Mixer Low-Pass / Anti-Aliasing Filter

After analogue mixing, the 87.5–108 MHz FM broadcast band is translated using an 85 MHz local oscillator to an intermediate-frequency range of approximately **2.5–23 MHz**.

A low-pass filter was therefore placed between the mixer and the ADC to preserve the required IF spectrum while attenuating higher-frequency mixer products before digitisation.

The measured S21 response shows a cutoff close to the upper edge of the desired IF band. At **23 MHz**, the filter is approximately at the edge of its passband, after which the attenuation increases rapidly. By the **32.5 MHz Nyquist frequency** of the 65 MS/s ADC, unwanted frequency components are already significantly attenuated, with substantially greater rejection at higher frequencies.

![Measured post-mixer low-pass filter response](images/post_mixer_anti_aliasing_lpf.png)

This filter therefore limits the bandwidth presented to the ADC and reduces the contribution of unwanted high-frequency mixer products and out-of-band signals that could otherwise alias into the sampled spectrum.

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
