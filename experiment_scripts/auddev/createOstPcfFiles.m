% Script to create OST and PCF files for PPT1 paradigm
%
% This paradigm involves pitch perturbations, using the old phase vocoder
% method of perturbing pitch in Audapter. There are two variations - one
% with a gradual onset of perturbation (over 110ms) and one with a sudden
% onset of perturbation (over 10ms). The onset of perturbation is also
% jittered between 500 and 1000ms.
%
% See the Audapter manual for more information re OST and PCF files.
%
% Developed by Elaine Kearney, Jul 2021 (elaine-kearney.com)
% Matlab 2020b

%% paradigm - perturbation onset
sudden = 1; % change to 0 for gradual paradigm
if sudden
    rampTime = .01;
    type = 'sudden';
else 
    rampTime = .11;
    type = 'gradual';
end

% variables (can edit for different paradigms)
timestep = .005; % time step between changes in pert magnitude during pert onset
pThresh = 0.025; % used for voice onset
pertDirection = [1, -1, 0]; % up, down, no shift
pertDirStr = {'up', 'down', 'noshift'};
maxPert = 1; % 1 semi-tone = 100 cents
jitterMin = .5;
jitterMax = 1;
nOST = 10; % creates 10 OST files with varying pert onset times

%% setup

% set randstream
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setGlobalStream(s);

% derived variables
dlm = strsplit(num2str(pThresh),'.');
pThreshStr = dlm{2};
rampSteps = (rampTime/timestep)+1; % num steps needed during pert onset
pert = linspace(1/rampSteps, maxPert, rampSteps);
pert = round(pert, 5);
nOSTRules = 3 + rampSteps;
nPCFRules = nOSTRules + 1;

% pert jitter
jitterVec = nan(nOST,1);
for i = 1:nOST
    jitterVec(i) = jitterMin + (jitterMax-jitterMin).*rand(1,1);
end
jitterVec = round(jitterVec, 3);

% go time
dirs = setDirs('AudDev');

%% create ost files
for i = 1:nOST
    
    fname = sprintf('AudDev_pitch_reflex_%s_pthresh%s_%d.ost', type, pThreshStr, i);
    fid = fopen(fullfile(dirs.audapter_config, fname), 'w');
    
    modeNum = 0;
    fprintf(fid, '# Online status tracking (OST) configuration file\n');
    fprintf(fid, 'rmsSlopeWin = 0.030000\n\n');

    fprintf(fid, '# Main section: Heuristic rules for tracking\n');
    fprintf(fid, 'n = %d\n', nOSTRules);
    fprintf(fid, '%d INTENSITY_RISE_HOLD %s 0.02 {}   # Detect voicing onset for at least 20ms\n', modeNum, num2str(pThresh));
    modeNum = modeNum + 2;  % intensity rise hold mode advances 2 modes
    fprintf(fid, '%d ELAPSED_TIME %s NaN {}           # Wait for %s seconds after voice detecion\n', modeNum, num2str(jitterVec(i)), num2str(jitterVec(i)));
    modeNum = modeNum +1;
    for j = 1:rampSteps-1
        fprintf(fid, '%d ELAPSED_TIME .005 NaN {}            # Increase pitch shift every .005 seconds\n', modeNum);
        modeNum = modeNum + 1;
    end
    fprintf(fid, '%d ELAPSED_TIME 3 NaN {}               # Hold max pitch shift on for 3 seconds (longer than trial)\n', modeNum);
    modeNum = modeNum + 1;
    fprintf(fid, '%d OST_END NaN NaN {}                  # Stop tracking\n\n', modeNum);
    
    fprintf(fid, '# maxIOICfg\n');
    fprintf(fid, 'n = 1                                 # One maximum-inter-onset-interval rule\n');
    fprintf(fid, '0 1 2                                # If voicing is not detected (status 0) after 1 second, turn on the perturbation(status 2)\n\n');
    fclose(fid);
end

%% create pcf files
for i = 1:numel(pertDirection)
    
    fname = sprintf('AudDev_pitch_reflex_%s_%s.pcf', type, pertDirStr{i});
    fid = fopen(fullfile(dirs.audapter_config, fname), 'w');

    fprintf(fid, '# Section 1 (Time warping): tBegin, rate1, dur1, durHold, rate2\n');
    fprintf(fid, '#In this section, the # in the first column corresponds to the tracking mode in the OST file, and the second column is the magntiude of perturbation\n');
    fprintf(fid, '0\n\n');

    fprintf(fid, '# Section 2: stat pitchShift(st) gainShift(dB) fmtPertAmp fmtPertPhi(rad)\n');
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
