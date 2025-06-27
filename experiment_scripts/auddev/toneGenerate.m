function toneGenerate(time, freq, wavDir)
%
% Generates and plays a tone at a specific frequency for a given amount of time
% and creates a WAV file of the tone to store at input wavDir
%
% INPUT:    time      Length (in seconds) of tone played
%           freq      Frequency (in hertz) of tone played
%           wavDir    Directory for storage of .wav file
%
% Created by Alex Acosta

% Establish sampling rate and time
Fs = 14400;
t = linspace(0, time, Fs * time);

%Establish radian value to generate tone
w = 2 * pi * freq;

%Create tone via sine wave
s = sin(w * t);

%Create file name and temp file
filename = fullfile(wavDir, strcat(num2str(freq), 'hz_', num2str(time), 'sec.wav'));

%Generate tone
sound(s, Fs);

%create wav file
audiowrite(filename, s, Fs)