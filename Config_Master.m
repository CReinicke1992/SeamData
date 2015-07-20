% PURPOSE
% * Input a desired data size
% * This program should extract the desired data, apply fk etc.

addpath('Functions/');

%% 1 Define number data size
Nsx = 36;


%% 2 Load data and parameters

% Data in Cartesian format
data5d = load('Data/p_raw_Cartesian.mat');
data5d = data5d.data5d;

% PARAMETERS
fileID = 'Data/Parameters.mat';
Parameters = load(fileID); clear fileID

dt  = Parameters.dt;    % Duration of a time sample in seconds
di  = Parameters.di;    % Inline spacing in metres
dx  = Parameters.dx;    % Crossline spacing in metres
Nt  = Parameters.Nt;    % Number of time samples
Nrx = Parameters.Nrx;   % Number of crossline receivers
Nri = Parameters.Nri;   % Number of inline receivers
Nsi = Parameters.Nsi;   % Number of inline sources
Nr  = Parameters.Nr;    % Number of receivers
Ns  = Nsx * Nsi;        % Number of sources
xr  = Parameters.xr;    % Receiver crossline position
yr  = Parameters.yr;    % Receiver inline position

fmin = Parameters.fmin;  % Minimum frequency in Hz (Limited by the wavelet)
fmax = Parameters.fmax;  % Maximum frequency in Hz (Limited by the wavelet)
fal  = Parameters.fal;   % Highest unaliased frequency in Hz ( =vmin/(2*dx) )
df   = Parameters.df;    % Size of a frequency sample in Hz


%% 3 Adjust parameters & Save an updated Parameter.mat file

dkx = 1/dx/Nsx;         % Crossline wavenumber sample size
dki = 1/di/Nsi;         % Inline wavenumber sample size

% Make a new directory
dir = strcat('Data_Nsx',num2str(Nsx));
if exist(dir,'dir') ~= 7
    mkdir(dir);
end

% Write a new parameter file with updated values
% Copy the file Parameters.mat
copyfile('Data/Parameters.mat',strcat(dir,'/Parameters_red.mat'));

% Update the parameters in the copy Parameters_red.mat
fileID = strcat(dir,'/Parameters_red.mat');
m = matfile(fileID,'Writable',true);

m.Nsx = Nsx;
m.Ns  = Ns;
m.dkx = dkx;

%% 4 Save data with reduced size

% Define a range of the crossline sources which should be extracted
%   -> Choose Nsx sources to the "right" of the receiver
left  = xr; 
right = left + Nsx - 1;

data5d_red = data5d(:,:,:,left:right,:);
data_red = trans_5D_3D(data5d_red);

save(strcat(dir,'/p_red_Cartesian.mat'),'data5d_red'); %clear data5d_red
save(strcat(dir,'/p_red_Delphi.mat'),'data_red');

%% 5 fkk Mask

dim  = 3;
tune = 1;
mask = fkmask5d(data5d_red,dt,dx,di,fmax,dim,tune,Nri,Nsi,fmin);

if exist(strcat(dir,'/fk'),'dir') ~= 7
    mkdir(strcat(dir,'/fk'));  
end

save(strcat(dir,'/fk/fkmask.mat'),'mask');

%% 6 Taper in xline direction

taper = ones(size(data5d_red));
m = (1 + cos((0:3)/3*pi)) ./ 2;
n = max(size(m));
taper(:,:,:,1:n,:)         = repmat( flip(m,2),Nt,Nrx,Nri,1,Nsi );
taper(:,:,:,end-n+1:end,:) = repmat( m,        Nt,Nrx,Nri,1,Nsi );

save(strcat(dir,'/xline_taper.mat'),'taper');

%% 7 Apply the fkk mask

data_fil = fk3d_mod(data5d_red.*taper,mask,Nri,Nsi); clear mask
data3d_fil = trans_5D_3D(data_fil);
save(strcat(dir,'/p_red_fil_Delphi.mat'),'data3d_fil');
save(strcat(dir,'/p_red_fil_Cartesian.mat'),'data_fil');

%% 8 Run Deblending Test

b = 12; Ne = Ns/b;
Deblending_Test_mod(dir,b,Ne);

