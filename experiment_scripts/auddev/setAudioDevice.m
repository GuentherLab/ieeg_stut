function [micDevName,headphonesDevID,triggerDevID] = setAudioDevice(scan)
% [micDevName,headphonesDevID,triggerDevID] = setAudioDevice()
% 
% This function sets device variables based on the detected audio interface
% (Motu Microbook II vs Focusrite Scarlett 2i2/4i4). NOTE: The Scarlett 2i2
% cannot be used to run an fMRI experiment, as it does not have an extra
% output that can be used to trigger the scanner. The mic and headphone
% device names are identical when using the 2i2 and 4i4 and do not need to
% be changed when switching between devices for behavioral experiments. 
% 
% SUPPORTED DEVICES:    Focusrite Scarlett 2i2
%                       Focusrite Scarlett 4i4
%                       Motu Microbook II
%
% INPUTS:   scan (0 = no scan, 1 = fMRI scan)
% OUTPUTS:  micDevName
%           headphonesDevID
%           triggerDevID
%
% Adapted from runExp.m by Jordan Manes 7/20/21
% Matlab 2019b

%% get audio device info
devInfo = audiodevinfo;

%% define Motu and Focusrite mic names
fr_mic = 'Analogue 1 + 2';
motu_mic = 'Mic-Guitar 1-2';
ek_mic = 'MacBook Pro Microphone (Core Audio)';

%% set device variables

% find input device ID for microphone
for i = 1: size(devInfo.input, 2)
    if contains(devInfo.input(i).Name, motu_mic) % if device is Motu
        micDevName = strsplit(devInfo.input(i).Name, ' (Windows DirectSound)');
        micDevName = micDevName{1};
        micDevID = devInfo.input(i).ID;
        trigDevName = 'Phones 1-2'; % trigger
        headDevName = 'Main 1-2'; %  heapdhones
    elseif contains(devInfo.input(i).Name, fr_mic) % if device if Focusrite
        micDevName = strsplit(devInfo.input(i).Name, ' (Windows DirectSound)');
        micDevName = micDevName{1};
        micDevID = devInfo.input(i).ID;
        trigDevName = 'Playback 3 + 4'; % trigger
        headDevName = 'Speakers'; % heapdhones
        Audapter('deviceName', 'Focusrite USB ASIO'); % needed or else Audapter will default to Motu
    elseif contains(devInfo.input(i).Name, ek_mic) % allows EK to test script up to calling Audapter
        micDevName = strsplit(devInfo.input(i).Name, ' (Core Audio)');
        micDevName = micDevName{1};
        micDevID = devInfo.input(i).ID;
        trigDevName = 'MacBook Pro Speakers';
        headDevName = 'MacBook Pro Speakers';
    end
end

% find output device ID for trigger and headphones
for i = 1: size(devInfo.output, 2)
    % find output device ID for trigDev - assign to scan trigger
    if scan ==1 
        if contains(devInfo.output(i).Name, trigDevName) == 1
            triggerDevID = devInfo.output(i).ID;
        end
    else
        triggerDevID = [];
    end
    
    % find output device ID for heaedDev - assign to headphones    
    if contains(devInfo.output(i).Name, headDevName) == 1
        headphonesDevID = devInfo.output(i).ID;
    end
end

%% display error message if no device ID is found
if ~exist('micDevID', 'var')
    error('Check that the default recording device is set correctly in sound settings and restart Matlab');
elseif ~exist('triggerDevID', 'var') && scan
    error('Check that the default playback device is set correctly in sound settings and restart Matlab');
elseif ~exist('headphonesDevID', 'var')
    error('Check that the playback device is enabled in sound settings and restart Matlab');
end

end

