% Delayed Auditory Feedback (DAF) Experiment
% Requires Audio Toolbox and Psychtoolbox

clear; % Clear all variables from workspace
clc;   % Clear command window
AssertOpenGL; % Ensure Psychtoolbox is available

%% Prompt for saving
%saveData = input('Would you like to save session data and metadata? (y/n): ', 's');
saveData='y'; % set for autosave
doSave = strcmpi(saveData, 'y'); % Logical flag for saving

%% Parameter settings
Nblocks = 4; % Number of blocks
pause_between_blocks = true; % Set to true to require keypress between blocks
Fs = 44100; % Audio sample rate in Hz
frameSize = 128; % Number of samples processed per audio frame
audioGain = 2.0; % Output gain for delayed signal
fixDur = 1.0; % Duration of fixation cue (seconds)
prepPause = 0.5; % Pause between fixation and sentence onset (seconds)
sentDur = 5.0; % Duration for which sentence is displayed and spoken (seconds)
ITI = 2.0; % Inter-trial interval (seconds)
delayOptions = [0, 150, 200, 250]; % DAF delay conditions in ms
catchRatio = 1/6; % Fraction of catch (no-speak) trials

%% Manual path setup (for unrecognized host)
beep off
host = getenv('COMPUTERNAME');
warning('Unrecognized host: %s. Setting manual project directory.', host);
dirs.projrepo = 'C:\Users\samkh\OneDrive\Documents\MATLAB\ieeg_stut';
dirs.data     = dirs.projrepo;
dirs.spm      = fullfile(dirs.projrepo, 'spm12');
dirs.conn     = fullfile(dirs.projrepo, 'conn');
dirs.FLvoice  = fullfile(dirs.projrepo, 'FLvoice');
dirs.stim     = fullfile(dirs.projrepo, 'stimuli');
dirs.config   = fullfile(dirs.projrepo, 'config'); 
dirs.derivatives = fullfile(dirs.data, 'der');

paths_to_add = {dirs.projrepo; dirs.derivatives; dirs.spm; ...
    [dirs.projrepo filesep 'util']; ...
    [dirs.projrepo filesep 'analysis']; ...
    [dirs.projrepo filesep 'experiment_scripts']};
addpath(paths_to_add{:});

%% Subject/session/task input + BIDS folder setup
if doSave % Only prompt if saving is enabled
    subject = input('Enter subject ID (e.g., pilot01): ', 's');
    session = input('Enter session ID (e.g., 1): ', 's');
    task = input('Enter task label (e.g., daf): ', 's');
    dirs.sub = fullfile(dirs.data, 'sourcedata', ['sub-' subject]);
    dirs.ses = fullfile(dirs.sub, ['ses-' session]);
    runNum = 1; % Start with run-01
    while true % Find next available run folder
        runLabel = sprintf('run-%02d', runNum);
        dirs.run = fullfile(dirs.ses, runLabel);
        if ~exist(dirs.run, 'dir') % If folder doesn't exist, use it
            mkdir(dirs.run);
            break;
        end
        runNum = runNum + 1; % Otherwise increment run number
    end
    baseName = sprintf('sub-%s_ses-%s_run-%02d_task-%s', subject, session, runNum, task);
    logFileName = fullfile(dirs.run, [baseName '_trials-words.tsv']);
    metaFileName = fullfile(dirs.run, [baseName '_desc-meta.mat']);
end

%% Load sentences and block randomization (with preallocation)
T = readtable('sentences.tsv', 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',false);
sentences = T.Var1; % Extract sentences as cell array
nSentences = numel(sentences); % Number of sentences

% For one block: all (sentence x delay) pairs
[sentenceIdxGrid, delayIdxGrid] = ndgrid(1:nSentences, 1:numel(delayOptions));
blockSentIdx = sentenceIdxGrid(:); % [nSentences*numel(delayOptions) x 1]
blockDelays = delayOptions(delayIdxGrid(:)); % [nSentences*numel(delayOptions) x 1]
blockNtrials = numel(blockSentIdx); % Number of trials per block
nTrials = Nblocks * blockNtrials; % Total number of trials

% Preallocate arrays for all trials
trialSentIdx = zeros(nTrials, 1); % Sentence indices for all trials
trialDelays = zeros(nTrials, 1); % Delay values for all trials
trialBlock = zeros(nTrials, 1); % Block number for all trials
trialCounter = 1; % Index for filling arrays
for b = 1:Nblocks
    blockOrder = randperm(blockNtrials); % Unique shuffle for this block
    trialRange = trialCounter:(trialCounter + blockNtrials - 1);
    trialSentIdx(trialRange) = blockSentIdx(blockOrder);
    trialDelays(trialRange)  = blockDelays(blockOrder);
    trialBlock(trialRange)   = b;
    trialCounter = trialCounter + blockNtrials;
end

% Assign catch trials randomly across all trials
nCatch = round(nTrials * catchRatio);
isCatch = false(nTrials, 1);
if nCatch > 0
    isCatch(randperm(nTrials, nCatch)) = true;
end

%% Audio setup
devices = getAudioDevices(audioDeviceReader); % List available audio devices
for k = 1:length(devices)
    fprintf('%d: %s\n', k, devices{k});
end
inIdx = input('INPUT device #: '); % User selects input device
outIdx = input('OUTPUT device #: '); % User selects output device
reader = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize, 'Device', devices{inIdx}); % Live mic input
writer = audioDeviceWriter('SampleRate', Fs, 'Device', devices{outIdx}); % Speaker output
vfd = dsp.VariableFractionalDelay('MaximumDelay', round(Fs * 0.5)); % Delay buffer for DAF
for k = 1:10, writer(reader()); end % Prime audio pipeline (avoid startup glitch)
maxDelay_ms = max(delayOptions); % Find largest delay (ms)
maxDelayFrames = ceil((maxDelay_ms/1000) * Fs / frameSize) + 5; % Max delay in frames, add buffer

%% GUI setup
screenSize = get(0, 'ScreenSize'); % Get screen size for centering
fig = figure('Name','DAF','Color','white','MenuBar','none','ToolBar','none','Position',[screenSize(3)/4 screenSize(4)/4 900 600],'NumberTitle','off'); % Main experiment window
ax = axes('Parent',fig,'Position',[0 0 1 1],'Visible','off'); % Invisible axes for center-center text
hText = text(0.5, 0.5, '', ...
    'FontSize', 28, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Units','normalized', ...
    'Parent', ax); % Centered text object for all instructions/cues
stopFig = figure('Name','Stop','NumberTitle','off','MenuBar','none','ToolBar','none','Position',[300 100 200 80]); % Stop window
setappdata(0, 'stopReq', false); % Shared flag for stopping experiment
uicontrol(stopFig,'Style','pushbutton','String','Stop','FontSize',14,'Position',[50 20 100 40],'Callback', @(~,~) setappdata(0,'stopReq',true)); % Stop button sets flag

%% Instructions and sync beeps
instructions = [
    'INSTRUCTIONS\n\n' ...
    'You will see a series of sentences.\n\n' ...
    '* When you see a GRAY asterisk (*), read the sentence aloud.\n' ...
    '* When you see a RED asterisk (*), do NOT speak.\n\n' ...
    'Try to speak clearly and at a natural pace.\n\n' ...
    'Press any key to begin...'
];
set(hText, 'String', sprintf(instructions), ...
    'FontSize', 22, ...
    'Color', 'black'); % Show instructions
figure(fig); % Bring main window to front
set(fig, 'WindowKeyPressFcn', @(~,~) uiresume(fig)); % Resume on any key
uiwait(fig); % Wait for user keypress
set(fig, 'WindowKeyPressFcn', ''); % Remove keypress handler
set(hText, 'String', ''); drawnow; % Clear text
beepWave = 0.1 * sin(2*pi*1000*(0:1/Fs:0.2)); % 200ms, 1kHz beep
set(hText, 'String', 'SYNC', 'FontSize', 48, 'Color', 'red'); drawnow; % Show sync message
syncTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'); % Log sync time (for aligning with other systems)
for i = 1:3
    if i == 1
        refTime = GetSecs; % Start experiment timer at first beep
    end
    sound(beepWave, Fs);
    pause(0.5);
end
set(hText, 'String', ''); drawnow; % Clear after last beep

%% Log file
if doSave
    logFile = fopen(logFileName, 'w'); % Open trial log
    fprintf(logFile, 'SYNC_TIME\t%s\n', char(syncTime)); % Write sync time
    fprintf(logFile, 'block\tfixation_onset\tsentence_onset\tsentence_offset\ttrial_type\tsentence\tdelay_ms\n'); % Updated header
else
    logFile = [];
end

%% Trial loop
lagBuffer = zeros(1, 5000); lagIndex = 1; lagCount = 0; completedTrials = 0; % Buffers for audio latency diagnostics
for t = 1:nTrials
    if getappdata(0, 'stopReq'), break; % Stop if pressed
    end
    sIdx = trialSentIdx(t); delay_ms = trialDelays(t); delay_samples = Fs * delay_ms / 1000; % Trial parameters
    sentence = sentences{sIdx}; isSpeak = ~isCatch(t); % Sentence text, trial type
    for i = 1:maxDelayFrames
        writer(zeros(frameSize,1)); % Flush output buffer
        vfd(zeros(frameSize,1), delay_samples); % Flush delay buffer
    end
    vfd.reset(); % Reset delay state
    set(hText, 'String', '*', 'FontSize', 48, 'Color', ifelse(isSpeak, [0.7 0.7 0.7], 'red')); % Show asterisk cue
    drawnow;
    fixOn = GetSecs - refTime; % Log fixation onset
    fixStart = GetSecs;
    while (GetSecs - fixStart) < fixDur; end % Hold for fixation duration
    set(hText, 'String', '');
    drawnow; % Clear
    WaitSecs(prepPause); % Pre-sentence pause
    set(hText, 'String', sentence, 'FontSize', 32, 'Color', 'black'); drawnow; % Show sentence
    visOn = GetSecs - refTime; % Log sentence onset
    if isSpeak && delay_ms > 0 % Only do DAF if not catch and delay > 0
        DAFstart = GetSecs;
        frameCounter = 0;
        while (GetSecs - DAFstart) < sentDur && ~getappdata(0,'stopReq') % While within trial duration and not stopped
            tStart = GetSecs; % Start timing for this frame
            audioIn = reader(); delayed = vfd(audioIn, delay_samples); % Get input, apply delay
            audioOut = max(min(audioGain * delayed, 1), -1); % Apply gain, clip to [-1,1]
            writer(audioOut); % Output delayed audio
            lag = max((GetSecs - tStart)*1000 - (frameSize/Fs*1000), 0); % Compute audio processing lag in ms
            lagBuffer(lagIndex) = lag; % Store lag
            lagIndex = mod(lagIndex, 5000) + 1; % Circular buffer
            lagCount = min(lagCount+1, 5000);
            frameCounter = frameCounter + 1;
            if mod(frameCounter, 10) == 0
                drawnow; % Update GUI every 10 frames
            end
            pause(0.001); % Prevent CPU slowing
        end
        for i = 1:maxDelayFrames
            audioOut = vfd(zeros(frameSize,1), delay_samples); % Flush remaining delayed audio
            writer(audioOut);
        end
        vfd.reset();
        WaitSecs(0.1); % Short pause to finish playback
    else
        sentStart = GetSecs;
        while (GetSecs - sentStart) < sentDur; end % Wait for sentence duration if not DAF
    end
    visOff = GetSecs - refTime; % Log sentence offset
    set(hText, 'String', '');
    drawnow; % Clear
    ITIstart = GetSecs;
    while (GetSecs - ITIstart) < ITI; end % Inter-trial interval

    % Console log
    fprintf('Block: %d | Delay: %3d ms | %s | Sentence: %s | Visual On: %.3f s\n', ...
        trialBlock(t), delay_ms, ifelse(isSpeak,'Speaking','Catch'), sentence, visOn);

    % Log file output (block, timings, type, sentence, delay)
    if doSave && ~isempty(logFile)
        fprintf(logFile, '%d\t%.3f\t%.3f\t%.3f\t%s\t%s\t%d\n', ...
            trialBlock(t), fixOn, visOn, visOff, ifelse(isSpeak,'speech','catch'), sentence, delay_ms);
    end

    %  Pause between blocks: if this is the last trial of the current block (but not the last trial overall), pause and wait for spacebar
    if pause_between_blocks && t < nTrials && (t == find(trialBlock == trialBlock(t), 1, 'last'))
        set(hText, 'String', sprintf('Block %d/%d finished.\nPress spacebar to continue.', ...
            trialBlock(t), max(trialBlock)), 'FontSize', 28, 'Color', 'blue');
        drawnow;
        fprintf('Block %d/%d finished; press spacebar to continue...\n', trialBlock(t), max(trialBlock));
        set(fig, 'WindowKeyPressFcn', @(src,evt) spacebarToContinue(src,evt,fig)); % Use nested function below
        uiwait(fig); % Wait for spacebar
        set(fig, 'WindowKeyPressFcn', '');
        set(hText, 'String', '');
        drawnow;
    end
    completedTrials = completedTrials + 1; % Increment trial count
end

%% Cleanup and save metadata
release(reader); % Release hardware, close windows
release(writer);
release(vfd);
close(fig);
close(stopFig);
rmappdata(0,'stopReq');
if doSave && ~isempty(logFile), fclose(logFile); end % Close log file
if lagCount > 0, fprintf('\nAvg lag: %.2f ms\n', mean(lagBuffer(1:lagCount))); end % Print average audio lag
if doSave
    ts = trialSentIdx(1:completedTrials); % Final trial order
    td = trialDelays(1:completedTrials); % Final delays
    ic = isCatch(1:completedTrials); % Final catch mask
    tb = trialBlock(1:completedTrials); % Final block numbers
    runMeta = struct('subject', subject, 'session', session, 'run', runNum, 'task', task, 'created_on', datestr(now), ...
        'catchRatio', catchRatio, 'delayOptions', delayOptions, 'sentDur', sentDur, 'fixDur', fixDur, 'ITI', ITI, ...
        'prepPause', prepPause, 'audioGain', audioGain, 'frameSize', frameSize, 'samplingRate', Fs, 'totalTrials', completedTrials, ...
        'nCatchTrials', sum(ic(:)), 'trialOrder', table(tb(:), ts(:), td(:), ic(:), 'VariableNames', {'trialBlock','trialSentIdx','trialDelays','isCatch'})); % Save all metadata for reproducibility
    save(metaFileName, 'runMeta'); % Save metadata
    fprintf('Metadata saved to: %s\n', metaFileName); % Confirm
else
    fprintf('Session was not saved.\n'); % Confirm
end

%% Nested function for spacebar detection
function spacebarToContinue(~, evt, figHandle) % Only resume if the pressed key is the spacebar
    if strcmp(evt.Key, 'space')
        uiresume(figHandle);
    end
end

%% Helper function (Ternary operator: returns a if cond is true, else b)
function out = ifelse(cond, a, b)
    if cond, out = a;
    else, out = b;
    end
end