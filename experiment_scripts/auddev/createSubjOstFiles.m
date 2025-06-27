function createSubjOstFiles(dirs, subjectID, session, runName, measurePert, trialNum, rampTime, rmsThresh, minThreshTime, pertJitter)
% function createSubjOstFiles(dirs, subjectID, session, runName, trialNum, rampTime, rmsThresh, minThreshTime, pertJitter)
%
% Function to create subject and trial-specific OST file for the SAP pitch perturbations. These
% files are saved to the subject data directory used with the old phase vocoder method of perturbing 
% pitch in Audapter.
%
% INPUTS    dirs                structure created with setDirs.m function
%           subjectID           string
%           session             session number, 1 or 2
%           measurePert         'pitch' or 'formant'
%           rampTime            time over which perturbation is introduced
%           runName             run name, e.g. 'run-1', 'run-practice'
%           trialNum            trial number
%           rmsThresh           structure created with runVoiceCal.n function               
%           minThreshTime       min time above threshold to be considered
%                               voice onset (seconds)
%           pertJitter          jitter time between voice onset and pert onset
%
% See the Audapter manual for more information re OST files.
%
% Developed by Elaine Kearney, Aug 2021 (elaine-kearney.com)
% Matlab 2020b

%% setup

% time step between changes in pert magnitude during pert onset
timestep = .005; 

% derived variables
rampSteps = (rampTime/timestep)+1; % num steps needed during pert onset
nOSTRules = 3 + rampSteps;

%% create ost file: pitch

if strcmp(measurePert,'pitch')

    fname = sprintf('sub-%s_ses-%d_%s_task-aud_trial-%d_pitchreflex.ost', subjectID, session, runName, trialNum);
    fid = fopen(fullfile(dirs.run, fname), 'w');

    modeNum = 0;
    fprintf(fid, '# Online status tracking (OST) configuration file\n');
    fprintf(fid, 'rmsSlopeWin = 0.030000\n\n');

    fprintf(fid, '# Main section: Heuristic rules for tracking\n');
    fprintf(fid, 'n = %d\n', nOSTRules);
    fprintf(fid, '%d INTENSITY_RISE_HOLD %s %s {}   # Detect voicing onset for at least 20ms\n', modeNum, num2str(rmsThresh), num2str(minThreshTime));
    modeNum = modeNum + 2;  % intensity rise hold mode advances 2 modes
    fprintf(fid, '%d ELAPSED_TIME %s NaN {}           # Wait for %s seconds after voice detecion\n', modeNum, num2str(pertJitter), num2str(pertJitter));
    modeNum = modeNum +1;
    for j = 1:rampSteps-1
        fprintf(fid, '%d ELAPSED_TIME .005 NaN {}            # Increase pitch shift every .005 seconds\n', modeNum);
        modeNum = modeNum + 1;
    end
    fprintf(fid, '%d ELAPSED_TIME 3 NaN {}               # Hold max pitch shift on for 3 seconds (longer than trial)\n', modeNum);
    modeNum = modeNum + 1;
    fprintf(fid, '%d OST_END NaN NaN {}                  # Stop tracking\n\n', modeNum);

    fprintf(fid, '# maxIOICfg\n');
    fprintf(fid, 'n = 0                                  # No maximum-inter-onset-interval rule\n');
    fclose(fid);
end
%% create ost file: formant

if strcmp(measurePert,'formant')

    fname = sprintf('sub-%s_ses-%d_%s_task-aud_trial-%d_formantreflex.ost', subjectID, session, runName, trialNum);
    fid = fopen(fullfile(dirs.run, fname), 'w');

    modeNum = 0;
    fprintf(fid, '# Online status tracking (OST) configuration file\n');
    fprintf(fid, 'rmsSlopeWin = 0.030000\n\n');

    fprintf(fid, '# Main section: Heuristic rules for tracking\n');
    fprintf(fid, 'n = %d\n', nOSTRules);
    fprintf(fid, '%d INTENSITY_RISE_HOLD %s %s {}   # Detect voicing onset for at least 20ms\n', modeNum, num2str(rmsThresh), num2str(minThreshTime));
    modeNum = modeNum + 2;  % intensity rise hold mode advances 2 modes
    fprintf(fid, '%d ELAPSED_TIME %s NaN {}           # Wait for %s seconds after voice detecion\n', modeNum, num2str(pertJitter), num2str(pertJitter));
    modeNum = modeNum +1;
    for j = 1:rampSteps-1
        fprintf(fid, '%d ELAPSED_TIME .005 NaN {}            # Increase formant shift every .005 seconds\n', modeNum);
        modeNum = modeNum + 1;
    end
    fprintf(fid, '%d ELAPSED_TIME 3 NaN {}               # Hold max formant shift on for 3 seconds (longer than trial)\n', modeNum);
    modeNum = modeNum + 1;
    fprintf(fid, '%d OST_END NaN NaN {}                  # Stop tracking\n\n', modeNum);

    fprintf(fid, '# maxIOICfg\n');
    fprintf(fid, 'n = 0                                  # No maximum-inter-onset-interval rule\n');
    fclose(fid);
end
