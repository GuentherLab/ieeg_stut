function createSSNfile(noiseDur)
% function to generate speech-shaped noise (SSN) file that extends for max duration
% of run
%
% INPUTS
%           noiseDur = target duration of output file in seconds
%
% OUTPUTS
%           SSN file for SAP study
%
% Developed in Matlab 2019a by Elaine Kearney, Dec 2020
%

%% read in SSN file from DRF study

% set directories
dirs = setDirs('AudDev');

% maskFile 
maskFile = 'SSN.wav';   % this file was taken from the DRF repo (Dante's study); 
                        % Dante used an amplified version of this file (SSN_ampChunk.wav)
                        % however the amplification introduced a bunch of clipping to
                        % the file so I rolled back to the original non-amplified file
                        % We don't know exactly where this file came from 
[wavFile, fsorig] = audioread(maskFile);

% % resample to 48k
fs = 48000;
wavFile = resample(wavFile, fsorig, fs);
wavDur = length(wavFile);

% target duration of output file in samples
noiseDur = round(noiseDur*fs);

% create a 2-second linear ramp
rampUpSp = round(2*fs) + 1;
rampUpIdx = 1:rampUpSp;
rampUpL = length(rampUpIdx);
rampUp = linspace(0, 1, rampUpL);

% How many repetitions of the .wav file (decimal)
% whole repetitions
numRep = noiseDur/wavDur;
minInt = floor(numRep);   % Min number of whole repeitions (integer)
noiseInt = repmat(wavFile', [1, minInt]);

% partial repetitions
remRep = numRep - minInt; % How many decimal amounts left?
remIdx = round(wavDur*remRep);
noiseRem = wavFile(1:remIdx)';

% stitch them together
fullNoise = [noiseInt noiseRem];

% apply amplitude ramp at beginning of file so that onset of masking noise
% doesn't sound so sudden
rampFilt = ones(size(fullNoise));
rampFilt(rampUpIdx) = rampUp;
sessionNoise = fullNoise.*rampFilt;

% write file
audiowrite(fullfile(dirs.code, 'experiment', 'SSN', 'SAP_SSN.wav'), sessionNoise, fs, 'BitsPerSample', 24);

