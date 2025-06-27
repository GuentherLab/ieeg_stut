% Script to create PCF files for the SAP pitch perturbations. These
% files are used with the old phase vocoder method of perturbing pitch in Audapter. 
%
% See the Audapter manual for more information regarding PCF files.
%
% Developed by Elaine Kearney, Aug 2021 (elaine-kearney.com)
% Matlab 2020b

%% variables (can edit for different paradigms)
rampTime = .11; % 110 ms ramp onset
timestep = .005; % time step between changes in pert magnitude during pert onset
pertDirection = [1, -1, 0]; % up, down, no shift
pertDirStr = {'up', 'down', 'noshift'};
maxPert = 1; % 1 semi-tone = 100 cents

%% setup

% derived variables
rampSteps = (rampTime/timestep)+1; % num steps needed during pert onset
pert = linspace(1/rampSteps, maxPert, rampSteps);
pert = round(pert, 5);
nOSTRules = 3 + rampSteps;
nPCFRules = nOSTRules + 1;

% go time
dirs = setDirs('AudDev');

%% create pcf files
for i = 1:numel(pertDirection)
    
    fname = sprintf('AudDev_pitch_reflex_%s.pcf', pertDirStr{i});
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
    for k = 1:rampSteps
        fprintf(fid, '%d, %s, 0, 0, 0\n', modeNum, num2str(pertDirection(i)*pert(k)));
        modeNum = modeNum +1;
    end
    fprintf(fid, '%d, 0, 0, 0, 0\n\n', modeNum);
    
    fclose(fid);
end
