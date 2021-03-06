%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION
% * Read seam data
% * Get all the parameters (from header file and fk spectrum)
% * Upscale the data to higher frequencies/smaller spacings
% * Save a Parameters.m file

% * The data are a common shot gather
% * Apply reciprocity and assume it is a common receiver gather
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




close all 

%% 1 Load data

header = load('../Seam4Chris_hdrs.mat');
hdrs = header.hdrs;

data = load('../Seam4Chris.mat');
p = data.p;



%% 2 Look at the data

xr  = 81;
yr  = 81;

% Data sorting: Time x Crossline sources x Inline sources
figure(1);imagesc(squeeze(p(:,xr-20:xr,50))); colormap gray

% Time slice
figure(2); imagesc(squeeze(p(120,xr-20:xr,:))); colormap gray

% Where is the receiver location? Early time slice
figure(3); imagesc(squeeze(p(5,:,:))); colormap gray




%% 3 Find the parameters

% How is the data sorted?
%       -> I think it should be: Time x Inline sources x Crossline sources
%       -> For symmetry reasons I think I can assume the sorting was
%          Time x Crossline sources x inlince sources


% Data dimensions
[Nt,Nsx,Nsi] = size(p);

% Parameters
dx  = 50;           % Crossline spacing in metres
di  = 50;           % Inlince spacing in metres
dkx = 1/dx/Nsx;     % Size of a crossline wavenumber sample
dki = 1/di/Nsi;     % Size of an inline wavenumber sample

Nrx = 1;            % Number of crossline receivers
Nri = 1;            % Number of inline receivers
Nr = Nrx*Nri;       % Number of receivers
Ns = Nsi*Nsx;       % Number of sources

dt = 0.016;         % Duration of a time sample in seconds
df = 1/dt/Nt;       % Size of a frequency sample in Hz
fmin = 0;           % Minimum frequency in Hz (Limited by the wavelet)
fmax = 16.5;        % Maximum frequency in Hz (Limited by the wavelet)
fal  = 15;          % Highest unaliased frequency in Hz ( =vmin/(2*dx) )
vmin = 1500;        % Minimum velocity in the data im m/s


% Find frequency limits
figure(4); imagesc(fftshift(abs(fft2(squeeze(p(:,:,81))))));

ylim([500,1001]);
set(gca,'YTick',[500 600 700 800 900 1000])
set(gca,'YTickLabel',{num2str(df*0),num2str(df*100),num2str(df*200),num2str(df*300),num2str(df*400),num2str(df*500)})

%% 4 Look at the wavelet

figure(5); plot(squeeze(p(:,81,81)));

T = 9 * dt;         % Wavelet duration in s


%% 5 Upscale data

% Assume the spatial spacing was 12.5m instead of 50m
%       -> Modify the other parameters correspondingly

scale = 12.5/50;

% Upscaled Parameters
dx  = scale*dx;           % Crossline spacing in metres
di  = scale*di;           % Inlince spacing in metres
dkx = 1/dx/Nsx;     % Size of a crossline wavenumber sample
dki = 1/di/Nsi;     % Size of an inline wavenumber sample

Nrx = 1;            % Number of crossline receivers
Nri = 1;            % Number of inline receivers
Nr = Nrx*Nri;       % Number of receivers
Ns = Nsi*Nsx;       % Number of sources

dt   = dt*scale;    % Duration of a time sample in seconds
df   = 1/dt/Nt;     % Size of a frequency sample in Hz
fmin = 0;           % Minimum frequency in Hz (Limited by the wavelet)
fmax = fmax/scale;  % Maximum frequency in Hz (Limited by the wavelet)
fal  = fal/scale;   % Highest unaliased frequency in Hz ( =vmin/(2*dx) )
vmin = 1500;        % Minimum velocity in the data im m/s
T    = T*scale;     % Wavelet duration in seconds


% Find frequency limits
figure(6); imagesc(fftshift(abs(fft2(squeeze(p(:,:,81))))));

ylim([500,1001]);
set(gca,'YTick',[500 600 700 800 900 1000])
set(gca,'YTickLabel',{num2str(df*0),num2str(df*100),num2str(df*200),num2str(df*300),num2str(df*400),num2str(df*500)})



% Save parameters to a file
%save('../Data/Parameters.mat','Nt','Nrx','Nri','Nsx','Nsi','Nr','Ns','dt','dx',...
    % 'di','vmin','fmin','fmax','fal','df','dkx','dki','T','xr','yr');
