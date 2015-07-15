%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE
% 0 Load data and parameters
% 1 Build a fkk mask
% 2 Plot fkk mask
% 3 Apply fkk mask
% 4 Save and plot data in xt domain after fkk filtering
% 5 Save and plot data in fkk domain before fkk filtering
% 6 Save and plot data in fkk domain after fkk filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('Functions/');

%% 0 Load data & Parameters

% To keep computational effort small, I use only a small part of the data
fileID = 'Raw-Data/data_red_Cartesian_Format.mat';
SavedData = load(fileID); clear fileID

% Data in Cartesian format
data = SavedData.data5d_red; clear SavedData

cd ..
fileID = 'Parameters_red.mat';
Parameters_red = load(fileID); clear fileID
cd Deblending


% Parameters
dt   = Parameters_red.dt;    % Duration of a time sample in seconds
di   = Parameters_red.di;    % Inline spacing in metres
dx   = Parameters_red.dx;    % Crossline spacing in metres
Nt   = Parameters_red.Nt;    % Number of time samples
Nrx  = Parameters_red.Nrx;   % Number of crossline receivers
Nri  = Parameters_red.Nri;   % Number of inline receivers
Nsx  = Parameters_red.Nsx;   % Number of crossline sources
Nsi  = Parameters_red.Nsi;   % Number of inline sources
Nr   = Parameters_red.Nr;    % Number of receivers
Ns   = Parameters_red.Ns;    % Number of sources
vmin = Parameters_red.vmin;  % Minimum velocity in the data im m/s
fmin = Parameters_red.fmin;  % Minimum frequency in Hz (Limited by the wavelet)
fmax = Parameters_red.fmax;  % Maximum frequency in Hz (Limited by the wavelet)
fal  = Parameters_red.fal;   % Highest unaliased frequency in Hz ( =vmin/(2*dx) )
df   = Parameters_red.df;    % Size of a frequency sample in Hz
dkx  = Parameters_red.dkx;   % Size of a crossline wavenumber sample
dki  = Parameters_red.dki;   % Size of an inline wavenumber sample

%% 1 Build a 5d fkk mask

fcut = fmax;            % Choose fal or fmax
flow = fmin;            % The wavelet seems to have only poor frequency 
                        % contents below fmin=24 Hz. Therefore, try to cut
                        % everything below fmin.
tune = 0.15;            % The minimum velocity in the data appears to be 
                        % 1700 and 2700 m/s depending on inline/crossline. 
                        % Thus, I use 1500m/s as minimum velocity which is
                        % set by the water velocity.
dim = 3;                % A 3d mask should be build

mask = fkmask5d(data,dt,dx,di,fcut,dim,tune,Nri,Nsi,flow);
save('Data/FK/fkmask_red.mat','mask');

%% 2 Plot fkk mask

% Plot frequency slice at 40 Hz of the mask
slice = 40;
mask40 = reshape(mask(round(slice/df),1,1,:,:),Nsx,Nsi);
fig1 = figure(1); imagesc(mask40); 
xlab = sprintf('Inline Wavenumber %f m^{-1} / sample',dki);
ylab = sprintf('Crossline Wavenumber %f m^{-1} / sample',dkx); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
tit = sprintf('3d FKK Filter (Frequency slice at %.2f Hz)',slice);
title(tit);
path = sprintf('Plots/FK/fkmask_red_%dHz_slice',round(slice));
savefig(path);
close(fig1); clear mask40

% Plot inline slice of the mask for the crossline 1
slice = 1;
mask1 = reshape(mask(:,1,1,1,:),Nt,Nsi);
fig1 = figure(1); imagesc(mask1); 
xlab = sprintf('Inline Wavenumber %f m^{-1} / sample',dki);
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
tit = sprintf('3d FKK Filter (Inline slice at crossline number %d)',slice);
title(tit);
path = 'Plots/FK/fkmask_red_inline_slice';
savefig(path);
close(fig1); clear mask1

%% 3 Apply the fkk mask

data_fil = fk3d_mod(data,mask,Nri,Nsi); clear mask
data_fil3d = trans_5D_3D(data_fil);
save('Data/Data_red_Delphi_Bandlimited.mat','data_fil3d');
save('Data/Data_red_Cartesian_Bandlimited.mat','data_fil');

%% 4 Plot fkk filtered data in Delphi format in xt domain
data2d = reshape(data_fil3d(:,1,:),Nt,Ns);  clear data_fil3d
fig1 = figure(1); imagesc(data2d); colormap gray
xlabel('Source number','fontweight','bold');
ylab = sprintf('Time (%.2fms / sample)',1000*dt);
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
title('FKK filtered data (Delphi, reduced size)');
savefig('Plots/Data_red_Delphi_Bandlimited');
clear data2d
close(fig1);

%% 5 FKK domain raw data 

% Save data in FKK domain in both formats Delphi and Cartesian
Data = fftn(data); clear data
Data3d = trans_5D_3D(Data);
save('Data/FK/Data_red_Cartesian.mat','Data'); clear Data
save('Data/FK/Data_red_Delphi.mat','Data3d');

% Plot data in FKK domain in Delphi format
Data2d = reshape(Data3d(:,1,:),Nt,Ns); clear Data3d
fig1 = figure(1); imagesc(abs(Data2d));
xlab = 'Pseudo Wavenumber';
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
title('Raw data in FKK domain (Delphi, reduced size)');
savefig('Plots/FK/Data_red_Delphi');
close(fig1); clear Data2d 

%% 6 FKK domain bandlimited data

% Save FKK filtered data in FKK domain in both formats Delphi and Cartesian
Data_fil = fftn(data_fil); clear data_fil
Data3d_fil = trans_5D_3D(Data_fil);
save('Data/FK/Data_red_Cartesian_bandlimited.mat','Data_fil'); clear Data_fil
save('Data/FK/Data_red_Delphi_bandlimited.mat','Data3d_fil');

% Plot FKK filtered data in FKK domain in Delphi format
Data2d_fil = reshape(Data3d_fil(:,1,:),Nt,Ns); clear Data3d_fil
fig1 = figure(1); imagesc(abs(Data2d_fil));
xlab = 'Pseudo Wavenumber';
ylab = sprintf('Frequency %.2f Hz / sample',df); 
xlabel(xlab,'fontweight','bold');
ylabel(ylab,'fontweight','bold');
set(gca,'FontSize',14);
title('FKK filtered data in FKK domain (Delphi, reduced size)');
savefig('Plots/FK/Data_red_Delphi_bandlimited');
close(fig1); clear Data2d_fil