%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE
% 1 Sort and save data in Delphi format
% 2 Sort and save data in Cartesian format
% - Select a small part of the data to reduce computation time for first
%   tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%% 3 Reduce data size

% Reduce number crossline sources
 Nsx = 21; 

% Write a new parameter file with updated values
% Copy the file Parameters.mat
copyfile('../Data/Parameters.mat','../Data/Parameters_red.mat');

% Update the parameters in the copy Parameters_red.mat
fileID = '../Data/Parameters_red.mat';
m = matfile(fileID,'Writable',true);

m.Nsx = Nsx;
m.Ns  = Nsx * Nsi;
m.dkx = 1/Parameters.dx/Nsx;     % Size of an crossline wavenumber sample,  1/dx/Nsx;

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

