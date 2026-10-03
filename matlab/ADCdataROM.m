clear;
clc;
close all;



fs = 65e6;                 
ADC_BITS = 12;             
NUM_SAMPLES = 65000;       

f_LO = 85e6;

freq_dev = 75e3;           

ADC_AMPLITUDE = 0.90;      


f_station = [ ...
    87.5e6, ...
    91.3e6, ...
    98.25e6, ...
    102.75e6, ...
    108.0e6 ...
];

f_audio = [ ...
    1e3, ...
    2e3, ...
    4e3, ...
    6e3, ...
    8e3 ...
];

station_amplitude = [ ...
    1.00, ...
    0.80, ...
    0.65, ...
    0.75, ...
    0.55 ...
];

NUM_STATIONS = length(f_station);

f_IF = f_station - f_LO;



fprintf('\n====================================================\n');
fprintf('FM SDR SIMULATION\n');
fprintf('====================================================\n');

fprintf('ADC sample rate = %.2f MHz\n', fs/1e6);
fprintf('Analogue LO     = %.2f MHz\n\n', f_LO/1e6);

fprintf(' Station     RF (MHz)     IF (MHz)     Audio (kHz)\n');
fprintf('----------------------------------------------------\n');

for k = 1:NUM_STATIONS

    fprintf('   %d         %6.2f        %6.2f         %5.1f\n', ...
        k, ...
        f_station(k)/1e6, ...
        f_IF(k)/1e6, ...
        f_audio(k)/1e3);

end

fprintf('====================================================\n\n');




t = (0:NUM_SAMPLES-1).' / fs;

fprintf('ROM duration = %.3f ms\n\n', ...
    NUM_SAMPLES/fs * 1e3);




audio = zeros(NUM_SAMPLES, NUM_STATIONS);

for k = 1:NUM_STATIONS

    audio(:,k) = sin(2*pi*f_audio(k)*t);

end



FM_signals = zeros(NUM_SAMPLES, NUM_STATIONS);

for k = 1:NUM_STATIONS

    beta = freq_dev / f_audio(k);

    phase = ...
        2*pi*f_IF(k)*t ...
        - beta*cos(2*pi*f_audio(k)*t);

    FM_signals(:,k) = ...
        station_amplitude(k) * cos(phase);

end



ADC_analogue = sum(FM_signals, 2);




ADC_analogue = ...
    ADC_AMPLITUDE * ADC_analogue / max(abs(ADC_analogue));



ADC_MAX =  2^(ADC_BITS-1) - 1;    % +2047
ADC_MIN = -2^(ADC_BITS-1);        % -2048

ADCsamples = round(ADC_analogue * ADC_MAX);



ADCsamples(ADCsamples > ADC_MAX) = ADC_MAX;
ADCsamples(ADCsamples < ADC_MIN) = ADC_MIN;




ADC_unsigned = mod(ADCsamples, 2^ADC_BITS);



filename = 'ADCsamples.mif';

fid = fopen(filename, 'w');

if fid == -1
    error('Could not create ADCsamples.mif');
end


fprintf(fid, 'WIDTH=%d;\n', ADC_BITS);
fprintf(fid, 'DEPTH=%d;\n\n', NUM_SAMPLES);

fprintf(fid, 'ADDRESS_RADIX=HEX;\n');
fprintf(fid, 'DATA_RADIX=HEX;\n\n');

fprintf(fid, 'CONTENT BEGIN\n');


for k = 0:NUM_SAMPLES-1

    fprintf(fid, ...
        '    %04X : %03X;\n', ...
        k, ...
        ADC_unsigned(k+1));

end


fprintf(fid, 'END;\n');

fclose(fid);

fprintf('Created %s successfully.\n', filename);




figure;

hold on;

for k = 1:NUM_STATIONS

    plot( ...
        t*1e3, ...
        audio(:,k) + 2*(k-1) ...
    );

end

xlabel('Time (ms)');
ylabel('Audio signals (offset vertically)');

title('Original Message Signals');

grid on;

legend( ...
    arrayfun(@(x) sprintf('%.1f kHz', x/1e3), ...
    f_audio, ...
    'UniformOutput', false) ...
);




N_plot = round(2e-6 * fs);

figure;

hold on;

for k = 1:NUM_STATIONS

    plot( ...
        t(1:N_plot)*1e6, ...
        FM_signals(1:N_plot,k) + 2*(k-1) ...
    );

end

xlabel('Time (\mus)');
ylabel('Amplitude (offset vertically)');

title('Individual FM IF Signals');

grid on;

legend( ...
    arrayfun(@(x) sprintf('%.2f MHz RF', x/1e6), ...
    f_station, ...
    'UniformOutput', false) ...
);




figure;

plot( ...
    t(1:N_plot)*1e6, ...
    ADCsamples(1:N_plot) ...
);

xlabel('Time (\mus)');
ylabel('ADC Code');

title('12-bit ADC Samples - All FM Stations Combined');

grid on;



figure;

hold on;

for k = 1:NUM_STATIONS

    f_inst = ...
        f_IF(k) ...
        + freq_dev*sin(2*pi*f_audio(k)*t);

    plot( ...
        t*1e3, ...
        f_inst/1e6 ...
    );

end

xlabel('Time (ms)');
ylabel('Instantaneous IF Frequency (MHz)');

title('Instantaneous Frequencies of FM Stations');

grid on;

legend( ...
    arrayfun(@(x) sprintf('%.2f MHz RF', x/1e6), ...
    f_station, ...
    'UniformOutput', false) ...
);




NFFT = 2^nextpow2(NUM_SAMPLES);

X = fft(ADC_analogue, NFFT);

f = (0:NFFT-1).' * fs/NFFT;

Xmag = abs(X);

Xmag_dB = ...
    20*log10( ...
        Xmag / max(Xmag) ...
    );


figure;

plot( ...
    f(1:NFFT/2)/1e6, ...
    Xmag_dB(1:NFFT/2) ...
);

xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');

title('Spectrum of Composite ADC Input');

grid on;

xlim([0 25]);
ylim([-100 5]);



hold on;

for k = 1:NUM_STATIONS

    xline( ...
        f_IF(k)/1e6, ...
        '--', ...
        sprintf('%.2f MHz', f_IF(k)/1e6) ...
    );

end

hold off;