% Delayed Auditory Feedback (DAF) Experiment - BIDS-Compliant Version
% Requires Audio Toolbox and set_paths_ieeg_stut()

clear;
clc;

%% ===== Set paths using utility function =====
% ===== Inline set_paths_ieeg_stut() functionality =====
beep off
project = 'ieeg_stut';
pilotstring = [project filesep 'data' filesep 'pilot'];

if ispc
    [~,host] = system('hostname');
    host = deblank(host);
    system(sprintf('wmic process where processid=%d call setpriority "high priority"',feature('getpid')));
elseif ismac
    [~,host] = system('scutil --get LocalHostName');
    host = deblank(host);
elseif isunix
    [~,host] = system('hostname -s');
    host = deblank(host);
end

if strncmpi('scc-x02', host, 3)
    dirs.projrepo = '/project/busplab/software/ieeg_stut';
    dirs.data = ['/projectnb/busplab/Experiments/', project];
    dirs.pilot = fullfile('/projectnb/busplab/Experiments/', pilotstring);
    dirs.conn = '/project/busplab/software/conn'; 
    dirs.spm = '/project/busplab/software/spm12'; 
    dirs.FLvoice = '/project/busplab/software/FLvoice'; 
else
    switch host
        case {'MSI','677-GUE-WL-0010', 'amsmeier'}
            pkgdir = 'C:\docs\code';
            dirs.projrepo = [pkgdir filesep 'ieeg_stut']; 
            dirs.spm = [pkgdir filesep 'spm12'];
            dirs.conn = [pkgdir filesep 'conn'];
            dirs.FLvoice  = [pkgdir filesep 'FLvoice'];
            dirs.data = 'C:\ieeg_stut'; 
        otherwise
    disp('Directory listings are not set up for this computer. Please check that your hostname is correct.');
    return
    end
end

dirs.stim = [dirs.projrepo, filesep, 'stimuli'];
dirs.config = fullfile(dirs.projrepo, 'config');
dirs.derivatives = [dirs.data, filesep, 'der'];

paths_to_add = {dirs.projrepo;...
                dirs.derivatives;...
                dirs.spm;...
                [dirs.projrepo filesep 'util'];...
                [dirs.projrepo filesep 'analysis'];...
                [dirs.projrepo filesep 'experiment_scripts'];...
                };
addpath(paths_to_add{:});
[dirs, host] = deal(dirs, host);


%% Parameters
Fs = 44100;
frameSize = 128;
fixDur = 1.0;
prepPause = 0.5;
sentDur = 5.0;
ITI = 2.0;
delayOptions = [0, 150, 200, 250];
catchRatio = 1/6;
audioGain = 2.0;

%% Load Sentences
T = readtable('sentences.tsv', 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',false);
sentences = T.Var1;
nSentences = numel(sentences);
[sentenceIdxGrid, delayIdxGrid] = ndgrid(1:nSentences, 1:numel(delayOptions));
trialSentIdx = sentenceIdxGrid(:);
trialDelays = delayOptions(delayIdxGrid(:));
nTrials = numel(trialSentIdx);
randOrder = randperm(nTrials);
trialSentIdx = trialSentIdx(randOrder);
trialDelays = trialDelays(randOrder);

nCatch = round(nTrials * catchRatio);
isCatch = false(nTrials, 1);
if nCatch > 0
    isCatch(randperm(nTrials, nCatch)) = true;
end

%% Audio setup
devices = getAudioDevices(audioDeviceReader);
for k = 1:length(devices)
    fprintf('%d: %s\n', k, devices{k});
end
inIdx = input('INPUT device #: ');
outIdx = input('OUTPUT device #: ');
reader = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize, 'Device', devices{inIdx});
writer = audioDeviceWriter('SampleRate', Fs, 'Device', devices{outIdx});
vfd = dsp.VariableFractionalDelay('MaximumDelay', round(Fs * 0.5));

%% Warm up audio stream
for k = 1:10, writer(reader()); end

%% GUI setup
screenSize = get(0, 'ScreenSize');
fig = figure('Name','DAF','Color','white','MenuBar','none','ToolBar','none','Position',[screenSize(3)/4 screenSize(4)/4 900 600],'NumberTitle','off');
hText = uicontrol('Style','text','FontSize',16,'Units','normalized','Position',[0.05 0.05 0.9 0.9],'HorizontalAlignment','center','BackgroundColor','white');
stopFig = figure('Name','Stop','NumberTitle','off','MenuBar','none','ToolBar','none','Position',[300 100 200 80]);
setappdata(0, 'stopReq', false);
uicontrol(stopFig,'Style','pushbutton','String','Stop','FontSize',14,'Position',[50 20 100 40],'Callback', @(~,~) setappdata(0,'stopReq',true));

%% Instructions
set(hText, 'String', sprintf('INSTRUCTIONS:\n\nYou will see a series of sentences.\n* GRAY asterisk = speak when it appears\n* RED asterisk = do NOT speak (catch trial)\n\nSentences last ~5 seconds.\nPress any key to begin...'), 'FontSize', 16); drawnow;
waitforbuttonpress; set(hText, 'String', '', 'FontSize', 20); drawnow;

%% Sync and beep
beepWave = 0.1 * sin(2*pi*1000*(0:1/Fs:0.2));
set(hText, 'String', 'SYNC', 'FontSize', 48, 'ForegroundColor', 'red'); drawnow;
syncTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
refTime = tic;
for i = 1:3, sound(beepWave, Fs); pause(0.5); end
set(hText, 'String', '', 'FontSize', 20); drawnow;

%% Log file
logFile = fopen(logFileName, 'w');
fprintf(logFile, 'SYNC_TIME\t%s\n', char(syncTime));
fprintf(logFile, 'fixation_onset\tsentence_onset\tsentence_offset\ttrial_type\tsentence\tdelay_ms\tis_catch\n');

%% Trial loop
lagBuffer = zeros(1, 5000); lagIndex = 1; lagCount = 0; completedTrials = 0;
for t = 1:nTrials
    if getappdata(0, 'stopReq'), break; end
    sIdx = trialSentIdx(t); delay_ms = trialDelays(t); delay_samples = Fs * delay_ms / 1000;
    sentence = sentences{sIdx}; isSpeak = ~isCatch(t);

    set(hText, 'String', '*', 'FontSize', 48, 'ForegroundColor', ifelse(isSpeak, [0.7 0.7 0.7], 'red')); drawnow;
    fixOn = toc(refTime); pause(fixDur); set(hText, 'String', ''); drawnow; pause(prepPause);

    set(hText, 'String', sentence, 'FontSize', 20); drawnow;
    visOn = toc(refTime);
    for k = 1:10, writer(zeros(frameSize,1)); end

    if isSpeak && delay_ms > 0
        timerDAF = tic;
        while toc(timerDAF) < sentDur && ~getappdata(0,'stopReq')
            tStart = tic; audioIn = reader(); delayed = vfd(audioIn, delay_samples); audioOut = max(min(audioGain * delayed, 1), -1);
            writer(audioOut); lag = max(toc(tStart)*1000 - (frameSize/Fs*1000), 0);
            lagBuffer(lagIndex) = lag; lagIndex = mod(lagIndex, 5000) + 1; lagCount = min(lagCount+1, 5000); drawnow limitrate;
        end
        vfd.reset(); for i = 1:10, writer(zeros(frameSize,1)); end; pause(0.05);
    else
        pause(sentDur);
    end

    visOff = toc(refTime); set(hText, 'String', ''); drawnow; pause(ITI);
    fprintf('Delay: %3d ms | %s | Sentence: %s | Visual On: %.3f s\n', delay_ms, ifelse(isSpeak,'Speaking','Catch'), sentence, visOn);
    fprintf(logFile, '%.3f\t%.3f\t%.3f\t%s\t%s\t%d\t%d\n', fixOn, visOn, visOff, ifelse(isSpeak,'speech','catch'), sentence, delay_ms, ~isSpeak);
    completedTrials = completedTrials + 1;
end

%% Cleanup
release(reader); release(writer); release(vfd); close(fig); close(stopFig); rmappdata(0,'stopReq'); fclose(logFile);
if lagCount > 0, fprintf('\nAvg lag: %.2f ms\n', mean(lagBuffer(1:lagCount))); end

%% Save metadata
ts = trialSentIdx(1:completedTrials); td = trialDelays(1:completedTrials); ic = isCatch(1:completedTrials);
runMeta = struct('subject', subject, 'session', session, 'run', runNum, 'task', task, 'created_on', datestr(now), ...
    'catchRatio', catchRatio, 'delayOptions', delayOptions, 'sentDur', sentDur, 'fixDur', fixDur, 'ITI', ITI, ...
    'prepPause', prepPause, 'audioGain', audioGain, 'frameSize', frameSize, 'samplingRate', Fs, 'totalTrials', completedTrials, ...
    'nCatchTrials', sum(ic(:)), 'trialOrder', table(ts(:), td(:), ic(:), 'VariableNames', {'trialSentIdx','trialDelays','isCatch'}));
save(metaFileName, 'runMeta');

%% Helper
function out = ifelse(cond, a, b)
    if cond, out = a; else, out = b; end
end