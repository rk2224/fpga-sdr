clear;
clc;
close all;


fs = 65e6;               
T  = 2e-3;                
t  = 0:1/fs:T-1/fs;


f_LO = 85e6;


fc = [87.5e6, 91.3e6, 98.25e6, 102.75e6, 108e6];

fm = [8e3, 12e3, 10e3, 15e3, 11e3];

A = [0.45, 0.75, 1.00, 0.60, 0.35];

phi = [0, 0.7, 1.4, 2.1, 2.8];

kf = 75e3;


IF_signal = zeros(size(t));

for i = 1:length(fc)

    m = cos(2*pi*fm(i)*t);

    messageIntegral = cumtrapz(t,m);

    f_IF = fc(i) - f_LO;

    phase = ...
        2*pi*f_IF*t ...
        + 2*pi*kf*messageIntegral ...
        + phi(i);

    IF_signal = IF_signal + ...
        A(i)*cos(phase);

end


SNR_dB = 20;

signal_power = mean(IF_signal.^2);

noise_power = ...
    signal_power / 10^(SNR_dB/10);

noise_std = sqrt(noise_power);

noise = noise_std * randn(size(IF_signal));

IF_noisy = IF_signal + noise;


IF_scaled = ...
    0.85 * IF_noisy / max(abs(IF_noisy));


ADC_MAX = 2047;
ADC_MIN = -2048;

ADC_samples = round(IF_scaled * ADC_MAX);

ADC_samples(ADC_samples > ADC_MAX) = ADC_MAX;
ADC_samples(ADC_samples < ADC_MIN) = ADC_MIN;


fid = fopen('ADC_samples.hex','w');

for i = 1:length(ADC_samples)

    value = ADC_samples(i);

    if value < 0
        value = value + 4096;
    end

    fprintf(fid,'%03X\n',value);

end

fclose(fid);

disp('ADC_samples.hex created');


figure;

plot(t*1e6, ADC_samples);

xlabel('Time (\mus)');
ylabel('ADC Code');
title('12-bit ADC samples');

grid on;
xlim([0 2]);


Nfft = 65536;

X = fftshift(fft(ADC_samples,Nfft));

f = (-Nfft/2:Nfft/2-1)*(fs/Nfft);

Xmag = abs(X);
Xmag = Xmag/max(Xmag);

figure;

plot(f/1e6,Xmag);

xlabel('Frequency (MHz)');
ylabel('Normalised magnitude');
title('ADC spectrum');

grid on;
xlim([0 25]);