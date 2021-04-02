
clc
close all
clear 
tic;
% edit 'input_SMPE.txt';

[casename, N, np, f, zs, zr, rmax, dr, H, dz, tlmin, tlmax, dep, ...
c, rho, alpha] = ReadEnvParameter('input_SMPE.txt');

c0 = 1500;
ns = 1;
r  = dr : dr : rmax;
nr = length(r);
w  = 2 * pi * f;
k0 = w / c0;

x  = cos( (0 : N) * pi / N )';  
z  = (1.0 - x) * H / 2;         
cs     = interp1(dep, c,     z, 'linear');
rho    = interp1(dep, rho,   z, 'linear');
alpha  = interp1(dep, alpha, z, 'linear');
n      = (c0 ./ cs .* (1.0 + 1i * alpha / (40.0 * pi * log10( exp(1.0) ) ) ) ) .^ 2 - 1.0;

C  = ConvolutionMatrix( ChebTransFFT(N, n) );
D  = DerivationMatrix ( N + 1);
X  = 4.0 / H ^ 2 / k0 ^ 2 * ConvolutionMatrix( ChebTransFFT(N, rho) ) ...  
           * D  * ConvolutionMatrix( ChebTransFFT(N, 1.0 ./ rho) )* D + C;

%*********calculated the initial field*************
zd = 0 : 0.1 * dz : H;

cw = interp1(dep, c, zd, 'linear');
[~, ~, ~, ~, ~, starter] = selfstarter(zs, 0.1 * dz, k0, w, cw', np, ns, c0, dr, length(zd));

starter  = interp1(zd, starter, z, 'linear');
psi      = zeros(N + 1, nr);
psi(:, 1)= ChebTransFFT(N, starter);
[pade1, pade2] = epade(np, ns, 1, k0, dr);

%*****************split-step interation******************  
B = zeros(N + 1, N + 1);
A = zeros(N + 1, N + 1);
T = eye(N + 1);

for ip = 1 : np
    A = eye(N + 1) + pade1(ip) * X;    
    B = eye(N + 1) + pade2(ip) * X;
    B(N  ,       :) =  1.0;
    B(N+1, 1:2:N+1) =  1.0; 
    B(N+1, 2:2:N+1) = -1.0; 
    T               = B \ A * T;
end

for ir = 2 : nr
    psi(:, ir) = T * [psi(1 : N - 1, ir - 1); 0; 0];
end

psi = psi .* exp(1i * k0 * dr);
zl  = 0 : dz : H;
xl  = 1 - 2 ./ H * zl' ;
u   = InvChebTrans(psi, xl);
u   = u * diag( 1 ./ sqrt(r) ); 

%********************plot the results**************************

tl    = - 20 * log10( abs( u ));
tl_zr = interp1(zl,  tl,  zr,  'linear');
ShowSoundField(r,  zl,  tl,  tlmin,  tlmax,  casename);
ShowTLcurve(r,  zr,  tl_zr);   
toc;
