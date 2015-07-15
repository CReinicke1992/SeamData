%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE
% 1 Sort and save data in Delphi format
% 2 Sort and save data in Cartesian format
% 3 Select a small part of the data to reduce computation time for first
%   tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('Functions/');

%% Load data & Parameters
cd ..
fileID = 'ComplexData4Chris_data.mat';
SavedData = load(fileID); clear fileID

fileID = 'Parameters.mat';
Parameters = load(fileID); clear fileID
cd Deblending

p = SavedData.p;

% PARAMETERS
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

%% Sort data in Delphi format

% DATA FORMAT
% Time x Inline sources x Crossline sources

% DESIRED DATA FORMAT
% Time x Crossline * Inline receivers x Crossline*Inline sources
data = zeros(Nt,Nr,Ns);

% Sort data
for in = 1:Nsi
    data( :,1,1+(in-1)*Nsx : in*Nsx ) = p(:,in,:);
end
clear p

%save('Raw-Data/data_Delphi_Format.mat','data');

% Plot data in Delphi format
data2d = reshape(data(:,1,:),Nt,Ns); 
figure(1); imagesc(100*data2d);
xlabel('Source number','fontweight','bold');
ylabel('Time (4ms/sample)','fontweight','bold');
set(gca,'FontSize',14);
title('Data in Delphi format');
%savefig('Plots/Data_Delphi_Format');
clear data2d

%% Sort data in Cartesian format

data5d = trans_5D_3D(data,Nri,Nsi);
%save('Raw-Data/data_Cartesian_Format.mat','data5d');

%% Reduce data size

% Reduce number of time samples and inline sources
Nt = 1001;  Nsx = 51; Nsi = 51;  %Nsx = 21; Nsi = 51;

%dx = 25;    di = 25;

% Write a new parameter file with updated values
cd ..
% Copy the file Parameters.mat
copyfile('Parameters.mat','Parameters_red.mat');

% Update the parameters in the copy Parameters_red.mat
fileID = 'Parameters_red';
m = matfile(fileID,'Writable',true);
m.Nt  = Nt;
m.Nsx = Nsx;
m.Nsi = Nsi;
m.Ns  = Nsx * Nsi;
m.df  = 1/Parameters.dt/Nt;      % Size of a frequency sample in Hz
m.dkx = 1/Parameters.dx/Nsx;     % Size of an crossline wavenumber sample,  1/dx/Nsx;
m.dki = 1/Parameters.di/Nsi;     % Size of an inline wavenumber sample,     1/di/Nsi;

%m.dx = dx;
%m.di = di;

fileID = 'Parameters_red.mat';
Parameters_red = load(fileID); clear fileID

cd Deblending/

%% Save data with reduced size

% Define a range of the crossline sources which should be extracted
% One could also choose crosslines 1:Nsx_red but then the data will be less
% symmetric
left  = ceil(  0.5 * ( size(data5d,4) - Parameters_red.Nsx )  ); 
right = left + Nsx - 1;

% For /Users/christianreinicke/Dropbox/MasterSemester/SyntheticData/V3
%left  = ceil(  0.5 * ( size(data5d,4) - 2*Parameters_red.Nsx )  ); 
%right = left + 2*Nsx - 1;

% For /Users/christianreinicke/Dropbox/MasterSemester/SyntheticData/V4
%left  = ceil(  0.5 * size(data5d,4) ); 
%right = left + Nsx - 1;


data5d_red = data5d(1:Parameters_red.Nt,:,:,left:1:right,1:1:Parameters_red.Nsi); clear data5d
data_red = trans_5D_3D(data5d_red);

%save('Raw-Data/data_red_Cartesian_Format.mat','data5d_red'); clear data5d_red
%save('Raw-Data/data_red_Delphi_Format.mat','data_red');

%% Plot data with reduced size

% Plot data in Delphi format
data2d = reshape(data_red(:,1,:),Parameters_red.Nt,Parameters_red.Ns); 
figure(1); imagesc(data2d); colormap gray; clear data2d
xlabel('Source number','fontweight','bold');
ylabel('Time (4ms/sample)','fontweight','bold');
set(gca,'FontSize',14);
title('Data in Delphi format (reduced size)');
savefig('Plots/Data_red_Delphi_Format');

