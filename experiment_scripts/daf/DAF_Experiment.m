% Delayed Auditory Feedback (DAF) Experiment
% Requires Audio Toolbox and Psychtoolbox

clear; % Clear all variables from workspace
clc;   % Clear command window
close all % close all figure windows
AssertOpenGL; % Ensure Psychtoolbox is available

%% Prompt for saving
%saveData = input('Would you like to save session data and metadata? (y/n): ', 's');
saveData='y'; % set for autosave
doSave = strcmpi(saveData, 'y'); % Logical flag for saving

%% Parameter settings
op.n_blocks = 1; % Number of blocks
op.pause_between_blocks = 0; % Set to true to require keypress between blocks
op.audio_sample_rate = 44100; % Audio sample rate in Hz
op.audio_frame_size = 128; % Number of samples processed per audio frame
op.audio_playback_gain = 15; % Output gain for delayed signal... might want to run volume calibration for each subject
op.fix_cross_dur = 0.; % Duration of fixation cue (seconds)
op.delay_dur = 0.; % Pause between fixation and sentence onset (seconds)
op.text_stim_dur = 12.0; % Duration for which sentence is displayed and spoken (seconds)
op.iti = 2.0; % Inter-trial interval (seconds)
op.stim_font_size = 65; 
op.stim_max_char_per_line = 38; % wrap text at this length

delayOptions = [0, 100, 150, 200]; % DAF delay condoitions in ms
% delayOptions = [150]; % DAF delay conditions in ms (MAX IS 1000ms)
maxAllowedDelay_ms = 1000;
if any(delayOptions > maxAllowedDelay_ms)
    error('One or more delayOptions exceed the maximum allowed delay of %d ms.', maxAllowedDelay_ms);
end

catchRatio = 0; 
% catchRatio = 1/6; % Fraction of catch (no-speak) trials

%%
[dirs, host] = set_paths_ieeg_stut();

%% Subject/session/task input + BIDS folder setup
task = 'daf'; 
if doSave % Only prompt if saving is enabled
    subject = input('Enter subject ID (e.g., pilot01): ', 's');
    session = input('Enter session ID (e.g., 1): ', 's');
    dirs.sub = fullfile(dirs.data, ['sub-' subject]);
    dirs.ses = fullfile(dirs.sub, ['ses-' session]);
    runNum = 1; % Start with run-01
    while true % Find next available run folder
        runLabel = sprintf('run-%02d', runNum);
        dirs.run = fullfile(dirs.ses, 'beh', task, runLabel);
        if ~exist(dirs.run, 'dir') % If folder doesn't exist, use it
            mkdir(dirs.run);
            break;
        end
        runNum = runNum + 1; % Otherwise increment run number
    end
    baseName = sprintf('sub-%s_ses-%s_task-%s_run-%02d', subject, session, task, runNum);
    logFileName = fullfile(dirs.run, [baseName '_trials-words.tsv']);
    metaFileName = fullfile(dirs.run, [baseName '_desc-meta.mat']);
end

%% Load sentences and block randomization (with preallocation)
T = readtable([dirs.projrepo, filesep, 'stimuli', filesep, 'daf_sentences.tsv'],...
     'FileType','text', 'Delimiter','\t', 'ReadVariableNames',false);
sentences = T.Var1; % Extract sentences as cell array
nSentences = numel(sentences); % Number of sentences

% For one block: all (sentence x delay) pairs
[sentenceIdxGrid, delayIdxGrid] = ndgrid(1:nSentences, 1:numel(delayOptions));
blockSentIdx = sentenceIdxGrid(:); % [nSentences*numel(delayOptions) x 1]
blockDelays = delayOptions(delayIdxGrid(:)); % [nSentences*numel(delayOptions) x 1]
blockNtrials = numel(blockSentIdx); % Number of trials per block
nTrials = op.n_blocks * blockNtrials; % Total number of trials

% Preallocate arrays for all trials
trialSentIdx = zeros(nTrials, 1); % Sentence indices for all trials
trialDelays = zeros(nTrials, 1); % Delay values for all trials
trialBlock = zeros(nTrials, 1); % Block number for all trials
trialCounter = 1; % Index for filling arrays
for b = 1:op.n_blocks
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

input_devices = getAudioDevices(audioDeviceReader); % List available audio input devices
for k = 1:length(input_devices)
    fprintf('%d: %s\n', k, input_devices{k});
end
inIdx = input('INPUT device #: '); % User selects input device

% if using focisrite on BML intraop rig, specify the correct audio driver
if strcmp(host,'BML-ALIENWARE2') && contains(input_devices{3},'Focusrite')
    reader = audioDeviceReader('SampleRate', op.audio_sample_rate, ...
        'SamplesPerFrame', op.audio_frame_size, ...
        'Device', 'Focusrite USB ASIO',...
        'Driver','ASIO'); % Live mic input  
else
    reader = audioDeviceReader('SampleRate', op.audio_sample_rate,...
        'SamplesPerFrame', op.audio_frame_size,...
        'Device', input_devices{inIdx}); % Live mic input
end

output_devices = getAudioDevices(audioDeviceWriter); % List available audio output devices
for k = 1:length(output_devices)
    fprintf('%d: %s\n', k, output_devices{k});
end
outIdx = input('OUTPUT device #: '); % User selects output device

writer = audioDeviceWriter('SampleRate', op.audio_sample_rate, 'Device', output_devices{outIdx}); % Speaker output
vfd = dsp.VariableFractionalDelay('MaximumDelay', round(op.audio_sample_rate)); % Delay buffer for DAF
for k = 1:10, writer(reader()); end % Prime audio pipeline (avoid startup glitch)
maxDelay_ms = max(delayOptions); % Find largest delay (ms)
maxDelayFrames = ceil((maxDelay_ms/1000) * op.audio_sample_rate / op.audio_frame_size) + 5; % Max delay in frames, add buffer

%% GUI setup
screenSize = get(0, 'ScreenSize'); % Get screen size for centering
fig = figure('Name','DAF','Color','white','MenuBar','none','ToolBar','none','Position',[screenSize(3)/4 screenSize(4)/4 900 600],'NumberTitle','off'); % Main experiment window
ax = axes('Parent',fig,'Position',[0 0 1 1],'Visible','off'); % Invisible axes for center-center text
hText = text(0.5, 0.5, '', ...
    'FontSize', op.stim_font_size, ...
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
    'When text appears on the screen,\n'...
    'Read as quickly and accurately as possible.\n\n' ...
    'Press any key to begin...'
];
set(hText, 'String', sprintf(instructions), ...
    'FontSize', 55, ...
    'Color', 'black'); % Show instructions
figure(fig); % Bring main window to front
set(fig, 'WindowKeyPressFcn', @(~,~) uiresume(fig)); % Resume on any key
uiwait(fig); % Wait for user keypress
set(fig, 'WindowKeyPressFcn', ''); % Remove keypress handler
set(hText, 'String', ''); drawnow; % Clear text
beepWave = 0.1 * sin(2*pi*1000*(0:1/op.audio_sample_rate:0.2)); % 200ms, 1kHz beep
set(hText, 'String', 'SYNC', 'FontSize', 48, 'Color', 'red'); drawnow; % Show sync message
syncTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'); % Log sync time (for aligning with other systems)
for i = 1:3
    if i == 1
        refTime = GetSecs; % Start experiment timer at first beep
    end
    sound(beepWave, op.audio_sample_rate);
    pause(0.5);
end
set(hText, 'String', ''); drawnow; % Clear after last beep

%% Log file
if doSave
    logFile = fopen(logFileName, 'w'); % Open trial log
    fprintf(logFile, 'SYNC_TIME\t%s\n', char(syncTime)); % Write sync time
    fprintf(logFile, 'trialnum\tblock\tfixation_onset\tsentence_onset\tsentence_offset\ttrial_type\tsentence\tdelay_ms\n'); % Updated header
    save(metaFileName,'op'); % Save metadata
else
    logFile = [];
end

%% Trial loop
lagBuffer = zeros(1, 5000); lagIndex = 1; lagCount = 0; completedTrials = 0; % Buffers for audio latency diagnostics
for itrial = 1:nTrials
    if getappdata(0, 'stopReq'), break; % Stop if pressed
    end
  
    sIdx = trialSentIdx(itrial); delay_ms = trialDelays(itrial); delay_samples = op.audio_sample_rate * delay_ms / 1000; % Trial parameters
    text_stim = sentences{sIdx}; isSpeak = ~isCatch(itrial); % Sentence text, trial type
    text_stim_wrapped = textwrap({text_stim},op.stim_max_char_per_line); 
    
    for i = 1:maxDelayFrames
        writer(zeros(op.audio_frame_size,1)); % Flush output buffer
        vfd(zeros(op.audio_frame_size,1), delay_samples); % Flush delay buffer
    end
    vfd.reset(); % Reset delay state
    set(hText, 'String', '*', 'FontSize', op.stim_font_size, 'Color', ifelse(isSpeak, [0.7 0.7 0.7], 'red')); % Show asterisk cue
    drawnow;
    fixOn = GetSecs - refTime; % Log fixation onset
    fixStart = GetSecs;
    while (GetSecs - fixStart) < op.fix_cross_dur; end % Hold for fixation duration
    set(hText, 'String', '');
    drawnow; % Clear
    WaitSecs(op.delay_dur); % Pre-sentence pause
    set(hText, 'String', text_stim_wrapped, 'FontSize', op.stim_font_size, 'Color', 'black'); drawnow; % Show sentence
    visOn = GetSecs - refTime; % Log sentence onset
    
         % Commandline output
    fprintf('Trial %d/%d | Block: %d | Delay: %3d ms | %s | Sentence: %s | Visual On: %.3f s\n', ...
    itrial, nTrials, trialBlock(itrial), delay_ms, ifelse(isSpeak,'Speaking','Catch'), text_stim, visOn);
    
    if isSpeak && delay_ms > 0 % Only do DAF if not catch and delay > 0
        DAop.audio_sample_ratetart = GetSecs;
        frameCounter = 0;
        while (GetSecs - DAop.audio_sample_ratetart) < op.text_stim_dur && ~getappdata(0,'stopReq') % While within trial duration and not stopped
            tStart = GetSecs; % Start timing for this frame
            audioIn = reader(); 
            delayed = vfd(audioIn, delay_samples); % Get input, apply delay
            audioOut = max(min(op.audio_playback_gain * delayed, 1), -1); % Apply gain, clip to [-1,1]
            writer(audioOut); % Output delayed audio
            lag = max((GetSecs - tStart)*1000 - (op.audio_frame_size/op.audio_sample_rate*1000), 0); % Compute audio processing lag in ms
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
            audioOut = vfd(zeros(op.audio_frame_size,1), delay_samples); % Flush remaining delayed audio
            writer(audioOut);
        end
        vfd.reset();
        WaitSecs(0.1); % Short pause to finish playback
    else
        sentStart = GetSecs;
        while (GetSecs - sentStart) < op.text_stim_dur; end % Wait for sentence duration if not DAF
    end
    visOff = GetSecs - refTime; % Log sentence ofop.audio_sample_rateet
    set(hText, 'String', '');
    drawnow; % Clear
    op.itistart = GetSecs;
    while (GetSecs - op.itistart) < op.iti; end % Inter-trial interval

    % Log file output (block, timings, type, sentence, delay)
    if doSave && ~isempty(logFile)
        fprintf(logFile, '%d\t%d\t%.3f\t%.3f\t%.3f\t%s\t%s\t%d\n', itrial, trialBlock(itrial), fixOn, visOn, visOff, ifelse(isSpeak,'speech','catch'), text_stim, delay_ms);

    end

    %  Pause between blocks: if this is the last trial of the current block (but not the last trial overall), pause and wait for spacebar
    if op.pause_between_blocks && itrial < nTrials && (itrial == find(trialBlock == trialBlock(itrial), 1, 'last'))
        set(hText, 'String', sprintf('Block %d/%d finished.\nPress spacebar to continue.', ...
            trialBlock(itrial), max(trialBlock)), 'FontSize', 28, 'Color', 'blue');
        drawnow;
        fprintf('Block %d/%d finished; press spacebar to continue...\n', trialBlock(itrial), max(trialBlock));
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
    metadata = struct('subject', subject, 'session', session, 'run', runNum, 'task', task, 'created_on', datestr(now), ...
        'catchRatio', catchRatio, 'delayOptions', delayOptions, ...
        'totalTrials', completedTrials, ...
        'nCatchTrials', sum(ic(:)), 'trialOrder', table(tb(:), ts(:), td(:), ic(:), 'VariableNames', {'trialBlock','trialSentIdx','trialDelays','isCatch'})); % Save all metadata for reproducibility
    save(metaFileName, 'metadata', 'op'); % Save metadata
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