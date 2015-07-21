%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PURPOSE

% * Blend the SeamData with different blending patterns and different
%   maximum firing time delays
% * Deblend the data and measure the deblending quality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTENT

% 1 Load data, fkk-mask, and parameters
% 2 Initiate quality and time matrix
% 3 Generate random series for (1) the random firing time delays, and 
%   (2) the random source permutation
% 4 Loop over different blending patterns and firing time delays
%       -> Generate different blending matrices
%       -> Blend and deblend the data
%       -> Write a Results.txt file
% 5 Save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wavelet duration: 144 ms, 36 time samples

addpath('Functions/');

%% 1.1 Load data

% Load the bandlimited data in Delphi format
fileID  = 'Data/p_red_fil_Delphi.mat';
my_data = load(fileID);
data3d  = my_data.data3d_fil; clear fileID my_data

%% 1.2 Load the fkk-mask

% Load the fkk-mask (Cartesian format)
fileID = 'Data/fk/fkmask_x21.mat';
FKmask = load(fileID);
fkmask = FKmask.mask; clear fileID Fkmask

%% 1.3 Load and set general parameters
%       -> Wavelet duration: 144 ms, 36 time samples

% Load the paramteres which belong to the loaded data (in this case reduced data)
fileID = 'Data/Parameters_red.mat';
Parameters = load(fileID); 

dt   = Parameters.dt;   % Duration of a time sample
Nt   = Parameters.Nt;   % Number of time samples
Nsx  = Parameters.Nsx;  % Number of crossline sources
Nsi  = Parameters.Nsi;  % Number of inline sources
Ns   = Parameters.Ns;   % Number of sources

% Blending parameters
b    = 7;               % Blending factor for a 21 x 51 source grid
Ne   = Ns/b;            % Number of experiments
clear fileID Parameters

%% 1.4 Variation of random parameters

% Repeat the computation with different random number series
% Obtain an average Q
% Extract maximum Q values
Nran = 40;  % Number of random number iterations

%% 2 Initiate matrices for quality factors and computation time

quality     = zeros(3,15,Nran);     % Number of row:     Number of pattern
                                    % Number of columns: Number of shooting windows
time        = zeros(size(quality));
%incoherency = zeros(size(quality));

%% 3 Generate random series for time delays and source permutation

% Initiate random number series
random_times = zeros(Ne,b-1,Nran);
random_sources = zeros(Nsi,Nsx,Nran);

for ran = 1:Nran

% Create random series for the firing time delays
for exp = 1:Ne
    random_times(exp,:,ran) = rand(b-1,1);
end

% Create random series for the source permutation

for in = 1:Nsi
    ind = (in-1)*Nsx + randperm(Nsx);
    random_sources(in,:,ran) = ind;
end

%% 4 Loop over different blending patterns and firing time delays

% Default deblending time
time_deblending = 99999;

total = tic;

for pattern = 1:3
    
    % Choose a folder based on the pattern
    if pattern == 1
        folder = '1-time';
    elseif pattern == 2
        folder = '2-time-xline';
    elseif pattern == 3
        folder = '3-xline';
    end
    
    for t_g = 0:10:140 
        
        % tg is supposed to be an even number, to make sure Nt + tg is
        % still an odd number to avoid fft artifacts
        if mod(t_g,2) ~= 0;
            t_g = t_g+1;
        end
        
        % Display the iteration number
        disp(['                      Random iteration: ',sprintf('%d / %d',ran,Nran)]);
        disp(['                               Pattern: (',num2str(pattern), '/3), (',folder,')']);
        disp(['                                   t_g: ',num2str(t_g)]);
        disp(['Duration of the previous iteration (s): ',num2str(time_deblending)]);
        
        % Choose a subfolder based on t_g
        subfolder = sprintf('tg%d',t_g);
        
        % Set an input path for blend_deblend.m, and a general path
        % These pathes lead to the location where the data should be saved
        path_for_blend_deblend = strcat('/',folder,'/',subfolder,'/');
        path = strcat('Data',path_for_blend_deblend);
        
        % Create a 2d blending matrix
        g = gxin(t_g,Ns,Nsx,b,pattern,squeeze(random_times(:,:,ran)),...
                        squeeze(random_sources(:,:,ran)));
        %save(strcat(path,'g_matrix.mat'),'g')
        %mu = incoherency_dia(g,Nt);
        
        % Blend & deblend the data. Measure the computation time.
        bl = tic;
        [~,Q] = blend_deblend_mod(data3d,fkmask,g,'Data');
        time_deblending = toc(bl);
     
        % Load quality factor
%         fileID = strcat(path,'Q.mat');
%         Quality = load(fileID);
%         Q = Quality.Q; clear fileID Quality
        
        % Write a result file
        % Uncomment to write a result fil
%         fid = fopen(strcat(path,'Results.txt'),'w');
%         
%         fprintf(fid,'Acquisition Set Up \n');
%         fprintf(fid,'Parameter file: \t\tData/Parameters_red.mat \n');
%         fprintf(fid,'Blending factor: \t\t%d \n',b);
%         fprintf(fid,'Shooting window (seconds): \t%f \n',t_g*dt);
%         fprintf(fid,strcat('Blending pattern: \t\t',folder,'\n\n'));
%         
%         fprintf(fid,'Deblending quality: \t\t%f \n',Q(1));
%         fprintf(fid,'Computing time (seconds): \t%f \n\n',time_deblending);
%         
%         fprintf(fid,'Incoherency: \t\t %f \n',mu);
%         fprintf(fid,'Computing time (seconds): \t%f \n',t_in);
%         
%         fclose(fid); clear fid
        
        index = floor(t_g/10)+1;      
        quality(pattern,index,ran)     = Q(1);
        time(pattern,index,ran)        = time_deblending;
        %incoherency(pattern,index,ran) = mu;
        
    end
end

end
total_time = toc(total);


%% 5 Save results 

save('Data/ParameterTest/ran_Total_Elapsed_Time','total_time')

% Save measured parameters
save('Data/ParameterTest/ran_quality','quality')
save('Data/ParameterTest/ran_time','time')
%save('Data/ParameterTest/incoherency','incoherency')

% Save random series
save('Data/ParameterTest/ran_rand_times','random_times')
save('Data/ParameterTest/ran_rand_sources','random_sources')