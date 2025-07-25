% Write new pre-defined config strcuture
% add new fields if needed

%       visual                      : type of visual presentation ['figure']
%       root                        : root directory [pwd]
%       audiopath                   : directory for audio stimuli [pwd/stimuli/audio/Adults]
%       figurespath                 : directory for visual stimuli [pwd/stimuli/figures/Adults]
%       subject                     : subject ID ['TEST01']
%       session                     : session number [1]
%       run                         : run number [1]
%       task                        : task name ['test']
%       gender                      : subject gender ['unspecified']
%       scan                        : true/false include scanning segment in experiment sequence [1] 
%       timePostStim                : time (s) from end of the audio stimulus presentation to the GO signal (D1 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [.25 .75] 
%       timePostOnset               : time (s) from subject's voice onset to the scanner trigger (or to pre-stimulus segment, if scan=false) (D2 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [4.5] 
%       timeMax                     : maximum time (s) before GO signal and scanner trigger (or to pre-stimulus segment, if scan=false) (D3 in schematic above) (recording portion in a trial may end before this if necessary to start scanner) [5.5] 
%       timeScan                    : (if scan=true) duration (s) of scan (D4 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [1.6] 
%       timePreStim                 : time (s) from end of scan to start of next trial stimulus presentation (D5 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [.25] 
%       timePreSound                : time (s) from start of orthographic presentation to the start of sound stimulus (D6 in schematic above) [.5]
%       timePostSound               : time (s) from end of sound stimulus to the end of orthographic presentation (D7 in schematic above) [.47]
%       minVoiceOnsetTime           : time (s) to exclude from onset detection (use when beep sound is recorded)
%       prescan                     : (if scan=true) true/false include prescan sequence at the beginning of experiment [1] 
%       rmsThresh                   : voice onset detection: initial voice-onset root-mean-square threshold [.02]
%       rmsBeepThresh               : beep onset detection: initial beep-onset root-mean-square threshold [.1]
%       rmsThreshTimeOnset          : voice onset detection: mininum time (s) for intentisy to be above RMSThresh to be consider voice-onset [0.02] 
%       rmsThreshTimeOffset         : voice offset detection: mininum time (s) for intentisy to be above and below RMSThresh to be consider voice-onset [0.25 0.25] 
%       ipatDur                     : prescan sequence: prescan IPAT duration (s) [4.75] 
%       smsDur                      : prescan sequence: prescan SMS duration (s) [7] 
%       deviceMic                   : device name for sound input (microphone) (see audiodevinfo().input.Name for details)
%       deviceHead                  : device name for sound output (headphones) (see audiodevinfo().output.Name for details) 
%       deviceScan                  : device name for scanner trigger (see audiodevinfo().output.Name for details)

expParams=struct(...
    'visual', 'orthography', ... % from 'figure', 'fixpoint', 'orthography', 
    'root', pwd, ...
    'audiopath', fullfile(pwd, 'stimuli', 'audio', 'exp'), ...
    'figurespath', fullfile(pwd, 'stimuli', 'figures', 'Adults'), ...
    'subject','TEST01',...
    'session', 1, ...
    'run', 1,...
    'task', 'test', ...
    'gender', 'unspecified', ...
    'scan', true, ...
    'timePostStim', [.25 .75],...
    'timePostOnset', 1.5,... % 'timePostOnset', 4.5,...
    'timeScan', 1.6,...
    'timePreStim', .25,...
    'timeMax', 2.5, ... % 'timeMax', 5.5, ...
    'timePreSound', .5, ...
    'timePostSound', .47, ...
    'rmsThresh', .02,... %'rmsThresh', .05,...
    'rmsBeepThresh', .1,...
    'rmsThreshTimeOnset', .02,...% 'rmsThreshTimeOnset', .10,...
    'rmsThreshTimeOffset', [.25 .25],...
    'prescan', true, ...
    'minVoiceOnsetTime', 0.4, ...
    'ipatDur', 4.75,...         %   prescan IPAT duration
    'smsDur', 7,...             %   prescan SMS duration
    'deviceMic','',...
    'deviceHead','',...
    'deviceScan','');

spm_jsonwrite('./config/SUB_beh_test.json', expParams);