function [dirs, host] = setDirs(project)
% function dirs = setDirs(project)
%
% setting up directory paths for a project
%
% INPUTS    project = name of the project (string)
%
% OUTPUTS   dirs = structure with directory info
%
% Developed by Elaine Kearney, Oct 2020 (elaine-kearney.com)
% Edited by Jordan Manes, Jan 2021 (jordanleighmanes@gmail.com)
%
%% default to AudDev as project
if nargin == 0
    project = 'AudDev';
    pilot = 'AudDev-PILOT';
else
    pilot = [project '-PILOT'];
end

%% Determine hostname of system
% This section looks for the 'local' hostname of the computer running the
% script (based on the computer's OS).

if ispc % If running on a Windows
    [~,host] = system('hostname');
    host     = deblank(host);
    
    % set priority for matlab to high for running experiments
    system(sprintf('wmic process where processid=%d call setpriority "high priority"',feature('getpid')));
    
elseif ismac % If running on a Mac
    [~,host] = system('scutil --get LocalHostName');
    host     = deblank(host);
    
elseif isunix % If running on Linux
    [~,host] = system('hostname -s');  % Needs to be tested on Linux machine
    host     = deblank(host);
end


%% Set appropriate directories for code, data input and output, based on system hostname.
if strncmpi('scc-x02', host, 3) % Using SCC
    
    % project (set per user on SCC; assumes that GitHub repo has been
    % cloned to /projectnb/busplab/UserData/[USER])
    
    curDir = pwd;
    if contains(curDir, 'yshroff') % Yash
        
        dirs.projRepo = fullfile('/projectnb/busplab/UserData/yshroff/', project);
        
    elseif contains(curDir, 'ekearney') % Elaine
        
        dirs.projRepo = fullfile('/projectnb/busplab/UserData/ekearney/', project);
        
    else
        error('Directory listings are not setup for this user on the SCC. Modify setDirs function.');
    end
    
    % pilot
    dirs.pilot = fullfile('/projectnb/busplab/Experiments/', pilot);
    
    % code
    dirs.code = fullfile(dirs.projRepo, 'code');
    
    % stimuli
    dirs.stim = fullfile(dirs.code, 'experiment','stimLists');
    
    
    % config
    dirs.config = fullfile(dirs.projRepo, 'config', 'ACOUSTIC');
else
    switch host
        
        case 'Jordans-MacBook-Pro' % Jordan's personal laptop
            
            % project
            dirs.projRepo = sprintf('/Users/jordanmanes/GitHub/%s/', project);
            
            % pilot
            dirs.pilot = sprintf('/Users/jordanmanes/GitHub/%s/', pilot);
            
            
            % code
            dirs.code = fullfile(dirs.projRepo, 'code');
            
            % stimuli
            dirs.stim = fullfile(dirs.code, 'experiment','stimLists');
            
            % audapter
            %dirs.audapter = 'C:\speechres\Audapter\';
            
            % config
            dirs.config = fullfile(dirs.projRepo, 'config', 'ACOUSTIC');
            
            % SCC mounted drive
            dirs.scc = sprintf('/Users/jordanmanes/SCC_Guenther/');
            
        case '677-GUE-ML-0001' % Jordan's lab laptop
            
            % project
            dirs.projRepo = fullfile('/Users/jmanes/Documents/GitHub/', project);
            
            % pilot
            dirs.pilot = fullfile('/Users/jmanes/Documents/GitHub/', pilot);
            
            % add paths to audapter repos
            addpath(genpath('/Users/jmanes/Documents/GitHub/audapter_matlab'));
            addpath(genpath('/Users/jmanes/Documents/GitHub/commonmcode'));
            
        case '677-GUE-WL-0002' % CNC Experiment Laptop
            
            % project
            dirs.projRepo = sprintf('C:\\%s\\', project);
            
            % pilot
            dirs.pilot = sprintf('C:\\%s\\', pilot);
            
            % audapter & related repos
            dirs.audapter = 'C:\audapter_mex\BIN\release';
            addpath(genpath(dirs.audapter));
            dirs.audapter_matlab = 'C:\speechres\Audapter\audapter_matlab';
            addpath(genpath(dirs.audapter_matlab));
            dirs.commonmcode = 'C:\speechres\Audapter\commonmcode';
            addpath(genpath(dirs.commonmcode));
            
        case '677-GUE-WD-0013' % Sound booth computer
            
            % project
            dirs.projRepo = sprintf('C:\\%s\\', project);
            
            dirs.scc = sprintf('C:\\%s\\', project);
            
            % pilot
            dirs.pilot = sprintf('C:\\%s\\', pilot);
          
            % audapter & related repos
            dirs.audapter = 'C:\speechres\Audapter\';
            addpath(genpath(dirs.audapter));
            dirs.audapter_matlab = 'C:\speechres\Audapter\audapter_matlab';
            addpath(genpath(dirs.audapter_matlab));
            dirs.commonmcode = 'C:\speechres\Audapter\commonmcode';
            addpath(genpath(dirs.commonmcode));
            
            % analysis software
            addpath('C:\speechres\spm12\')
            addpath('C:\speechres\conn\')
            addpath('C:\speechres\FLvoice\')
            
        case '677-gue-wl-0003' % SPLAB second laptop (JT)
            
            % project
            dirs.projRepo = sprintf('C:/GitHub/%s/', project);
            
            % pilot
            dirs.pilot = sprintf('C:/GitHub/%s/', pilot);
            
            % audapter
            dirs.audapter = 'C:/Github/audapter_mex/BIN/Release/';
            
            % audapter_matlab
            dirs.audapter_matlab = 'C:/GitHub/audapter_matlab/';
            
            % scc data directory (requires mapping scc drive to local machine)
            dirs.scc = 'Z:';
            
            addpath(genpath(dirs.audapter));
            addpath(genpath(dirs.audapter_matlab));
            
        case 'DESKTOP-M88NOVM' % Ricky's laptop
            % project
            dirs.projRepo = fullfile('C:\Users\RickyFals\Documents\0BU\0GuentherLab\LabGit\', project);
            % pilot
            dirs.pilot = fullfile('C:\Users\RickyFals\Documents\0BU\0GuentherLab\LabGit\', pilot);
            
        case 'Elaines-MacBook-Pro'
            % project
            dirs.projRepo = fullfile('/Users/elainekearney/Repos/', project);
            
            % pilot
            dirs.pilot = fullfile('/Users/elainekearney/Repos/', pilot);
            
            % add paths to audapter repos
            addpath(genpath('/Users/elainekearney/Repos/audapter_matlab'));
            addpath(genpath('/Users/elainekearney/Repos/commonmcode'));
            
            % analysis software
            addpath('/Users/elainekearney/Repos/spm12/');
            addpath('/Users/elainekearney/Repos/conn/');
            addpath('/Users/elainekearney/Repos/FLvoice/');
            flvoice('root', dirs.projRepo);
            
        case 'Jasons-iMac'
            % project
            dirs.projRepo = fullfile('/Users/jason/BU/GitHub/', project);
            
            % pilot
            dirs.pilot = fullfile('/Users/jason/BU/GitHub/', pilot);
            
            % add paths to audapter repos
            addpath(genpath('/Users/jason/BU/GitHub/audapter_matlab'));
            addpath(genpath('/Users/jason/BU/GitHub/commonmcode'));
            
        case 'DESKTOP-804DML1' % Alex Laptop
            
            % project
            dirs.projRepo = fullfile('C:\\Users\maest\Documents\GitHub\', project);
            
            % pilot
            dirs.pilot = fullfile('C:\Users\maest\Documents\\BU\Neuro\Lab\Code\', pilot);
            
            % audapter
            addpath(genpath('C:\Users\maest\Documents\GitHub\audapter_matlab'));
            addpath(genpath('C:\Users\maest\Audapter\audapter_mex'));
            
            % commonmcode
            addpath C:\Users\maest\Documents\GitHub\commonmcode
            
        case 'Alfonsos-MacBook-Pro-2018'
            % project
            dirs.projRepo = fullfile('/Users/Shared/GitHub/', project);
            
            % pilot
            dirs.pilot = fullfile('/Users/Shared/GitHub/', pilot);
            
            % add paths to audapter repos
            addpath(genpath('/Users/Shared/GitHub/audapter_matlab'));
            addpath(genpath('/Users/Shared/GitHub/commonmcode'));
            
        case 'DESKTOP-BLV0TSC' %Frank's home Desktop
            % project
            dirs.projRepo = fullfile('C:\Users\fguen\Dropbox\Documents\MATLAB\', project);
            
            % pilot
            dirs.pilot = fullfile('C:\Users\fguen\Dropbox\Documents\MATLAB\', pilot);
            
            % audapter
            dirs.audapter = 'C:\Users\fguen\Dropbox\Documents\MATLAB\audapter_mex\bin\Release\';
            
            % audapter_matlab
            dirs.audapter_matlab = 'C:\Users\fguen\Dropbox\Documents\MATLAB\audapter_matlab\';
            
            % commonmcode
            addpath(genpath('C:\Users\fguen\Dropbox\Documents\MATLAB\commonmcode'));
            
            addpath(genpath(dirs.audapter));
            addpath(genpath(dirs.audapter_matlab));

        case 'AJA-PC' % Alex's PC

            % project
            dirs.projRepo = fullfile('C:\Users\Alex\Documents\Github', project);

            dirs.pilot = fullfile('C:\Users\Alex\Documents\MATLAB\AudDev-PILOT', pilot);

            % Analysis software

            % analysis software
            addpath('C:\Users\Alex\Documents\speechres\spm12');
            addpath('C:\Users\Alex\Documents\GitHub\conn');
            addpath('C:\Users\Alex\Documents\GitHub\FLvoice');
            
        otherwise
            
            disp('Directory listings are not set up for this computer. Please check that your hostname is correct.');
            
            return
    end
end

% paths common to all hosts
% code
dirs.code = fullfile(dirs.projRepo, 'code');

% stimuli
dirs.stim = fullfile(dirs.code, 'experiment','stimLists');

% config
dirs.config = fullfile(dirs.projRepo, 'config', 'ACOUSTIC');
dirs.audapter_config = fullfile(dirs.config, 'audapter');

% add paths to folders and subfolders
addpath(genpath(dirs.projRepo));
addpath(genpath(dirs.pilot));

end