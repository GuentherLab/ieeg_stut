function createSubjPcfFiles(pert, direction, angle,dirs)
% Script to create PCF files for the AudDev pitch and formant perturbations. These
% files are used with the old phase vocoder method of perturbing pitch in Audapter.
%
% See the Audapter manual for more information regarding PCF files.
%
%
%% INPUTS
%                            pert
%                                 Magnitude of F1F2 vector for formant
%                                 perturbations
%                                   Defined in RunExp as
%                                   expParams.magnitude *
%                                   trialMagnitudes(trial_index)
%                            direction
%                                  Direction of perturbation
%                                  Takes input as 'Up' or 'Down'
%                           angle
%                               Magnitude of the F1/F2 vector angle in
%                               radians. 0 = F1 shift only
%
% Also calls:               Audapter (audapter_matlab, audapter_mex, commonmcode)
%                           setDirs.m
%
% Developed by Elaine Kearney, Aug 2021 (elaine-kearney.com)
% Developed from createPcfFiles by Alexander Acosta, Oct 2021
% Matlab 2020b


%% setup

% derived variables
%rampSteps = (rampTime/timestep)+1; % num steps needed during pert onset
%pert = linspace(1/rampSteps, maxPert, rampSteps);
%pert = round(pert, 5);
nOSTRules = 3;
nPCFRules = nOSTRules + 1;

%default values
if nargin<2
    direction = 'Up';
    angle = 0;
elseif nargin < 3
    angle = 0;
end

%define pertDirect based on direction input
switch direction
    case 'Up'
        pertDirection = 1;
    case 'Down'
        pertDirection = -1;
    case 'Control'
        pertDirection = 1;
end

% go time

%% create pcf files
fname = sprintf('AudDev_formant_adapt.pcf');
fid = fopen(fullfile(dirs.audapter_config, fname), 'w');

fprintf(fid, '# Section 1 (Time warping): tBegin, rate1, dur1, durHold, rate2\n');
fprintf(fid, '0\n\n');

fprintf(fid, '# Section 2: stat pitchShift(st) gainShift(dB) fmtPertAmp fmtPertPhi(rad)\n');
fprintf(fid, '# In this section, the # in the first column corresponds to the tracking mode in the OST file, and the second column is the magntiude of perturbation\n');

fprintf(fid, '%d\n', nPCFRules);
modeNum = 0;

for j = 1:3
    fprintf(fid, '%d, 0, 0, 0, 0\n', modeNum);
    modeNum = modeNum +1;
end
for k = 1
    fprintf(fid, '%d, 0, 0, %s, %s \n', modeNum, num2str(pert*pertDirection), num2str(angle));
    modeNum = modeNum +1;
end
fprintf(fid, '%d, 0, 0, 0, 0\n\n', modeNum);

fclose(fid);
