%% Script to trigger the solenoid valve on the perturbatron using the arduino
%
% It's recommended to run this script once a month to maintain the
% functionality of the valve
%
% Requires: setUpArduino and IDSerialComs functions
%
% Developed by Elaine Kearney, Mar 2021 (elaine-kearney.com)
%
% Matlab 2019b

%% setup

% experimental params
numTrials = 5;
trialLen = 1;
iti = 1;

% set up Arduino
[ard, ardParam] = setUpArduino();

%% trial loop

for i = 1:numTrials
    t = tic;
    
    while toc(t) < trialLen
        writeDigitalPin(ard,ardParam.valvON,1);     % on
    end
    
    writeDigitalPin(ard,ardParam.valvON,0);     % off
    pause(iti);
end

% clear arduino object
clear ard
