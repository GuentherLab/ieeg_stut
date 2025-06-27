function [recAudio, percMissingSamples] = onlineVoiceDetection()
%
% Development script to test online voice detection functionality as part
% of SAP study (not called as part of runExp; relevant lines were
% integrated into main script).
%
% Functionality:
%   records audio
%   prompts the user to start speaking
%   checks for voice onset every frame - once detected, sends a pseudo
%       perturbation trigger (prints to screen)
%   plots the audio recording and voice onset (if detected) in real time
%
% OUTPUT:
%   percMissingSamples = percentage of missing samples across the audio
%   recording; ideally this should be close to zero but may increase
%   depending on processing power of computer and other processes running -
%   if percMissingSamples increases, you will need to increase the frameDur
%   variable to allow more time between frames
%
% Also calls detectVoiceOnset.m; note that there are 2 key variables passed
% to this function (onThresh, onDur) - these determine the threshold for
% detecting voicing and how long this threshold has to be met to be
% considered an onset. These values will vary per setup (e.g., mic, audio
% settings). Make sure you test for your setup.
%
% Developed in Matlab 2019a by Elaine Kearney (elaine-kearney.com)
% Jan 2021
%

%% variables to edit
recordLen = 2.5;            % length of recording
Fs = 48000;                 % sampling frequency
frameDur = .05;             % frame duration in seconds
frameLength = Fs*frameDur;  % framelength in samples
onDur = 50;                 % how long the intensity must exceed the threshold to be considered an onset (ms)
onDurS = onDur/1000;        % onDur in seconds
onThresh = -50;             % onset threshold

close all

% audio device reader settings
deviceReader = audioDeviceReader(...
    'Device', 'Default', ...   
    'SamplesPerFrame', frameLength, ...
    'SampleRate', Fs, ...
    'BitDepth', '16-bit integer');

% initialize variable to store audio signal
nSamples = recordLen*Fs;
recAudio = nan(nSamples,1);
nMissingSamples = 0; % cumulative n missing samples between frames

% counter for # of frames
frameCount = 1;
endIdx = 0;

% specify how far back in signal to look for voice onset (s)
onsetWindow = onDurS+frameDur; 

% set up figure
h=figure();
xlabel('Time(s)');
ylabel('Sound Pressure');
g = animatedline(gca(h), 'MaximumNumPoints', nSamples);
time = 0:1/Fs:(nSamples-1)/Fs;
plotVoiceOnset = 0;

% start trial
voiceOnsetDetected = 0;
setup(deviceReader)
disp('Speak into microphone now.')

% read audio data
while endIdx < nSamples
    
    % find beginning/end indices of frame, accounting for previous missing samples
    begIdx = (frameCount*frameLength) - (frameLength-1) + nMissingSamples;
    endIdx = (frameCount*frameLength) + nMissingSamples;
    
    % read audio data
    [audioFromDevice, numOverrun] = deviceReader();     % read one frame of audio data
    numOverrun = double(numOverrun);    % convert from uint32 to type double
    if numOverrun > 0, recAudio(begIdx:begIdx+numOverrun-1) = 0; end      % set missing samples to 0
    recAudio(begIdx+numOverrun:endIdx+numOverrun) = audioFromDevice;    % save frame to audio vector
    nMissingSamples = nMissingSamples + numOverrun;     % keep count of cumulative missng samples between frames
    
    % plot audio data
    addpoints(g, time, recAudio(1:nSamples))
    drawnow()
    
    % check for voice onset once 1.5 times onDur has passed
    if voiceOnsetDetected == 0 && frameCount > onsetWindow/frameDur
        
            % voice onset can occur at any time
            minVoiceOnsetTime = 0;
            
            % look for voice onset in previous samples covering 1.5 times onDur
            [voiceOnsetDetected, voiceOnsetTime]  = detectVoiceOnset(recAudio(endIdx+numOverrun-(round(onsetWindow*Fs)):endIdx+numOverrun,:), Fs, onDur, onThresh, minVoiceOnsetTime);
            
            % update voice onset time based on index of data passed to voice onset function
            voiceOnsetTime = voiceOnsetTime + (endIdx+numOverrun-(round(onsetWindow*Fs)))/Fs;

        % once voice onset is detected, "send" the pert trigger
    elseif voiceOnsetDetected == 1
        
        disp('Perturbation Trigger');
        
        if plotVoiceOnset == 0
            
            % add voice onset to plot
            xline(voiceOnsetTime, 'Color', 'r', 'LineWidth', 3);
            drawnow update
            plotVoiceOnset = 1;
            
        end
    end
    
    % update frame counter
    frameCount = frameCount+1;
end

% release device
release(deviceReader)

disp('Trial complete!')

percMissingSamples = (nMissingSamples/(recordLen*Fs))*100;
end
