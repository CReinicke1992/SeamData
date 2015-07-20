% 1 Create different blending patterns and different shooting windows
% 2 Blend Deblend the data
% - Compute incoherency
% 3 Save data
% - Write a result file with all the relevant numbers in it
% - Use a separate function to read and plot the data

% Wavelet duration: 144 ms, 36 time samples

%% Structure of this file

%%%%%%%%%%%%%%%%%%%
% NEEDS TO BE UPDATED
%%%%%%%%%%%%%%%%%%%


% 1 Add pathes to access specific functions
% 2 Load parameters from a parameter file which belongs to the Synthetic
%   Data
% 3 Create a matrix for quality factors, incoherency and computation time
% Create random number series for the pattern and the time delay
% 5 Iterate over blending patterns and shooting windows
%       -> Blend and deblend the data
%       -> Compute the incoherency of the blending pattern
%       -> Create separate folders for each iteration and save the results
%          in there

% for tg = 0:10:100
%     mkdir('Data/3-xline/',sprintf('tg%d',tg));
% end
% return

addpath('Functions/');

%% 2 Load and set general parameters

% Load the paramteres which belong to the loaded data, in this case it is
% the reduced data
fileID = 'Data/Parameters_red.mat';
Parameters = load(fileID); clear fileID

dt   = Parameters.dt;   % Duration of a time sample
Nt   = Parameters.Nt;   % Number of time samples
Nsx  = Parameters.Nsx;  % Number of crossline sources
Nsi  = Parameters.Nsi;  % Number of inline sources
Ns   = Parameters.Ns;   % Number of sources

% Blending parameters
b    = 7;               % Blending factor for a 21 x 51 source grid
Ne   = Ns/b;            % Number of experiments


%% 3 Create a matrix for quality factors, incoherency and computation time

quality     = zeros(3,11);    % Number of row:     Number of pattern
                              % Number of columns: Number of shooting windows
incoherency = zeros(size(quality));
time        = zeros(size(quality));



% Create random number series for the time delays
random_times = zeros(Ne,b-1);

for exp = 1:Ne
    random_times(exp,:) = rand(b-1,1);
end





% Randomly pick sources from a crossline
random_sources = zeros(Nsi,Nsx);
for in = 1:Nsi
    ind = (in-1)*Nsx + randperm(Nsx);
    random_sources(in,:) = ind;
end

%% 5 Loop over different blending patterns and shooting windows

for pattern = 1:3
    
    % Choose a folder based on the pattern
    if pattern == 1
        folder = '1-time';
    elseif pattern == 2
        folder = '2-time-xline';
    elseif pattern == 3
        folder = '3-xline';
    end
    
    
    for t_g = 0:10:100 % If the computation does not fail for t_g = 70,
        % then it will work for all smaller t_g
        
        % tg is supposed to be an even number, to make sure Nt + tg is
        % still an odd number to avoid fft artifacts
        if mod(t_g,2) ~= 0;
            t_g = t_g+1;
        end
        
        % Display the iteration number
        disp([' Pattern: (',num2str(pattern), '/3), (',folder,')']);
        disp(['     t_g: ',num2str(t_g)]);
        
        % Choose a subfolder based on t_g
        subfolder = sprintf('tg%d',t_g);
        
        % Set an input path for blend_deblend.m, and a general path
        % These pathes lead to the location where the data should be saved
        path_for_blend_deblend = strcat('/',folder,'/',subfolder,'/');
        path = strcat('Data',path_for_blend_deblend);
        
        % Create a 2d blending matrix
        g = gxin(t_g,Ns,Nsx,b,pattern,random_times,random_sources);
        save(strcat(path,'g_matrix.mat'),'g')
        return
        % Blend & deblend the data. Measure the computation time.
        bl = tic;
        blend_deblend(g,path_for_blend_deblend);
        time_deblending = toc(bl);
        
        inco = tic;
        in = incoherency_dia(g,Nt);
        time_incoherency = toc(inco);
        
        % Load quality factor
        fileID = strcat(path,'QualityFactor.mat');
        Quality = load(fileID);clear fileID
        Q = Quality.Q; clear Quality
        
        
        % Write a result file
        fid = fopen(strcat(path,'Results.txt'),'w');
        
        fprintf(fid,'Acquisition Set Up \n');
        fprintf(fid,'Parameter file: \t\tSyntheticData/Parameters_red.mat \n');
        fprintf(fid,'Blending factor: \t\t%d \n',b);
        fprintf(fid,'Shooting window (seconds): \t%f \n',t_g*dt);
        fprintf(fid,strcat('Blending pattern: \t\t',folder,'\n\n'));
        
        fprintf(fid,'Deblending quality: \t\t%f \n',Q);
        fprintf(fid,'Computing time (seconds): \t%f \n\n',time_deblending);
        
        fprintf(fid,'Incoherency: \t\t %f \n',in);
        -       fprintf(fid,'Computing time (seconds): \t%f \n',time_incoherency);
        
        fclose(fid);
        
        
        index = floor(t_g/10)+1;
        
        quality_matrix(pattern,index,ran)     = Q;
        incoherency_matrix(pattern,index,ran) = in;
        time_matrix(pattern,index,ran)        = time_deblending + time_incoherency;
        clear fid
        
    end
end

total_time = toc(total);

save('Data/Total_Elapsed_Time','total_time')

% Save measured parameters
save('Data/ParameterTest/quality','quality_matrix')
save('Data/ParameterTest/incoherency','incoherency_matrix')
save('Data/ParameterTest/time','time_matrix')

% Save random series
save('Data/ParameterTest/time_rand_series','time_rand_series')
save('Data/ParameterTest/space_rand_series','space_rand_series')