%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE
% 0 Load data and parameters
% 1 Build an fkk mask
% 2 Plot fkk mask
% 3 Apply fkk mask
% 4 Save and plot data in xt domain after fkk filtering
% 5 Save and plot data in fkk domain before fkk filtering
% 6 Save and plot data in fkk domain after fkk filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all

addpath('../Functions/');

%% 0 Load data & Parameters

% Data in Cartesian format
fileID = '../Data/p_red_Cartesian.mat';
SavedData = load(fileID);
data5d = SavedData.data5d_red; 

% Parameters
fileID = '../Data/Parameters_red.mat';
Parameters = load(fileID);
dt   = Parameters.dt;    % Duration of a time sample in seconds
di   = Parameters.di;    % Inline spacing in metres
dx   = Parameters.dx;    % Crossline spacing in metres
Nt   = Parameters.Nt;    % Number of time samples
Nrx  = Parameters.Nrx;   % Number of crossline receivers
Nri  = Parameters.Nri;   % Number of inline receivers
Nsx  = Parameters.Nsx;   % Number of crossline sources
Nsi  = Parameters.Nsi;   % Number of inline sources
Nr   = Parameters.Nr;    % Number of receivers
Ns   = Parameters.Ns;    % Number of sources
vmin = Parameters.vmin;  % Minimum velocity in the data im m/s
fmin = Parameters.fmin;  % Minimum frequency in Hz (Limited by the wavelet)
fmax = Parameters.fmax;  % Maximum frequency in Hz (Limited by the wavelet)
fal  = Parameters.fal;   % Highest unaliased frequency in Hz ( =vmin/(2*dx) )
df   = Parameters.df;    % Size of a frequency sample in Hz
dkx  = Parameters.dkx;   % Size of a crossline wavenumber sample
dki  = Parameters.dki;   % Size of an inline wavenumber sample

% Taper in Cartesian format (to be applied before fft)
fileID = '../Data/xline_taper.mat';
SavedData = load(fileID);
taper = SavedData.taper; clear fileID SavedData


%% 1.1 Look at fkk spectrum

Data5d = fftn( data5d .* taper );
figure(1); imagesc(abs(squeeze(Data5d(:,1,1,:,10))));
figure(2); imagesc(abs(squeeze(Data5d(:,1,1,10,:))));
save('../Data/fk/P_red_Cartesian.mat','Data5d');


%% 1.2 Build fkk mask
fcut = fmax;            % Choose fal or fmax
flow = fmin;            % The wavelet seems to have only poor frequency 
                        % contents below fmin=24 Hz. Therefore, try to cut
                        % everything below fmin.
tune = 1;               % The minimum velocity in the data appears to be 
                        % 1700 and 2700 m/s depending on inline/crossline. 
                        % Thus, I use 1500m/s as minimum velocity which is
                        % set by the water velocity.
dim = 3;                % A 3d mask should be build

mask = fkmask5d(data5d,dt,dx,di,fcut,dim,tune,Nri,Nsi,flow);
save('../Data/fk/fkmask_x21.mat','mask');

%% 2 Plot fkk mask

% Plot frequency slice at 40 Hz of the mask
slice = 40;
mask40 = reshape(mask(round(slice/df),1,1,:,:),Nsx,Nsi);
fig1 = figure(3); imagesc(mask40); 
xlab = sprintf('Inline Wavenumber %f m^{-1} / sample',dki);
ylab = sprintf('Crossline Wavenumber %f m^{-1} / sample',dkx); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
tit = sprintf('3d FKK Filter (Frequency slice at %.2f Hz)',slice);
title(tit);
%path = sprintf('Plots/FK/fkmask_red_%dHz_slice',round(slice));
%savefig(path);
%close(fig1); clear mask40

% Plot inline slice of the mask for the crossline 1
slice = 1;
mask1 = reshape(mask(:,1,1,1,:),Nt,Nsi);
fig1 = figure(4); imagesc(mask1); 
xlab = sprintf('Inline Wavenumber %f m^{-1} / sample',dki);
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
tit = sprintf('3d FKK Filter (Inline slice at crossline number %d)',slice);
title(tit);
%path = 'Plots/FK/fkmask_red_inline_slice';
%savefig(path);
%close(fig1); clear mask1

% Plot inline slice of the mask for the crossline 1
slice = 1;
mask1 = reshape(mask(:,1,1,:,1),Nt,Nsx);
fig1 = figure(5); imagesc(mask1); 
xlab = sprintf('Inline Wavenumber %f m^{-1} / sample',dki);
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
tit = sprintf('3d FKK Filter (Inline slice at crossline number %d)',slice);
title(tit);

%% 3 Apply the fkk mask

data_fil = fk3d_mod(data5d.*taper,mask,Nri,Nsi); clear mask
data3d_fil = trans_5D_3D(data_fil);
save('../Data/p_red_fil_Delphi.mat','data3d_fil');
save('../Data/p_red_fil_Cartesian.mat','data_fil');

%% 4 Plot fkk filtered data in Delphi format in xt domain
data2d = reshape(data3d_fil(:,1,:),Nt,Ns);  clear data3d_fil
figure(6); imagesc(data2d); colormap gray
xlabel('Source number','fontweight','bold');
ylab = sprintf('Time (%.2fms / sample)',1000*dt);
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
title('FKK filtered data (Delphi, reduced size)');
clear data2d

%% 6 FKK bandlimited data

% Save FKK filtered data in FKK domain in both formats Delphi and Cartesian
Data_fil = fftn(data_fil.*taper);
Data3d_fil = trans_5D_3D(Data_fil);
save('../Data/fk/P_red_fil_Delphi.mat','Data3d_fil');
save('../Data/fk/P_red_fil_Cartesian.mat','Data_fil');


% Plot FKK filtered data in FKK domain in Delphi format
Data2d_fil = reshape(Data3d_fil(:,1,:),Nt,Ns); clear Data3d_fil
fig1 = figure(7); imagesc(abs(Data2d_fil));
xlab = 'Pseudo Wavenumber';
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
title('FKK filtered data in FKK domain (Delphi, reduced size)');
%savefig('Plots/FK/Data_red_Delphi_bandlimited');
%close(fig1); clear Data2d_fil