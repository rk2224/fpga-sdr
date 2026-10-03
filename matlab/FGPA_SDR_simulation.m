clear;
clc;
close all;


fs = 50e6;                
T  = 2e-3;                 % Simulation duration
t  = 0:1/fs:T-1/fs;
f_LO = 97.75e6;

%% FM parameters

fc1 = 107.75e6;  % 10 MHz
fc2 = 98.25e6;   % 500 kHz
fc3 = 99.75e6;
fc4 = 102.75e6;

fm1 = 15000;
fm2 = 10000;
fm3 = 12000;
fm4 = 15000;

kf = 75000;                % Frequency sensitivity

m1 = cos(2*pi*fm1*t);      % First message signal
m2 = cos(2*pi*fm2*t);      % Second message signal
m3 = cos(2*pi*fm3*t);      % Third message signal
m4 = cos(2*pi*fm4*t);      % Fourth message signal


%% Numerical integral of message signal

messageIntegral1 = cumtrapz(t, m1);
messageIntegral2 = cumtrapz(t, m2);
messageIntegral3 = cumtrapz(t, m3);
messageIntegral4 = cumtrapz(t, m4);


%% FM signal

phase1 = 2*pi*fc1*t + 2*pi*kf*messageIntegral1;
phase2 = 2*pi*fc2*t + 2*pi*kf*messageIntegral2;
phase3 = 2*pi*fc3*t + 2*pi*kf*messageIntegral3;
phase4 = 2*pi*fc4*t + 2*pi*kf*messageIntegral4;


x = cos(phase1) + cos(phase2) + cos(phase3) + cos(phase4);

I_x = 0.5*cos(phase1-2*pi*f_LO*t) ...
    + 0.5*cos(phase2-2*pi*f_LO*t) ...
    + 0.5*cos(phase3-2*pi*f_LO*t) ...
    + 0.5*cos(phase4-2*pi*f_LO*t);

Q_x = 0.5*sin(phase1-2*pi*f_LO*t) ...
    + 0.5*sin(phase2-2*pi*f_LO*t) ...
    + 0.5*sin(phase3-2*pi*f_LO*t) ...
    + 0.5*sin(phase4-2*pi*f_LO*t);


%% Add white Gaussian noise to I and Q

SNR_dB = 20;

% Power of the complex IQ signal
IQ_clean = I_x + 1j*Q_x;
signal_power = mean(abs(IQ_clean).^2);

% Required total noise power
noise_power = signal_power / (10^(SNR_dB/10));

% Half the noise power goes into I and half into Q
noise_std = sqrt(noise_power/2);

I_noise = noise_std * randn(size(I_x));
Q_noise = noise_std * randn(size(Q_x));

% Noisy I/Q signals
I_x_noisy = I_x + I_noise;
Q_x_noisy = Q_x + Q_noise;


%% Combine noisy I and Q

IQ = I_x_noisy + 1j*Q_x_noisy;


%% FFT of IQ signal

Nfft = 65536;

IQ_fft = fftshift(fft(IQ, Nfft));

% Frequency axis
f = (-Nfft/2:Nfft/2-1)*(fs/Nfft);

% Magnitude spectrum
IQ_mag = abs(IQ_fft);
IQ_mag = IQ_mag / max(IQ_mag);


%% Plot IQ spectrum

figure;
plot(f/1e6, IQ_mag);
xlabel('Frequency (MHz)');
ylabel('Normalised magnitude');
title('Spectrum of I_x + jQ_x');
grid on;
xlim([-15 15]);


figure;
stem(t, I_x_noisy, "filled");
xlabel("Discrete time t");
ylabel("I[n]");
title("Digital antenna signal");
grid on;


%% Complex mixer

expfunc = exp(-1j*2*pi*(fc2-f_LO)*t);

y = IQ .* expfunc;


figure;
stem(t, real(expfunc), "filled");
xlabel("Discrete time t");
ylabel("Sine");
title("Real part of sine wave");
grid on;
xlim([0 1e-7]);


%% FIR low-pass filter 1
% Anti-aliasing filter before decimation

B = 2e6;                 % Cutoff frequency
M = 50;                 % Filter order
n = 0:M;                 % Coefficient indices

u = (2*B/fs) .* (n - M/2);

% Normalised sinc
sinc_u = ones(size(u));
nonzero = (u ~= 0);

sinc_u(nonzero) = ...
    sin(pi*u(nonzero)) ./ (pi*u(nonzero));

% Ideal low-pass impulse response
idealfilter = (2*B/fs) .* sinc_u;


%% Rectangular window

w_rect = ones(1, M+1);

h_rect = idealfilter .* w_rect;

% Normalise to unity DC gain
h_rect = h_rect / sum(h_rect);


%% Hamming window

w_hamming = 0.54 - 0.46*cos(2*pi*n/M);

h_hamming = idealfilter .* w_hamming;

% Normalise to unity DC gain
h_hamming = h_hamming / sum(h_hamming);


%% Compare FIR 1 coefficients

figure;

stem(n, h_rect, "filled");
hold on;

plot(n, h_hamming, "LineWidth", 1.5);

xlabel("Coefficient index n");
ylabel("h[n]");

title("FIR Filter 1 Coefficients");

legend("Rectangular", "Hamming");

grid on;


%% Compare frequency response of FIR filter 1

Nfft = 16384;

H_rect = fftshift(fft(h_rect, Nfft));
H_hamming = fftshift(fft(h_hamming, Nfft));

f = (-Nfft/2:Nfft/2-1) * (fs/Nfft);

Hmag_rect = abs(H_rect);
Hmag_rect = Hmag_rect / max(Hmag_rect);

Hmag_hamming = abs(H_hamming);
Hmag_hamming = Hmag_hamming / max(Hmag_hamming);


figure;

plot(f/1e3, Hmag_rect);
hold on;

plot(f/1e3, Hmag_hamming);

xlabel("Frequency (kHz)");
ylabel("|H(f)|");

title("FIR Filter 1: Rectangular vs Hamming");

legend("Rectangular", "Hamming");

grid on;

xlim([-5000 5000]);


%% Compare FIR 1 frequency response in dB

figure;

plot(f/1e3, 20*log10(Hmag_rect + 1e-12));
hold on;

plot(f/1e3, 20*log10(Hmag_hamming + 1e-12));

xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");

title("FIR Filter 1: Rectangular vs Hamming");

legend("Rectangular", "Hamming");

grid on;

xlim([-5000 5000]);
ylim([-100 5]);


%% Spectrum of signal after mixer

Nfft = 16384;

Y = fftshift(fft(y, Nfft));

f = (-Nfft/2:Nfft/2-1) * (fs/Nfft);

ymag = abs(Y);
ymag = ymag / max(ymag);

figure;

plot(f/1e3, ymag);

xlabel("Frequency (kHz)");
ylabel("|Y(f)|");

title("Frequency response of signal after mixer");

grid on;

xlim([-500 500]);


%% Message signal spectrum

Nfft = 16384;

MessageFFT = fftshift(fft(m1, Nfft));

f = (-Nfft/2:Nfft/2-1) * (fs/Nfft);

mmag = abs(MessageFFT);
mmag = mmag / max(mmag);

figure;

plot(f/1e3, mmag);

xlabel("Frequency (kHz)");
ylabel("|M(f)|");

title("Frequency response of message 1 signal");

grid on;

xlim([-500 500]);


%% Antenna signal spectrum

Nfft = 16384;

X = fftshift(fft(x, Nfft));

f = (-Nfft/2:Nfft/2-1) * (fs/Nfft);

xmag = abs(X);
xmag = xmag / max(xmag);

figure;

plot(f/1e6, xmag);

xlabel("Frequency (MHz)");
ylabel("|X(f)|");

title("Frequency response of antenna signal");

grid on;

xlim([-10 10]);


%% Filter mixed signal with both FIR filters

z_rect = conv(y, h_rect, 'same');

z_hamming = conv(y, h_hamming, 'same');


%% Decimate from 50 MS/s -> 5 MS/s

D = fs / 5e6;

z_rect_dec = z_rect(1:D:end);

z_hamming_dec = z_hamming(1:D:end);

fs_dec = fs/D;


%% Second FIR LPF: +/-100 kHz

B2 = 1e5;
M2 = 50;

n2 = 0:M2;

u1 = (2*B2/fs_dec) .* (n2 - M2/2);

sinc_u1 = ones(size(u1));

nonzero = (u1 ~= 0);

sinc_u1(nonzero) = ...
    sin(pi*u1(nonzero)) ./ (pi*u1(nonzero));

idealfilter1 = (2*B2/fs_dec) .* sinc_u1;


%% Rectangular window FIR 2

w1_rect = ones(1, M2+1);

h1_rect = idealfilter1 .* w1_rect;

h1_rect = h1_rect / sum(h1_rect);


%% Hamming window FIR 2

w1_hamming = 0.54 - 0.46*cos(2*pi*n2/M2);

h1_hamming = idealfilter1 .* w1_hamming;

h1_hamming = h1_hamming / sum(h1_hamming);


%% Compare frequency response of FIR filter 2

Nfft = 16384;

H1_rect = fftshift(fft(h1_rect, Nfft));

H1_hamming = fftshift(fft(h1_hamming, Nfft));

f = (-Nfft/2:Nfft/2-1) * (fs_dec/Nfft);


Hmag1_rect = abs(H1_rect);
Hmag1_rect = Hmag1_rect / max(Hmag1_rect);


Hmag1_hamming = abs(H1_hamming);
Hmag1_hamming = Hmag1_hamming / max(Hmag1_hamming);


figure;

plot(f/1e3, Hmag1_rect);
hold on;

plot(f/1e3, Hmag1_hamming);

xlabel("Frequency (kHz)");
ylabel("|H(f)|");

title("FIR Filter 2: Rectangular vs Hamming");

legend("Rectangular", "Hamming");

grid on;

xlim([-500 500]);


%% Compare FIR filter 2 in dB

figure;

plot(f/1e3, 20*log10(Hmag1_rect + 1e-12));
hold on;

plot(f/1e3, 20*log10(Hmag1_hamming + 1e-12));

xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");

title("FIR Filter 2: Rectangular vs Hamming");

legend("Rectangular", "Hamming");

grid on;

xlim([-500 500]);
ylim([-100 5]);


%% Apply second FIR

r_rect = conv(z_rect_dec, h1_rect, 'same');

r_hamming = conv(z_hamming_dec, h1_hamming, 'same');


%% FM demodulation: rectangular

phaseDifference_rect = angle( ...
    r_rect(2:end) .* conj(r_rect(1:end-1)) );

m_demod_rect = ...
    (fs_dec/(2*pi*kf)) .* phaseDifference_rect;


%% FM demodulation: Hamming

phaseDifference_hamming = angle( ...
    r_hamming(2:end) .* conj(r_hamming(1:end-1)) );

m_demod_hamming = ...
    (fs_dec/(2*pi*kf)) .* phaseDifference_hamming;


%% New time axis after decimation

t_dec = (0:length(r_rect)-1)/fs_dec;

t_demod = t_dec(2:end);


%% Original message at same sampling instants

m2_reference = cos(2*pi*fm2*t_demod);


%% Compare rectangular demodulation

figure;

plot(t_demod*1e3, m_demod_rect);
hold on;

plot(t_demod*1e3, m2_reference, '--');

xlabel("Time (ms)");
ylabel("Amplitude");

title("Rectangular Window: Original and Demodulated Message");

legend("Demodulated", "Original");

grid on;

xlim([0 0.5]);


%% Compare Hamming demodulation

figure;

plot(t_demod*1e3, m_demod_hamming);
hold on;

plot(t_demod*1e3, m2_reference, '--');

xlabel("Time (ms)");
ylabel("Amplitude");

title("Hamming Window: Original and Demodulated Message");

legend("Demodulated", "Original");

grid on;

xlim([0 0.5]);


%% Direct comparison of demodulated signals

figure;

plot(t_demod*1e3, m_demod_rect);
hold on;

plot(t_demod*1e3, m_demod_hamming);

plot(t_demod*1e3, m2_reference, '--');

xlabel("Time (ms)");
ylabel("Amplitude");

title("Rectangular vs Hamming FM Demodulation");

legend("Rectangular", "Hamming", "Original");

grid on;

xlim([0 0.5]);