function runExp(subjectID, session)
%
% ABOUT
%       Main script for running the auditory perturbation experiments in 
%       the soundbooth in the lab, for either the aud-reflexive task or the 
%       aud-adaptive task.
%
% SECTIONS
%       initiate
%       user config
%       setup
%       paradigm config for Audapter
%       ready?
%       trial loop
%           perturbation settings for audapter
%           initialize audapter
%           set up trial timer
%           determine trial timing info
%           save trial info
%           adjust adaptable rms Thresh and pitch bounds
%       end trial
%       end experiment
%
% IMPORTANT VARIABLES
%           expParams
%               This structure contains all the information on the
%               parameters set and implied for all trials in the run, 
%               including audapter parameters, stimulus lists, subject info
%               etc. Some of these parameters, like rmsThreshold estimates
%               and pitch estimates, are set in runVoiceCal.
%           p
%               This structure contains audapter settings. This structure
%               is fed into the AudapterIO() script. Most of these settings
%               are set through the setAudapterParams script.
%           trialData
%               This structure contains trial-specific settings and
%               information, such as condition, stimulus, trial timing,
%               etc.
%
%
% INPUTS                    subjectID (e.g., PPT001, pilot001)
%                           session # (1, 2)
%
% OUTPUTS (saved to C\:DATA\AudDev\SubjectID\Session\beh)
%                           AudDev data structure
%
% Also calls:               Audapter (audapter_matlab, audapter_mex, commonmcode)
%                           checkAudapterParams.m
%                           createSubjOstFiles.m
%                           createSubjPcfFiles.m
%                           EQfilters.m
%                           ManageTime.m
%                           plotMicSignal.m
%                           setAudapterParams.m
%                           setAudioDevice.m
%                           setDirs.m
%                           setUpMicPlot.m
%                           setUpVisAnnot.m                   
%                           ost/pcf files (audapter config files)
%                           stimuli lists (see stimListGen and
%                               stimLists subdirectories)
%
%                           
% Developed in Matlab 2019b by many Guenther Speech Lab Members 2020-2023:
% Liz Heller Murray, Ricky Falsini, Elaine Kearney, Jordan Manes, Jason Tourville, Alfonso Nieto-Castanon, Alexander Acosta

%% initiate
%
% This section locates the relevant files and directories and loads the
% subject's voice calibration data
%

close all
ET = tic;

% set directories
[dirs, host] = setDirs('AudDev');

bidsSubID = ['sub-' subjectID];
bidsSesID = ['ses-' num2str(session)];

if contains(subjectID,'test','IgnoreCase',true) || contains(subjectID,'pilot','IgnoreCase',true)
    dirs.sub = fullfile(dirs.pilot, bidsSubID);
    dirs.ses = fullfile(dirs.pilot, bidsSubID, bidsSesID, 'beh');
    dirs.config = fullfile(dirs.pilot, 'config', 'ACOUSTIC');   % Directs test and pilot data to be saved into the project pilot directory
else
    dirs.sub = fullfile(dirs.projRepo, bidsSubID);
    dirs.ses = fullfile(dirs.projRepo, bidsSubID, bidsSesID, 'beh');    % Directs study data to be saved into the project directory
end

% create structure to save experimental parameters
expParams = struct;
expParams.computer = host;

% determine run #
listing = dir(dirs.ses);
compRuns = 0;   % completed runs counter, start at 0
for i = 1:numel(listing)
    if regexp(listing(i).name, 'run-\d') == 1 % start index of matched string is 1 - corresponds to run directories
        compRuns = compRuns + 1;
    end
end
runNum = compRuns+1;

% read subject-session config file
cfgMat = sprintf('sub-%s_ses-%d_config.mat', subjectID, session);
cfg = fullfile(dirs.config, bidsSesID, cfgMat);
load(cfg, 'group', 'gender', 'stimListOrder');

% read voice calibration file
voiceCalFile = fullfile(dirs.ses, 'task-voicecalibration', sprintf('%s_%s_task-voicecalibration.mat', ...
    bidsSubID, bidsSesID));
if exist(voiceCalFile, 'file') == 2
    load(voiceCalFile, 'voiceCal')
    expParams.voiceCal = voiceCal;
    expParams.pertType = voiceCal.pertType;
    expParams.pitchMethod = voiceCal.pitchMethod;
else
    error('Voice calibration file not found for %s; run runVoiceCal.m', subjectID);
end

% determine perturbation task: adaptive or reflexive
expParams.task = questdlg('Which perturbation task would you like to run?', 'Task type', 'aud-reflexive', 'aud-adaptive','aud-reflexive'); %Sets perturbation paradigm as expParams.task

dimsLines = [1 50];

expParams.sessionTime = fix(clock);
if expParams.sessionTime(4) < 12, expParams.sessionTimeLabel = 'Morning'; else expParams.sessionTimeLabel = 'Afternoon'; end

% default nLPC value
if strcmp(gender,'male')
    nLPC = 17;
elseif strcmp(gender, 'female')
    nLPC = 15;
end

%% config
%
% Presents user dialogue boxes to check experimental info and update as needed
% and input experimental parameters
%

% Prompt1 sets up acoustic processing details
prompt1 = {sprintf('Check the following for \nSubject: %s\nSession: %d\n\n Gender', ...
    subjectID, session), 'Run #', ...
    'gainAdapt? (formants)','Which PCF?', ...
    'PreEmphasis (formants)','nLPC','Which OST?','FB Value? (1=No noise)'};
defaultInput = {gender, num2str(runNum), '0', '_nogain30', '.98', ...
    num2str(nLPC),'_pthresh02','1'};
dlgtitgle = 'Config';
runPrompt = inputdlg(prompt1, dlgtitgle, dimsLines, defaultInput);

%save acoustic parameters
expParams.project = 'AudDev';
expParams.subjectID = subjectID;
expParams.session = session;
expParams.group = group;
expParams.gender = runPrompt{1};
expParams.runNum = str2double(runPrompt{2});
gainAdapt = str2num(runPrompt{3});
expParams.pcfSuffix = runPrompt{4};
preemp = str2num(runPrompt{5});
nLPC = str2num(runPrompt{6});
expParams.ostSuffix = runPrompt{7};
expParams.fb = str2num(runPrompt{8});
gender = expParams.gender;

%%% CONFIGURE TASK-SPECIFIC PARAMETERS %%%
switch expParams.task
    case 'aud-reflexive'
        
        % Practice or Experimental Run?
        runType = questdlg('What kind of run is this?','Run Type','Practice Run','Experimental Run','Practice Run');
        
        % Set default stim list, and ask about perturbation onset
        switch expParams.pertType
            case 'formant' 
                stimFileName = 'F1_30_Set';
                expParams.formantType = questdlg('Please choose formant perturbation type.', 'Formant Perturbation', 'Voice-Onset', 'Mid-Voice', 'Jittered','Voice-Onset');
                expParams.pitchType = 'N/A';
            case 'pitch'
                stimFileName = 'PPT1';
                expParams.pitchType = questdlg('Please choose pitch perturbation type.', 'Pitch Perturbation', 'Voice-Onset', 'Mid-Voice', 'Jittered','Voice-Onset');
                expParams.formantType = 'N/A';
            case 'both' 
                expParams.formantType = questdlg('Please choose formant perturbation type.', 'Formant Perturbation', 'Voice-Onset', 'Mid-Voice', 'Jittered','Voice-Onset');
                expParams.pitchType = questdlg('Please choose pitch perturbation type.', 'Pitch Perturbation', 'Voice-Onset', 'Mid-Voice', 'Jittered','Voice-Onset');
                stimFileName = 'AudDev_AllConds';
        end
        
        % Prompt 2 asks about stim list and stimulus presentation
        prompt2 = {'Stimuli List', 'Stim list order', 'Visual or Audio stimuli?'};
        defaultInput1 = {stimFileName, num2str(stimListOrder), 'Visual'};
        dlgtitle = 'Reflexive Task Additional Parameters';
        runPrompt2 = inputdlg(prompt2, dlgtitle, dimsLines, defaultInput1);
        sustained = 0;
        
        switch runType
            case 'Practice Run'
                runName = 'run-practice';
                expParams.stimFileName = [runPrompt2{1} '_practice_aud.mat'];
            case 'Experimental Run'
                runName = ['run-' num2str(expParams.runNum)];
                expParams.stimFileName = [runPrompt2{1} '_aud.mat'];
                expParams.stimListOrder = str2num(runPrompt2{2});
                stimListOrder = expParams.stimListOrder;
                save(cfg, 'gender', 'stimListOrder', '-append');
        end
        switch runPrompt2{3}, case 'Visual', audioStim = 0; case 'Audio', audioStim = 1; end

    case 'aud-adaptive'
        
        runName = ['run-' num2str(expParams.runNum)];
        
        % Set default stimulus list
        switch expParams.pertType
            case 'formant'
                stimFileName = '80-mixed_.3-Up';
            case 'pitch'
                stimFileName = '80-mixed_100-Up';
            case 'both'
                stimFileName = '80-mixed_.3-Up';
        end
        
        % Prompts 2 asks about stimulus list, stimuli presentation and production length
        defaultInput1 = {stimFileName, 'Visual', 'Sustained'};
        prompt2 = {'Stimuli List', 'Visual or audio stimuli?', 'Sustained or Natural Production?'};
        dlgtitle = 'Adaptive Task Additional Parameters';
        runPrompt2 = inputdlg(prompt2, dlgtitle, dimsLines, defaultInput1);
        
        expParams.stimFileName = [runPrompt2{1} '_aud-adaptive.mat'];
        switch runPrompt2{2}, case 'Visual', audioStim = 0; case 'Audio', audioStim = 1; end
        switch runPrompt2{3}, case 'Sustained', sustained = 1; case 'Natural', sustained = 0; end
end

clear gender runNum stimFileName

%% setup
%
% Create new directories for run info, reads the stim list, and prepares
% the overall structures for the run
%

%%% CREATE RUN DIRECTORY %%%
dirs.run = fullfile(dirs.ses,runName);
if exist(dirs.run, 'dir')
    overwriteDir = questdlg('This subject already has a directory for this run, do you want to over-write?','Answer', 'Yes - overwrite', 'No - quit','No - quit');
    switch overwriteDir
        case 'No - quit'
            return
    end
end
mkdir(dirs.run);

% filename for saving data
fName = fullfile(dirs.ses,sprintf('sub-%s_ses-%d_%s_task-%s', ...
    expParams.subjectID, expParams.session, runName, expParams.task));

% delete any previous .mat files for that run
if exist([fName '_expParams.mat'], 'file') == 2
    delete([fName '_expParams.mat'])
end
if exist([fName '.mat'], 'file') == 2
    delete([fName '.mat'])
end

%%% READ STIM LIST %%%
load(fullfile(dirs.stim, expParams.stimFileName), 'StimListSet'); % define .mat file with stimulus list for each run
% find stimList # based on run number & order in config file
switch expParams.task
    case 'aud-reflexive'
        try expParams.stimList = stimListOrder(expParams.runNum);
        catch, error('The stimListOrder in the config file has fewer elements than the # of runs. Re-run createSubjConfig with the correct # of runs.'), end
        try stimName = StimListSet.Stims(:,expParams.stimList);  % extract stimulus name (word) listfor a given run
        catch, error(sprintf('The stimListOrder value (%s) does not match the available permutations of the stimList (%s\n)', stimListOrder, size(StimListSet,2))), end
        condition = StimListSet.CondLabel(:,expParams.stimList); % extract stimulus condition list form a given run
        
    case 'aud-adaptive'
        stimName = StimListSet.Stims;
        condition = StimListSet.CondLabel;
        trialMagnitudes = StimListSet.trialMagnitudes;
        trialPhases = StimListSet.trialPhases;
        expParams.magnitude = StimListSet.magnitude;
        expParams.pertDirect = StimListSet.pertDirect;
        expParams.pertAngle = StimListSet.pertAngle;
end
expParams.numTrials = length(condition); % pull out the number of trials from the stimList

% pull out the trials from the stim list (keeps it in the same order as the stim list)
pitchUp = find(strcmp(condition, 'U0'));
pitchDown = find(strcmp(condition, 'D0'));
formantUp = find(strcmp(condition, 'U1'));
formantDown = find(strcmp(condition, 'D1'));
pitchNoShift = find(strcmp(condition, 'N0'));
formantNoShift = find(strcmp(condition, 'N1'));

% PPT1 conditions
pitchUpGradual = find(strcmp(condition, 'U0G'));
pitchUpSudden = find(strcmp(condition, 'U0S'));
pitchDownGradual = find(strcmp(condition, 'D0G'));
pitchDownSudden = find(strcmp(condition, 'D0S'));

% pitch vs formant trials
pitchTrials = [pitchUp; pitchDown; pitchNoShift; pitchUpGradual; pitchUpSudden; pitchDownGradual; pitchDownSudden];
formantTrials = [formantUp; formantDown; formantNoShift];

% create random number stream so randperm doesn't call the same thing everytime when matlab is opened
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setGlobalStream(s);

% set up visualization
annoStr = setUpVisAnnot(); 

% set up audio device
setAudioDevice(0);

% length of voice/speech recording (s)
%%% IMPORTANT NOTE from Acosta
%%% This is a *hard-coded* experimental parameter, since adjusting the
%%% recording length can mess with the OST files, since these files are
%%% instructed to hold the perturbation for a set amount of time. 
expParams.recordLen = 2.0;

% length the word is on screen (s)
expParams.stimOn = expParams.recordLen - .5;

% pitch perturbation onset jitter (relative to voice onset) - will be a random number between these two values
% No jitter if adaptive
switch expParams.task
    case 'aud-reflexive'
        expParams.pertJitterMin = 0.3;
        expParams.pertJitterMax = 0.6;
    case 'aud-adaptive'
        expParams.pertJitterMin = 0;
        expParams.pertJitterMax = 0;
end

% for non-speech trials, initiate the delay to "match" the expected delay associated with
% time to voice onset
% This is not used in AudDev experiments since it is entirely behavioral,
% but I'm keeping it here - Acosta
nonSpeechDelay = .75;

% inter-trial interval - time from start of one trial to start of the next
expParams.iti = 4.5; if audioStim, expParams.iti = expParams.iti + 2.5; end

%% Paradigm Configurations for audapter

% set up audapter
which Audapter; % makes sure audapter is mapped
Audapter info; % lets you know which sound card is being used

% set up audapter param
switch expParams.pertType
    case {'pitch', 'both'}
        
        % p is a structure that is fed into the AudapterIO script
        % containing a set of different Audapter parameters.
        p = setAudapterParams(expParams.gender, 'pitch', 'pitchMethod', expParams.pitchMethod);

        expParams.suddenPitchRamp = 0.01;     % sudden onset of 10 ms, needed for the pitch schedule
        expParams.gradualPitchRamp = 0.11;    % gradual onset of 110ms
        
        % feedback noise
        p.fb = expParams.fb;
        
        if p.fb == 3, p.fb3Gain = .05;
        end
        
        switch expParams.pitchMethod
            case 'time-domain'
                p.timeDomainPitchShiftAlgorithm = voiceCal.algo;
                p.pitchLowerBoundHz = voiceCal.p.pitchLowerBoundHz;
                p.pitchUpperBoundHz = voiceCal.p.pitchUpperBoundHz;
                f0 = voiceCal.f0;
                noShift = [0, 1];           % at end of voice onset minThreshTime window (time 0), no shift (will be used later in the pitch shift schedule)
                switch expParams.task
                    case 'aud-reflexive'
                        shiftUp = 1.0595;           % shift up 100 cents
                        shiftDown = 0.9439;         % shift down 100 cents
                    case 'aud-adaptive'
                        shiftUp = 2^(expParams.magnitude/1200); % formula for cents to ratio conversion
                        shiftDown = 2^(expParams.magnitude/1200);
                end
        end
    case 'formant'
        expParams.suddenPitchRamp = 0.01;     % sudden onset of 10 ms, needed for the pitch schedule
        expParams.gradualPitchRamp = 0.11;    % gradual onset of 110ms
        p = setAudapterParams(expParams.gender, 'formant');
end
p.nLPC = nLPC; % Linear Predictive Coding coefficient for formant tracking
switch expParams.task
    case 'aud-reflexive'
        expParams.minThreshTime = 0.04; % min time for rms to be above rmsThresh to be considered voice onset
        % note: minThreshTime needs to be equal or lower than pertJitterMin
    case 'aud-adaptive'
        expParams.minThreshTime = 0.01; % in the adaptive study it can be very low, because the perturbation should always be on the entire trial
end

checkAudapterParams(p);
AudapterIO('init', p);  % set up params for voice amplitude check
EQfilters set_audapter; % user-prompt to select audapter's input/output equalization filters
AudapterIO('reset');
Audapter('start')   % just to get audapter started
Audapter('stop')

%% ready?
% visualization
set(annoStr.Ready, 'Visible','on');     % Turn on ready
pause(2);
set(annoStr.Ready, 'Visible','off');    % Turn off ready
set(annoStr.Plus, 'Visible','on');
pause(1);
CLOCK=[];                               % Main clock (not yet started)

% save the expParams data
save([fName '_expParams.mat'], 'expParams');

% initialize Trial Signal Plotting Figure
[h1,h2,h3,sigplotTitle] = setUpMicPlot;

% initialize trialData structure
trialData = struct;

% find sound file paths
if audioStim
    soundFilePath = 'C:\AudDev\code\experiment\Audio Cues';
    [beep1, Fs1] = audioread(fullfile(soundFilePath, 'beep1.wav'));
    [beep2, ~] = audioread(fullfile(soundFilePath, 'beep2.wav'));
end

%% trial loop
% determines audapter and stimulus data for trial
for ii = 1:expParams.numTrials
    
    % set up trial (see subfunction at end of script)
    [trialData, annoStr] = setUpTrial(expParams, annoStr, stimName, condition, trialData, ii);
    
    % find and read sound file for audio stimulus presentations
    if audioStim
        if sustained, soundFile = fullfile(soundFilePath, sprintf('%s-long.wav',stimName{ii}));
        else soundFile = fullfile(soundFilePath, sprintf('%s.wav',stimName{ii}));
        end
        [soundY, Fs] = audioread(soundFile);
        if Fs ~= 44100; error('Please make sure audio files for stimulus is sampled correctly'); end
    end
    
    % save phase to trialData
    switch expParams.task
        case 'aud-adaptive'
            trialData(ii).phase = trialPhases{ii};
    end
    
    %% Preparing perturbation settings
    % if it is a pitch shift trial
    if ismember(ii, pitchTrials)
        
        % settings common to all pitch shifts
        p = setAudapterParams(expParams.gender, 'pitch', 'pitchMethod', expParams.pitchMethod, 'p', p);
        p.preempFact = 0.98;
        
        % rampTime
        if ismember(ii, pitchUp) || ismember(ii, pitchUpSudden) || ismember(ii, pitchDown) || ismember(ii, pitchDownSudden) || ismember(ii, pitchNoShift)
            rampTime = expParams.suddenPitchRamp;
        elseif ismember(ii, pitchUpGradual) || ismember(ii, pitchDownGradual)
            rampTime = expParams.gradualPitchRamp;
        end

        % which direction shift?
        if ismember(ii,pitchUp) || ismember(ii,pitchUpSudden) || ismember(ii,pitchUpGradual)
            shift = shiftUp;
        elseif ismember(ii,pitchDown) || ismember(ii,pitchDownSudden) || ismember(ii,pitchDownGradual)
            shift = shiftDown;
        elseif ismember(ii,pitchNoShift)
            shift = 1;
        end
        
        switch expParams.pitchMethod
            
            case 'phase-vocoder'
                
                % Determine ramp time
                switch expParams.task
                    case 'aud-reflexive'
                        if ismember(ii, pitchUp) || ismember(ii, pitchUpSudden) || ismember(ii, pitchDown) || ismember(ii, pitchDownSudden) || ismember(ii, pitchNoShift)
                            rampTime = expParams.suddenPitchRamp;
                        elseif ismember(ii, pitchUpGradual) || ismember(ii, pitchDownGradual)
                            rampTime = expParams.gradualPitchRamp;
                        end
                    case 'aud-adaptive'
                        rampTime = expParams.suddenPitchRamp;
                end

                % Create OST files for each trial
                createSubjOstFiles(dirs, subjectID, session, runName, 'pitch', ii, rampTime, p.rmsThresh, expParams.minThreshTime, trialData(ii).pertJitter-expParams.minThreshTime); % note: perturbation starts trialData(ii).pertJitter seconds after beginning of minThreshTime window
                trialData(ii).ostFN = fullfile(dirs.run, sprintf('sub-%s_ses-%d_%s_task-aud_trial-%d_pitchreflex.ost', subjectID, session, runName, ii));
                
                
                % Find PCF file
                if ismember(ii, pitchUp) || ismember(ii, pitchUpSudden)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_pitch_reflex_sudden_up.pcf');
                elseif ismember(ii, pitchDown) || ismember(ii, pitchDownSudden)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_pitch_reflex_sudden_down.pcf');
                elseif ismember(ii, pitchUpGradual)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_pitch_reflex_gradual_up.pcf');
                elseif ismember(ii, pitchDownGradual)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_pitch_reflex_gradual_down.pcf');
                elseif ismember(ii, pitchNoShift)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_pitch_reflex_sudden_noshift.pcf');
                end

                % Set OST and PCF files
                check_file(trialData(ii).ostFN);
                Audapter('ost', trialData(ii).ostFN, 0);
                check_file(trialData(ii).pcfFN);
                Audapter('pcf', trialData(ii).pcfFN, 0);
                
            case 'time-domain'
                
                Audapter('ost', '', 0);      % not used for time-domain pitch shift
                Audapter('pcf', '', 0);
                trialData(ii).ostFN = NaN;
                trialData(ii).pcfFN = NaN;
                Audapter('setParam','rmsthrtime',round(1000*expParams.minThreshTime),0); % wait until minThreshTime ms of supra-threshold rms
                
                % Set the thre
                if ismember(ii, pitchNoShift)
                    p.timeDomainPitchShiftSchedule = noShift; % no shift the whole time
                    
                else
                    switch expParams.task
                        case 'aud-reflexive'
                            if strcmp(expParams.pitchType,'Voice-Onset')
                                onsetRamp = [0.001, 1];
                                pitchShift = [0.1 - expParams.minThreshTime, shift];
                            elseif strcmp(expParams.pitchType,'Mid-Voice')
                                onsetRamp = [0.4 - expParams.minThreshTime - rampTime,1];
                                pitchShift = [0.4 - expParams.minThreshTime, shift];
                            elseif strcmp(expParams.pitchType, 'Jittered')
                                onsetRamp = [(trialData(ii).pertJitter - expParams.minThreshTime - rampTime), 1];
                                pitchShift = [trialData(ii).pertJitter-expParams.minThreshTime, shift];        % set pitch shift schedule
                            end
                        case 'aud-adaptive'
                            onsetRamp = [0.001,1];
                            pitchShift = [0.1, 1 - ((1 - shift) * trialMagnitudes(ii))];        % set pitch shift schedule
                            
                    end
                    p.timeDomainPitchShiftSchedule = [noShift; onsetRamp; pitchShift]; % shift up after jittered time after voice onset
                end
        end
    end
    % settings common to all formant shifts
    if ismember(ii, formantTrials)
        
        p = setAudapterParams(expParams.gender, 'formant', 'p', p);
        p.gainAdapt = gainAdapt;        % JT added to test effect of gain adaptation during formants
        p.preempFact = preemp;           % JT added to test effect of preemp param on low freq power
        %%%JT 4/14/21 modified ost file assignment to allow for user specified suffix
        %trialData(ii).ostFN = fullfile(dirs.audapter_config, 'SAP_formant_reflex_fullshift.ost');
        
        
        % direction-specific settings, separated by task
        switch expParams.task
            case 'aud-reflexive'

                % setup
                rampTime = expParams.suddenPitchRamp;

                % Create OST files for each trial
                createSubjOstFiles(dirs, subjectID, session, runName, 'formant', ii, rampTime, p.rmsThresh, expParams.minThreshTime, trialData(ii).pertJitter-expParams.minThreshTime);
                trialData(ii).ostFN = fullfile(dirs.run, sprintf('sub-%s_ses-%d_%s_task-aud_trial-%d_formantreflex.ost', subjectID, session, runName, ii));          


                % Specify your PCF files. Different PCF files for
                % perturbation type
                if ismember(ii, formantUp)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, ['AudDev_formant_reflex_6rules_UP' expParams.pcfSuffix '.pcf']);
                elseif ismember(ii, formantDown)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, ['AudDev_formant_reflex_6rules_DOWN' expParams.pcfSuffix '.pcf']);
                elseif ismember(ii, formantNoShift)
                    trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_formant_reflex_6rules_noShift.pcf');
                end

            case 'aud-adaptive'
                createSubjPcfFiles((expParams.magnitude * trialMagnitudes(ii)),...
                    expParams.pertDirect, expParams.pertAngle,dirs);
                trialData(ii).pcfFN = fullfile(dirs.audapter_config, 'AudDev_formant_adapt.pcf');
                trialData(ii).ostFN = fullfile(dirs.audapter_config, ['AudDev_onset_reflex_fullshift' expParams.ostSuffix '.ost']);
        end
        
        check_file(trialData(ii).pcfFN);
        Audapter('pcf', trialData(ii).pcfFN, 0);

        check_file(trialData(ii).ostFN);
        Audapter('ost', trialData(ii).ostFN, 0);
    end
    
    %% Initialize Audapter
    checkAudapterParams(p);
    AudapterIO('init', p); %initiate with the above selected parameters
    if strcmp(expParams.task, 'aud-adaptive') && strcmp(expParams.pitchMethod, 'time-domain')
        Audapter('setParam', 'rmsthr', .001, 0); % set the rmsThresh very low so that the perturbation coincides with voice onset
    end
    AudapterIO('reset');   % Reset;
    pause(0.01)
    Audapter('start')
    Audapter('stop')
    
    %% TRIAL TIMER
    % at this point, the crosshair is already displayed
    
    % removing timer function because it's useless!!!!
    
    if isempty(CLOCK)
        CLOCK = ManageTime('start');  % resets clock to t=0 (first-trial start-time)
        TIME_TRIAL_START = 0;
    else  % note: THIS IS TIME LANDMARK #1: BEGINNING OF STIMULUS PRESENTATION: at this point the code will typically wait for ~2s, between the beginning of the previous scan and the beginning of the next trial presentation
        ok=ManageTime('wait', CLOCK, TIME_TRIAL_START);     % determine if it is time for this trial to begin; if not, then wait for next-trial start-time
        if ~ok, fprintf('warning: i am late for this trial stimulus presentation time\n'); end
    end
    
    if audioStim
        
        % Present stimulus audio and visual
        set(annoStr.Stim,'Visible','On');
        sound(soundY,Fs,16);
        pause(1.5)
        set(annoStr.Stim,'Visible','Off');
        pause(1)
        
        % Give go signal and begin audapter, remove go signal and end
        % audapter
        TIME_TRIAL_ACTUALLYSTART=ManageTime('current', CLOCK); % audio signal t=0
        sound(beep1,Fs1,16); 
        Audapter('start');
        set(annoStr.Go, 'Visible', 'On');
        pause(expParams.stimOn) 
        set(annoStr.Go, 'Visible', 'Off'); sound(beep2,Fs1,16); set(annoStr.Stop,'Visible', 'On');
        pause(expParams.recordLen - expParams.stimOn);
        Audapter('stop');
        set(annoStr.Stop,'Visible','Off');
        
        TIME_PERT_ACTUALLYEND=ManageTime('current', CLOCK);
        pause(0.01) % needed so doesn't lag
    else
        
        Audapter('start');
        set(annoStr.Stim, 'Visible', 'On');
        TIME_TRIAL_ACTUALLYSTART=ManageTime('current', CLOCK); % audio signal t=0
        pause(expParams.stimOn)
        set(annoStr.Stim, 'Visible', 'Off');
        pause(expParams.recordLen - expParams.stimOn);
        Audapter('stop');
        
        TIME_PERT_ACTUALLYEND=ManageTime('current', CLOCK);
        pause(0.01) % needed so doesn't lag
    end
    
    trialData(ii).audapData = AudapterIO('getData');
    
    %% determine voice onset and perturbation onset times
    
    % Find rmsOnsetIdx - determine if voicing occurred
    minThreshTimeFrames = (expParams.minThreshTime*p.sr)/p.frameLen; % convert minThreshTime to # frames in audapData
    rmsidx = find(diff([0; trialData(ii).audapData.rms(:,1) > p.rmsThresh; 0])); % finds voice onset and offset
    % This should be checking when you go above a minimumm threshold
    rmsOnsetIdx = rmsidx(-1+2*find(rmsidx(2:2:end)-rmsidx(1:2:end-1) >= minThreshTimeFrames,1));
    % when it goes above the threshold, does it stay there for a long
    % enough time?

    % Determine voice onset
    if isempty(rmsOnsetIdx) %if no index was found greater than the voicing threshold
        timetovoice = nonSpeechDelay;
        trialData(ii).onsetDetected = 0;
    else % if voicing was detected
        timetovoice = ((rmsOnsetIdx(1))*p.frameLen)/p.sr; %first time crosses rms threshold; note: this is accurate +- 1 frameLen; note: timetovoice marks the beginning of minThreshTime window
        trialData(ii).onsetDetected = 1;
        nonSpeechDelay = .5*nonSpeechDelay + .5*timetovoice;
    end
    trialData(ii).nonSpeechDelay = NaN;
    trialData(ii).rmsVoiceOnset = timetovoice;

    % Create values for timingTrial field of trialData structure
    TIME_VOICE_START = TIME_TRIAL_ACTUALLYSTART + timetovoice;
    TIME_PERT_START = TIME_VOICE_START + trialData(ii).pertJitter;
    trialData(ii).reference_time = trialData(ii).rmsVoiceOnset + trialData(ii).pertJitter;
    
    % This factor is for converting between the frame length of the
    % recorded signal and its length in seconds
    sampleFactor = trialData(ii).audapData.params.frameLen/trialData(ii).audapData.params.sr;
    
    % Determine perturbation onset
    % If this is a formant trial OR it's a pitch trial that uses phase
    % vocoder,
    if ismember(ii,formantTrials) || strcmp(expParams.pitchMethod,'phase-vocoder')
        
        % search for when the OST file's rule #3 is initiated. 
        % Note: this line assumes that rule 3 is where the perturbation is
        % begun. If using an OST file where rule 3 does not begin the ramp,
        % then this must be changed.
        TIME_PERT_ACTUALLYSTART = TIME_TRIAL_ACTUALLYSTART...
            + (min([nan;find(trialData(ii).audapData.ost_stat(:,1) == 4,1)])...
            * sampleFactor);
        trialData(ii).reference_time = TIME_PERT_ACTUALLYSTART - TIME_TRIAL_ACTUALLYSTART;
         
    elseif ismember(ii,pitchTrials) && strcmp(expParams.pitchMethod,'time-domain')
        
        % Find which time window is voiced
        voiced = timetovoice / sampleFactor;
        
        if ~strcmp(trialData(ii).condLabel,'N0')
            
            % Find the difference between the shifted and unshifted pitch at
            % each frame
            pitchDiff = (trialData(ii).audapData.shiftedPitchHz(voiced:end) - trialData(ii).audapData.pitchHz(voiced:end))...
                ./ trialData(ii).audapData.pitchHz(voiced:end);
            
            % Find where the pitch difference is
            if ismember(ii,pitchUp) || ismember(ii,pitchUpSudden) || ismember(ii,pitchUpGradual)
                rightPitchDiff = (pitchDiff+1)>=(shift-.015) & (pitchDiff+1)<=(shift+.0178);
            elseif ismember(ii,pitchDown) || ismember(ii,pitchDownSudden) || ismember(ii,pitchDownGradual)
                rightPitchDiff = (pitchDiff+1)>=(shift-.0168) & (pitchDiff+1)<=(shift+.015);
            end
            rightPitchDiffIdx = find(rightPitchDiff);
            
            % check to see where pitch diff is majority consistent for
            % next 5 frames
            for i = 1:numel(rightPitchDiffIdx)
                if rightPitchDiffIdx(i)+19 <= numel(rightPitchDiff)
                    consistent(i) = mode(rightPitchDiff(rightPitchDiffIdx(i):rightPitchDiffIdx(i)+19))==1;
                end
            end
            
            % If it's the right pitch difference, and it's more or less
            % consistent for 20 frames, then it's the perturbation onset
            onsetIdx = rightPitchDiffIdx(find(consistent,1,'first')) + voiced;
            
            % Use idx to label reference time
            trialData(ii).reference_time = ((onsetIdx) * sampleFactor) - rampTime;
            
            % If no onset was found, just try using pertJitter
            if ~isempty(trialData(ii).reference_time)
                TIME_PERT_ACTUALLYSTART = TIME_TRIAL_ACTUALLYSTART + trialData(ii).reference_time;
            elseif isempty(trialData(ii).reference_time)
                trialData(ii).reference_time = trialData(ii).rmsVoiceOnset + trialData(ii).pertJitter;
                TIME_PERT_ACTUALLYSTART = TIME_TRIAL_ACTUALLYSTART + trialData(ii).reference_time;
            end
            
        elseif strcmp(trialData(ii).condLabel,'N0') 
            TIME_PERT_ACTUALLYSTART = TIME_PERT_START;
            trialData(ii).reference_time = TIME_PERT_START - TIME_TRIAL_ACTUALLYSTART;
        end
    end
    
    TIME_PERT_END = TIME_TRIAL_ACTUALLYSTART + numel(trialData(ii).audapData.signalIn)/p.sr;  % or TIME_TRIAL_ACTUALLYSTART + expParams.recordLen?
    
    TIME_SCAN_START = NaN;
    TIME_SCAN_ACTUALLYSTART=NaN;
    TIME_SCAN_END = NaN;
    
    % plot trial data
    pTitle = sprintf('Run %d  Trial %d  Condition: %s', expParams.runNum, ii, trialData(ii).condLabel);
     set(sigplotTitle,'String',pTitle);
    plotMicSignal(p, trialData, ii, h1, h2, h3, expParams.pitchMethod);
    
    % trial timing
    trialData(ii).timingTrial = [TIME_TRIAL_START; TIME_TRIAL_ACTUALLYSTART; TIME_VOICE_START; TIME_PERT_START; TIME_PERT_ACTUALLYSTART; TIME_PERT_END; TIME_PERT_ACTUALLYEND; TIME_SCAN_START; TIME_SCAN_ACTUALLYSTART; TIME_SCAN_END]; % note: we also prefer to record absolute times for analyses of BOLD signal
    
    TIME_TRIAL_START = TIME_TRIAL_START + expParams.iti; % when should next trial start THIS SHOULD BE DIFFERENT FOR AUDIO AND VISUAL STIMULUS PRESENTATION METHODS
    
    %% save for each trial (in case of computer/matlab failure)
    trialData(ii).p = p;
    
    %JT save time updates 8/10/21: save only data from current trial
    tData = trialData(ii); %.002s
    fName_trial = fullfile(dirs.run,sprintf('sub-%s_ses-%d_%s_task-%s_trial-%s', ...
        expParams.subjectID, expParams.session, runName, expParams.task, num2str(ii)));
    save([fName_trial '.mat'], 'tData');
    
    %% adaptive voice thresholding - update voice threshold based on RMS of previous trials
    
    % running-average of rmsThresh values, with alpha-parameter = 0.9
    % (p.rmsThresh = alpha*p.rmsThresh + (1-alph)*new_rmsThresh; alpha between
    % 0 and 1; alpha high -> slow update; alpha low -> fast update)
    
    % If you chose your threshold manually (threshType == 2) when running
    % runVoiceCal.m, the script will not use adaptive thresholding
    
    if isfield(expParams,'voiceCal')&&expParams.voiceCal.threshType == 1  %If using automatic/adaptive thresholding
        if ~isempty(rmsOnsetIdx)    % voice onset detected
            minRms = prctile(trialData(ii).audapData.rms(:,1),10);
            maxRms = prctile(trialData(ii).audapData.rms(rmsOnsetIdx:end,1),90);
        else
            minRms = 0;
            maxRms = prctile(trialData(ii).audapData.rms(:,1),90);
        end
        tmpRmsThresh = minRms + (maxRms-minRms)/10;
        p.rmsThresh = .9*p.rmsThresh + .1*tmpRmsThresh;
    end
    
    %% adaptive pitch bounds - update upper and lower pitch bounds to account for vocal drift
    
    if ismember(ii, pitchTrials)
        switch expParams.pitchMethod
            case 'time-domain'
                if ~isempty(rmsOnsetIdx)
                    tmpf0 = trialData(ii).audapData.pitchHz(rmsOnsetIdx:end);
                    tmpf0 = median(tmpf0(tmpf0>0)); %get average f0 removing 0's and nan's
                else
                    tmpf0 = trialData(ii).audapData.pitchHz;
                    tmpf0 = median(tmpf0(tmpf0>0)); %get average f0 removing 0's and nan's
                end
                if ~isnan(tmpf0) %only update f0 if trial is voiced
                    f0 = .9*f0 + .1*tmpf0; %update f0 estimate from voiced trial
                    p.pitchLowerBoundHz = f0 - 40;
                    p.pitchUpperBoundHz = f0 + 40;
                end
        end
    end
      
end
save([fName '.mat'], 'expParams', 'trialData');

%% end of experiment

close all

% experiment time
expParams.elapsed_time = toc(ET)/60;
fprintf('\nElapsed Time: %f (min)\n', expParams.elapsed_time)

% number of trials with voice onset detected
onsetCount = nan(expParams.numTrials,1);
for j = 1: expParams.numTrials
    onsetCount(j) = trialData(j).onsetDetected;
end
numOnsetDetected = sum(onsetCount);
fprintf('Voice onset detected on %d/%d trials\n', numOnsetDetected, expParams.numTrials);

end

% sub-functions

function [trialData, annoStr] = setUpTrial(expParams, annoStr, stimName, condition, trialData, ii)

% print progress to window
fprintf('\nRun %d, trial %d/%d\n', expParams.runNum, ii, expParams.numTrials);

% turn on fixation 'Cross'
set(annoStr.Plus, 'Visible','on');

% pull out the correct stim/condition from the list & save to trialData
annoStr.Stim.String = stimName{ii};
trialData(ii).stimName = stimName{ii};
trialData(ii).condLabel = condition{ii};

% set up perturbation onset jitter
% This value actually doesn't just represent the jitter but represents the
% time between voice onset and pert onset it all trials, whether it's a
% static or jittered perturbation
switch expParams.task
    case 'aud-reflexive'
        if strcmp(trialData(ii).condLabel, 'U1') || strcmp(trialData(ii).condLabel, 'D1') || strcmp(trialData(ii).condLabel, 'N1')
            if strcmp(expParams.formantType, 'Voice-Onset')
                trialData(ii).pertJitter = .04; % pert must come on at after the minThreshTime at the earliest
            elseif strcmp(expParams.formantType,'Mid-Voice')
                trialData(ii).pertJitter = .4;  % Assumes mid-voice pert onset is set to .4 in the pcf file
            elseif strcmp(expParams.formantType,'Jittered')
                trialData(ii).pertJitter = expParams.pertJitterMin + (expParams.pertJitterMax-expParams.pertJitterMin).*rand(1,1); %find a random number between pertJitterMin and pertJitterMax
            end
        else
            if strcmp(expParams.pitchType, 'Voice-Onset')
                trialData(ii).pertJitter = 0.04;
            elseif strcmp(expParams.pitchType,'Mid-Voice')
                trialData(ii).pertJitter = .4; % Assumes mid-voice pert onset is set to .4 in the pcf file
            elseif strcmp(expParams.pitchType,'Jittered')
                trialData(ii).pertJitter = expParams.pertJitterMin + (expParams.pertJitterMax-expParams.pertJitterMin).*rand(1,1); %find a random number between pertJitterMin and pertJitterMax
            end
        end
    case 'aud-adaptive'
        trialData(ii).pertJitter = 0;
end

end
