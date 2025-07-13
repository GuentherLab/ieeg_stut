function testMicHeadphones(gender)
% function testMicHeadphones(gender)
% tests audapter playing microphone signal through headphones
%
% INPUT     gender: male/female (sets up and lower bounds for pitch tracking)
%
% Developed by Elaine Kearney, Jan 2020 (elaine-kearney.com)
%
% Matlab 2019b

%% Set up 

% workspace
close all
dirs = setDirs('AudDev');

type = questdlg('Do you want to run Audapter continuosly or for a 2.5-second recording?', 'Type of recording', 'Continuous', '2.5 seconds', 'Continuous');

%  Set up Audio device
setAudioDevice(0);

% figure for mic plot
if strcmp(type, '2.5 seconds')
    [h1,h2,h3,~] = setUpMicPlot;
end

%%  Set up Audapter
which Audapter;     %makes sure audapter is mapped
Audapter info;      %lets you know which sound card is being used

% set params for no-shift formant shift
p = setAudapterParams(gender, 'formant');
%p.dScale = 1.75;

% ost/pcf files
ostFN = fullfile(dirs.audapter_config, 'AudDev_onset_reflex_fullshift.ost');
pcfFN = fullfile(dirs.audapter_config, 'AudDev_formant_reflex_noShift.pcf');
check_file(ostFN);
check_file(pcfFN);
Audapter('ost', ostFN, 0);
Audapter('pcf', pcfFN, 0);

% initiate audapter
checkAudapterParams(p);
AudapterIO('init', p);
EQfilters set_audapter; % user-prompt to select audapter's input/output equalization filters
AudapterIO('reset');
pause(.01);

% If matlab is restarted, the first time audapter runs, the voice feedback
% is high-pitched. This runs a quick start/stop of audapter before doing
% the mic test.
Audapter('start');
Audapter('stop');

%% Record & plot
switch type
    
    case 'Continuous'
        
        % start, pause, stop
        Audapter('start')
        fprintf('.\n.\nAudapter is running - press any key to stop\n.\n.\n');
        pause;
        Audapter('stop')
        
    case '2.5 seconds'
        
        % set up visualization
        annoStr = setUpVisAnnot();
        readyDur = 2;
        cueDur = 1;
        stimDur = 2.5;
        annoStr.Stim.String = 'bed';
        
        endTest = 0;
        trialData = struct;
        
        while endTest == 0
            
            % ready 
            set(annoStr.Ready, 'Visible','on');
            pause(readyDur);
            set(annoStr.Ready, 'Visible','off');
            
            % cue
            set(annoStr.Plus, 'Visible','on');
            pause(cueDur);
            
            % run Audapter
            Audapter('start')
            
            % stimulus
            set(annoStr.Plus, 'Visible','off');
            set(annoStr.Stim,'Visible','on');
            pause(stimDur)
            
            Audapter('stop')
            set(annoStr.Stim,'Visible','off');
            pause(0.01)
            
            % get data
            ii = 1;
            trialData(ii).audapData = AudapterIO('getData');
            rmsOnsetIdx = find(trialData(ii).audapData.rms(:,1) > p.rmsThresh); % find indices greater than rms threhsold for voicing
        
            if isempty(rmsOnsetIdx) %if no index was found greater than the voicing threshold
                trialData(ii).onsetDetected = 0;
                trialData(ii).rmsVoiceOnset = NaN;
            else
                trialData(ii).onsetDetected = 1;
                trialData(ii).rmsVoiceOnset = ((rmsOnsetIdx(1))*p.frameLen)/p.sr; %first time crosses rms threshold
            end
            
            % plot the data
            plotMicSignal(p, trialData, ii, h1, h2, h3, 'phase-vocoder') %pitch method is set to phase-vocoder because pitch is not estimated
            %during the formant trial; plotMicSignal will estimate the
            %pitch for us
            
            % redo?
            recordAgain = questdlg('Do you want to record again?', 'Recording', 'Yes', 'No', 'Yes');
            
            switch recordAgain
                
                case 'Yes'
                    endTest = 0;
                    
                case 'No'
                    endTest = 1;
            end
        end
        
        close all
end