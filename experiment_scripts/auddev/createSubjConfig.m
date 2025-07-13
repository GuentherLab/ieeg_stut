function createSubjConfig(subjectNum, prefix, group, gender, varargin)
% createSubjConfig(subjectNum, prefix, group, gender, varargin)
%
% function to create subject-session configuration files
% - randomizes order of stimlus lists within a subject
%
% INPUTS    subjectNum      subject number (will be concatenated with prefix to create subjectID)
%           prefix          character array, e.g., 'PPT', 'pilot', 'test'
%           group           character array, e.g., 'pd', 'control'
%           gender          'm' (male) or 'f' (female)
%
% OPTIONAL INPUTS (specify as name-value pair)  
%           sessNum         array specifying which sessions to create config files for (default: [1,2])
%           numRuns         total number of runs (default: 6)
%
% OUTPUTS   subject-session config files saved to study config directory
%
% e.g.      createSubjConfig(1,'PPT1', 'pd', 'f', 'sessNum', [1,2], 'numRuns', 4)
%           createSubjConfig(1,'pilot', 'control', 'm', 'sessNum', [5], 'numRuns', 6)
%
% Developed by Elaine Kearney, Oct 2020 (elaine-kearney.com)
% Matlab 2019b

%% check inputs and set key variables

% set directories
dirs = setDirs('AudDev');

% subject number
if ~isnumeric(subjectNum)
    error('specify subjectID as a number, e.g., 3')
end

% subjectID prefix
if ~ischar(prefix)
    error('specify prefix as a char array')
end

% create subjectID
if subjectNum < 10
    % pad number with a 00
    subjectID = sprintf('%s00%d', prefix, subjectNum);
elseif subjectNum >= 10 && subjectNum < 100
    % pad number with a 0
    subjectID = sprintf('%s0%d', prefix, subjectNum);
else
    subjectID = sprintf('%s%d', prefix, subjectNum);
end

% add group info
if ~ischar(group)
    error('specify group as a char array')
end
% make lower case
group = lower(group);

% gender must be 'm' or 'f'
if strcmp(gender, 'm') == 1
    gender = 'male';
elseif strcmp(gender, 'f') == 1
    gender = 'female';
else
    error('specify gender as ''m'' or ''f''')
end

% session numbers to create the config files for
if isempty(fsic(varargin, 'sessNum'))
    sessNum = [1,2];
else
    sessNum = varargin{fsic(varargin, 'sessNum') + 1};
    if~isnumeric(sessNum)
        error('specify sessNum as a number, e.g., 3')
    end
end

% number of runs
if isempty(fsic(varargin, 'numRuns'))
    numRuns = 6;
else
    numRuns = varargin{fsic(varargin, 'numRuns') + 1};
    if ~isnumeric(numRuns)
        error('specify numRuns as a number, e.g., 3')
    end
end

%% write to config file

% make subj directory
if contains(subjectID,'test','IgnoreCase',true) || contains(subjectID,'pilot','IgnoreCase',true)
    subDir = [dirs.pilot filesep 'sub-' subjectID]; % Directs test and pilot data to be saved into the project pilot directory
    dirs.config = fullfile(dirs.pilot, 'config', 'ACOUSTIC');
else
    subDir = [dirs.projRepo filesep 'sub-' subjectID];  % Directs study data to be saved into the project directory
end

if ~exist(subDir, 'dir')
    mkdir(subDir)
end

configDir = dirs.config;

% for each session
sessions = sessNum;
for i = 1:numel(sessions)
    
    % make session directory
    sesDir = fullfile(configDir, sprintf('ses-%d', sessions(i)));
    if ~exist(sesDir, 'dir')
        mkdir(sesDir)
    end
    
    % generate stimList order
    % create random number stream so randperm doesn't call the same thing everytime when matlab is opened
    s = RandStream.create('mt19937ar','seed',sum(100*clock));
    RandStream.setGlobalStream(s);
    stimListOrder = randperm(numRuns, numRuns);
    
    % save config to mat file
    fName = fullfile(sesDir, sprintf('sub-%s_ses-%d_config.mat', subjectID, sessions(i)));
    % but first check is it already exists with option to overwrite
    if exist(fName, 'file') == 2
        overwriteCfg = questdlg('This subject already has config file for this session, do you want to over-write?','Answer', 'Yes - overwrite', 'No - quit','No - quit');
        switch overwriteCfg
            
            case 'Yes - overwrite'
            % continue                 
            case 'No - quit'
                return
        end
    end
    session = sessions(i);
    save(fName, 'subjectID', 'group', 'gender', 'session', 'stimListOrder');
    
end
end