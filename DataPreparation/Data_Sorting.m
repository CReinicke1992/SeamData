%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE
% 1 Sort and save data in Delphi format
% 2 Sort and save data in Cartesian format
% 3 Top mute
% 4 Select a small part of the data to reduce computation time for first
%   tests
% 5 Build a taper for the crossline direction to avoid stripes in fk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all


addpath('../Functions/');

%% 1 Load data & Parameters

% Data
fileID = '../Seam4Chris.mat';
SavedData = load(fileID); clear fileID
p = SavedData.p;


% PARAMETERS
fileID = '../Data/Parameters.mat';
Parameters = load(fileID); clear fileID

dt  = Parameters.dt;    % Duration of a time sample in seconds
di  = Parameters.di;    % Inline spacing in metres
dx  = Parameters.dx;    % Crossline spacing in metres
Nt  = Parameters.Nt;    % Number of time samples
Nrx = Parameters.Nrx;   % Number of crossline receivers
Nri = Parameters.Nri;   % Number of inline receivers
Nsx = Parameters.Nsx;   % Number of crossline sources
Nsi = Parameters.Nsi;   % Number of inline sources
Nr  = Parameters.Nr;    % Number of receivers
Ns  = Parameters.Ns;    % Number of sources
xr  = Parameters.xr;    % Receiver crossline position
yr  = Parameters.yr;    % Receiver inline position

%% 2.1 Sort data in Delphi format

% DATA FORMAT: Nt x Nsx x Nsi 

% DESIRED DATA FORMAT
% Time x Crossline*Inline receivers x Crossline*Inline sources
data = zeros(Nt,Nr,Ns);

% Sort data
for in = 1:Nsi
    data( :,1,1+(in-1)*Nsx : in*Nsx ) = p(:,:,in);
end
clear p

save('../Data/p_raw_Delphi.mat','data');

%% 2.2 Sort data in Cartesian format

data5d = trans_5D_3D(data,Nri,Nsi);
save('../Data/p_raw_Cartesian.mat','data5d');

%% 3 Top mute
%   -> Suppress the direct wave

for xs = 1:Nsx
    for ys = 1:Nsi
        
        dist  = 12.5*sqrt( (xr-xs)^2 + (yr-ys)^2 );      % Receiver source distance 
        v     = 1500;                                    % Water Velocity
        delay = 20*dt;                                   % Supress tail of the direct wave
        t     = round( (dist/v + delay)/dt );
  
        data5d(1:t,1,1,xs,ys) = 0;%* data5d(1:t,1,1,xs,ys);
        
    end
end

%% 4.1 Reduce data size

% Reduce number crossline sources
Nsx = 21; 
dkx = 1/Parameters.dx/Nsx;     % Size of an crossline wavenumber sample,  1/dx/Nsx;
Ns  = Nsx * Nsi;

% Write a new parameter file with updated values
% Copy the file Parameters.mat
copyfile('../Data/Parameters.mat','../Data/Parameters_red.mat');

% Update the parameters in the copy Parameters_red.mat
fileID = '../Data/Parameters_red.mat';
m = matfile(fileID,'Writable',true);

m.Nsx = Nsx;
m.Ns  = Ns;
m.dkx = dkx;

%% 4.2 Save data with reduced size

% Define a range of the crossline sources which should be extracted
%   -> Choose 20 sources to the "right" of the receiver
left  = xr; 
right = left + 20;

data5d_red = data5d(:,:,:,left:right,:);
data_red = trans_5D_3D(data5d_red);

save('../Data/p_red_Cartesian.mat','data5d_red'); %clear data5d_red
save('../Data/p_red_Delphi.mat','data_red');

%% 4.3 Plot data with reduced size

% Plot data in Delphi format
data2d = reshape(data_red(:,1,:),Nt,Ns); 
figure; imagesc(data2d,[-0.0001,0.0001]); colormap gray; clear data2d


%% 5 Taper in crossline direction
%   -> Only 21 sources in crossline direction, i.e. FFT artifacts are very
%      likely
%   -> A taper is supposed to reduce the artifacts

taper = ones(size(data5d_red));
m = (1 + cos((0:3)/3*pi)) ./ 2;
n = max(size(m));
taper(:,:,:,1:n,:)         = repmat( flip(m,2),Nt,Nrx,Nri,1,Nsi );
taper(:,:,:,end-n+1:end,:) = repmat( m,        Nt,Nrx,Nri,1,Nsi );

save('../Data/xline_taper.mat','taper');


% data5d_red = taper.*data5d_red;
% 
% Data5d_red = fftn(data5d_red(:,1,1,:,:));
% figure; imagesc(abs(squeeze(Data5d_red(:,1,1,:,20))));
% 
% Data5d_red = fftn(squeeze(data5d_red(:,1,1,:,:)));
% figure; imagesc(abs(squeeze(Data5d_red(:,:,20))));


