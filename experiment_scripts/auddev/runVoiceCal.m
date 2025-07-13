function runVoiceCal(project,subjectID, session)
% runVoiceCal(subjectID, session)
%
% Runs voice calibration step for the AudDev and seq_pert studies: calls audapter to record
% three trials ('bed') and estimates rmsThresh that will be used to detect voice
% onset. If using the time-domain pitch-shift algorithm, the script also
% calculates participant fundamental frequency, and determines which
% pitch perturbation algorithm to use (via another function
% VoiceCalibrationAlgorithm)
%
% INPUTS                    subjectID (e.g., ppt1001, pilot001)
%                           session # (1, 2)
%
% OUTPUTS                   baseline recording wav file
%                           baseline recording with different shift
%                               algorithms applied
%                           mat file with calibration info (e.g., f0, voice
%                               onset threshold, selected algorithm)
%
% e.g.                      runVoiceCal('ppt1001', 1)
%
% Also calls:               VoiceCalibrationAlgorithm
%                           
%
% Developed by Elaine Kearney (elaine-kearney.com).... edited by Andrew Meier for seq-pert
% Matlab 2019b
%
%% set up
close all

% recording info
nTrials = 3;
readyDur = 3;
cueDur = 1.5;
recordLen = 2.5;
stimOn = recordLen - .5;
stim = 'bed';

% set directories
dirs = setDirs_seq_pert();

% ask user which pitch method to use
voiceCal.pertType = lower(questdlg('What type of auditory perturbations are you doing?', 'Perturbation Type', 'Pitch', 'Formant', 'Both', 'Both'));
switch voiceCal.pertType
    case {'pitch', 'both'}
        voiceCal.pitchMethod = lower(questdlg('Which pitch method would you like to use?', 'Pitch Method', 'Phase-vocoder', 'Time-domain', 'Phase-vocoder'));
    case 'formant'
        voiceCal.pitchMethod = 'NaN';
end

bidsSubID = ['sub-' subjectID];
bidsSesID = ['ses-' num2str(session)];

if contains(subjectID,'test','IgnoreCase',true) || contains(subjectID,'pilot','IgnoreCase',true)
    dirs.sub = fullfile(dirs.pilot, bidsSubID);
    dirs.ses = fullfile(dirs.pilot, bidsSubID, bidsSesID, 'beh');% Directs test and pilot data to be saved into the project pilot directory
    dirs.config = fullfile(dirs.pilot, 'config', 'ACOUSTIC');
else
    dirs.sub = fullfile(dirs.data, bidsSubID);
    dirs.ses = fullfile(dirs.data, bidsSubID, bidsSesID, 'beh');    % Directs study data to be saved into the project directory
end

dirs.voiceCal = fullfile(dirs.ses, 'task-voicecalibration');

if ~exist(dirs.voiceCal, 'dir')
    mkdir(dirs.voiceCal)
end

% read subject-session config file
cfg = fullfile(dirs.config, sprintf('ses-%d', session), sprintf('sub-%s_ses-%d_config.mat',  subjectID, session));
load(cfg, 'gender');

% set up visualization
annoStr = setUpVisAnnot();
annoStr.Stim.String = stim;

% set audio device
setAudioDevice(0);

%% audapter setup
which Audapter; %makes sure audapter is mapped
Audapter info; %lets you know which sound card is being used

switch voiceCal.pertType
    case {'pitch', 'both'}
        p = setAudapterParams(gender, 'pitch', 'pitchMethod', voiceCal.pitchMethod);
        switch voiceCal.pitchMethod
            case 'phase-vocoder'
                ostFN = fullfile(dirs.audapter_config, sprintf('%s_pitch_reflex_gradual_pthresh0114_1.ost',project));
                pcfFN = fullfile(dirs.audapter_config, sprintf('%s_pitch_reflex_gradual_noshift.pcf',project));
                check_file(ostFN);
                check_file(pcfFN);
            case 'time-domain'
                ostFN = '';
                pcfFN = '';
        end
        
    case 'formant'
        p = setAudapterParams(gender, 'formant');
        ostFN = fullfile(dirs.audapter_config, sprintf('%s_onset_reflex_fullshift.ost',project));
        pcfFN = fullfile(dirs.audapter_config, sprintf('%s_formant_reflex_noShift.pcf',project));
        check_file(ostFN);
        check_file(pcfFN);
end

% set ost/pcf files
Audapter('ost', ostFN, 0);
Audapter('pcf', pcfFN, 0);

% initiate audapter                                                                
checkAudapterParams(p);                                                           
AudapterIO('init', p); %set up params for voice amplitude check 
EQfilters set_audapter; % user-prompt to select audapter's input/output equalization filters

AudapterIO('reset');                                                              
pause(0.01) % needed so doesn't lag                                                                                                                         
Audapter('start') %just to get audapter started                                   
Audapter('stop') 

%% check voicing amplitude and get fo
endVoiceCal = 0;
newRecording = 1;

set(annoStr.Ready, 'Visible','on');
pause(readyDur);
set(annoStr.Ready, 'Visible','off');

%% set up figure
s = struct; % subplots
h = struct; %handles

figure(2);
set(gcf,'Units','normalized','Position',[.05 .35 .6 .4])
sgtitle('Calibration recordings','fontsize',16);

for ii = 1:nTrials
    s(ii).splot = subplot(1,3,ii);
    s(ii).splot.YAxis.Exponent = 0;
    hold on
    h(ii).minMic = rectangle('pos',[0 -.2 2.5 .4],'EdgeColor', [1,1,1],'FaceColor',[.5 .5 .5 .4]);
    h(ii).mic = plot(nan, nan);          % mic
    h(ii).rms = plot(nan, nan, 'k', 'LineWidth', 2); % rms
    h(ii).rmsThresh  = yline(0, 'LineWidth', 2, 'LineWidth', 1, 'visible', 'off'); % rmsThresh
    h(ii).voiceOnset = xline(0, 'r--','LineWidth', 2, 'visible', 'off'); %voice onset
    h(ii).selection = plot(nan, nan, 'r', 'LineWidth', 2); % selection
    title(['Trial ' num2str(ii)]);
    ylabel('Sound Pressure');
    xlabel('time (s)')
    ylim([-1,1])
    %hold off
    legend([h(ii).mic h(ii).rmsThresh h(ii).voiceOnset h(ii).selection], 'Mic RMS','rmsThresh', 'Voice detect', 'Selection', 'Location', 'southeast')
    hold off %is this needed??
end

while endVoiceCal == 0
    
    while newRecording == 1
        
        for ii = 1:nTrials
            
            % ready
            % cue
            set(annoStr.Plus, 'Visible','on');
            pause(cueDur);
            
            % stimulus
            set(annoStr.Plus, 'Visible','off');
            set(annoStr.Stim,'Visible','on');
            
            % stimulus timer
            t = timer;
            t.StartFcn = @(myTimerObj, thisEvent)set(annoStr.Stim,'Visible','on');  % Start timer with stimulus on
            t.StartDelay = stimOn;   % Delay between timer start and timer function (2s)
            t.TimerFcn = @(myTimerObj, thisEvent)set(annoStr.Stim,'Visible','off'); % Timer function turns stimulus off
            
            % start timer and audapter
            start(t)
            Audapter('start'); % start audapter
            pause(recordLen) % pause for length of trial

            set(annoStr.Stim,'Visible','off');
            set(annoStr.Plus,'Visible', 'on');
            Audapter('stop'); % stop audapter
            pause(0.01) % needed so doesn't lag
            
            delete(t)
            
            % get data
            trialData(ii) = AudapterIO('getData');
            
            % get time vector
            timeV = (0:1/p.sr:(length(trialData(ii).signalIn)/(p.sr)))'; % replace with gettimevec function?
            timeV = timeV(1:(length(timeV)-1));
            rX = 0; rY = -.2; rW = max(timeV); rH = 2*(abs(rY)); % dimensions for min acceptable mic levels rectangle

            % add min mic box, mic signal and rms trace to plot
            set(h(ii).minMic,'pos',[rX rY rW rH]);
            set(h(ii).mic,'xdata',timeV,'ydata',trialData(ii).signalIn);
            set(h(ii).rms,'xdata',timeV,'ydata',repelem(trialData(ii).rms(:,1),p.frameLen));
            xlim([min(timeV),max(timeV)])
            addToolbarExplorationButtons(gcf)
            ax = gca; ax.Toolbar.Visible = 'off'; % Turns off the axes toolbar
            hold on
        end

        % check mic levels - redo recording?
        micCheck = questdlg('Are you happy with the mic levels?', 'Mic levels', 'Yes', 'No - redo the recording', 'Yes');
        if strcmp(micCheck, 'Yes')
            newRecording = 0;
        else
            newRecording = 1;
        end
    end
    
    %% select section of voice you want to analyze
    
    selection = zeros(nTrials,2,2);
    dataselection = cell(nTrials,1);
    tmpRmsThresh = zeros(nTrials,1);
    f0 = nan(nTrials,1);
    
    for ii = 1:nTrials
        
        % message box with prompt
        f = msgbox('Select the onset and offset of a stable portion of voicing', ['Trial ' num2str(ii)']);
        waitfor(f);
        
        % user selection - using ginput_ax to restrict selection to specific subplot
%         selection(ii,:,:) =  ginput_ax(s(ii).splot, 2);
        selection(ii,:,:) =  ginput(2);
        startVoiceIndx = round((selection(ii,1,1))*(p.sr)); %start of voice segment to analyze
        endVoiceIndx = round((selection(ii,2,1))*(p.sr)); %end of voice segment to analyze

        % plot selection
        dataselection{ii} = trialData(ii).signalIn(startVoiceIndx:endVoiceIndx); %portion selected to analyze
        tselection = timeV(startVoiceIndx:endVoiceIndx); %time of selection to analyze
        set(h(ii).selection,'xdata',tselection,'ydata',dataselection{ii});
        set(h(ii).selection,'visible','on');
        pause(1)
        set(h(ii).selection,'visible','off');
        
        % voice onset threshold
        minRms = prctile(trialData(ii).rms(:,1),10);
        maxRms = prctile(trialData(ii).rms(ceil(startVoiceIndx/p.frameLen):floor(endVoiceIndx/p.frameLen),1),90);
        tmpRmsThresh(ii,1) = minRms + (maxRms-minRms)/10;
        
        % get first sample with RMS over threshold % update to be 20ms
        threshidx = find(trialData(ii).rms(:, 1) > tmpRmsThresh(ii,1), 1);
        
        %add RMS Threshold line to plot
        set(h(ii).rmsThresh,'value', tmpRmsThresh(ii,1), 'visible','on');
        
        %add RMS onset line to plot
        set(h(ii).voiceOnset,'value', threshidx*p.frameLen/p.sr, 'visible','on');
        
        %pull out the pitch
        switch voiceCal.pertType
            case {'pitch', 'both'}
                switch voiceCal.pitchMethod
                    case 'phase-vocoder'
                        f0(ii) = nanmean(pitch(dataselection{ii},p.sr));
                    case 'time-domain'
                        f0(ii) = nanmean(trialData(ii).pitchHz(round(startVoiceIndx/p.frameLen):round(endVoiceIndx/p.frameLen))); %get average f0
                end
                plotTitle = ['Trial ' num2str(ii) ': \color{red}f0 = ' num2str(round(f0(ii),0))];
                title(s(ii).splot, plotTitle)
        end
    end
    
    % option to select rmsThresh manually
    rmsCheck = questdlg('Are you happy with the rmsThresh value for some of the trials?', 'rmsThresh', 'Yes', 'No - select manually', 'Yes');
    
    switch rmsCheck
        case 'Yes'
            rmsAll = questdlg('Do you want to include all trials in the estimate of rmsThresh', 'rmsThresh', 'Yes', 'No - let me choose', 'Yes');
            switch rmsAll
                case 'Yes'
                    p.rmsThresh = mean(tmpRmsThresh);
                    voiceCal.threshType = 1; % auto
                case 'No - let me choose'
                    prompt = {'Trial no.'};
                    dlgtitgle = 'Specify trials to include';
                    dims = [1,50];
                    defaultInput = {num2str([1,2,3])};
                    runPrompt = inputdlg(prompt, dlgtitgle, dims, defaultInput);
                    idx = str2num(runPrompt{:});
                    p.rmsThresh = mean(tmpRmsThresh(idx));
                    voiceCal.threshType = 1;
            end
            
        case 'No - select manually'
            for ii = 1:nTrials
                
                set(h(ii).rmsThresh,'visible','off');
                set(h(ii).voiceOnset, 'visible','off');
                f = msgbox('Select the rmsThresh level', ['Trial ' num2str(ii)']);
                waitfor(f);
                coords = ginput(1);
                tmpRmsThresh(ii,1) = coords(2);
                set(h(ii).rmsThresh,'value', tmpRmsThresh(ii,1), 'visible','on');
                set(h(ii).voiceOnset,'value', coords(1), 'visible','on');
            end
            voiceCal.threshType = 2; % manual
    end
    voiceCal.p=p;
    
    % fo check
    switch voiceCal.pertType
        case {'pitch', 'both'}
            f0Check = questdlg('Are the estimates of f0 reasonable?', 'f0', 'Yes', 'No - redo selection', 'Yes');
            switch f0Check
                case 'Yes'
                    endVoiceCal = 1;
                    f0All = questdlg('Do you want to include all trials in the estimate of f0?', 'f0', 'Yes', 'No - let me choose', 'Yes');
                    switch f0All
                        case 'Yes'
                            voiceCal.f0 = nanmean(f0);
                            
                        case 'No - let me choose'
                            prompt = {'Trial no.'};
                            dlgtitgle = 'Specify trials to include';
                            dims = [1,50];
                            defaultInput = {num2str([1,2,3])};
                            runPrompt = inputdlg(prompt, dlgtitgle, dims, defaultInput);
                            idx = str2num(runPrompt{:});
                            voiceCal.f0 = nanmean(f0(idx));
                    end
                    
                    switch voiceCal.pitchMethod
                        case 'time-domain'
                            p.pitchLowerBoundHz = voiceCal.f0 - 40; % Lower
                            if p.pitchLowerBoundHz < 0
                                p.pitchLowerBoundHz = 0;
                            end
                            p.pitchUpperBoundHz = voiceCal.f0 + 40; % Upper
                    end
            end
        case 'formant'
            endVoiceCal = 1;
    end
end
close(gcf) %close current figure

%% save wav recording
for ii = 1:nTrials
    fName = fullfile(dirs.voiceCal, sprintf('sub-%s_ses-%d_task-voicecalibration_baselinerecording_%d.wav', ...
        subjectID, session, ii));
    audiowrite(fName, trialData(ii).signalIn,p.sr);
end

%% run voice calibration algorithm
switch voiceCal.pitchMethod
    case 'time-domain'
        prompt = {'Trial no.'};
        dlgtitgle = 'Which trial do you want to use for testing the different algorithms?';
        dims = [1,100];
        defaultInput = {'1'};
        runPrompt = inputdlg(prompt, dlgtitgle, dims, defaultInput);
        trialNum = str2num(runPrompt{:});
        voiceCal.algo = VoiceCalibrationAlgorithm(dirs, subjectID, session, p, trialNum);
end

%% save
voiceCal.rmsThresh = p.rmsThresh;
voiceCal.p = p;
voiceCal.audapData = trialData;
fName = fullfile(dirs.voiceCal, sprintf('sub-%s_ses-%d_task-voicecalibration.mat', ...
    subjectID, session));
save(fName, 'voiceCal');
close all

end