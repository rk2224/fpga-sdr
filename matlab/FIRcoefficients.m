clear;
clc;
close all;


fs1 = 65e6;      
fs2 = 5e6;        

B1 = 2e6;        
M1 = 49;         
n1 = 0:M1;


u1 = (2*B1/fs1) .* (n1 - M1/2);

sinc_u1 = ones(size(u1));

nonzero = (u1 ~= 0);

sinc_u1(nonzero) = ...
    sin(pi*u1(nonzero)) ./ (pi*u1(nonzero));

idealfilter1 = (2*B1/fs1) .* sinc_u1;



w1 = 0.54 - 0.46*cos(2*pi*n1/M1);

h1 = idealfilter1 .* w1;

h1 = h1 / sum(h1);



x1 = round(512 * h1);

x1(x1 > 511)  = 511;
x1(x1 < -512) = -512;

x1_unsigned = mod(x1, 1024);



fid = fopen('FIR1_coefficients.mif', 'w');

fprintf(fid, 'WIDTH=10;\n');
fprintf(fid, 'DEPTH=50;\n\n');

fprintf(fid, 'ADDRESS_RADIX=UNS;\n');
fprintf(fid, 'DATA_RADIX=HEX;\n\n');

fprintf(fid, 'CONTENT BEGIN\n');

for k = 1:length(x1_unsigned)

    address = k - 1;

    fprintf(fid, '    %d : %03X;\n', ...
        address, x1_unsigned(k));

end

fprintf(fid, 'END;\n');

fclose(fid);





B2 = 100e3;      
M2 = 49;          
n2 = 0:M2;



u2 = (2*B2/fs2) .* (n2 - M2/2);

sinc_u2 = ones(size(u2));

nonzero = (u2 ~= 0);

sinc_u2(nonzero) = ...
    sin(pi*u2(nonzero)) ./ (pi*u2(nonzero));

idealfilter2 = (2*B2/fs2) .* sinc_u2;



w2 = 0.54 - 0.46*cos(2*pi*n2/M2);

h2 = idealfilter2 .* w2;

h2 = h2 / sum(h2);



x2 = round(512 * h2);

x2(x2 > 511)  = 511;
x2(x2 < -512) = -512;

x2_unsigned = mod(x2, 1024);



fid = fopen('FIR2_coefficients.mif', 'w');

fprintf(fid, 'WIDTH=10;\n');
fprintf(fid, 'DEPTH=50;\n\n');

fprintf(fid, 'ADDRESS_RADIX=UNS;\n');
fprintf(fid, 'DATA_RADIX=HEX;\n\n');

fprintf(fid, 'CONTENT BEGIN\n');

for k = 1:length(x2_unsigned)

    address = k - 1;

    fprintf(fid, '    %d : %03X;\n', ...
        address, x2_unsigned(k));

end

fprintf(fid, 'END;\n');

fclose(fid);




disp("FIR 1 decimal coefficients:")
disp(x1)

disp("FIR 2 decimal coefficients:")
disp(x2)

disp("MIF files generated successfully.")