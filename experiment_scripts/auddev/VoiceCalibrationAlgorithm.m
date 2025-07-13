function algo = VoiceCalibrationAlgorithm(dirs, subjectID, session, p, trialNum)
% algo = algo = voiceCalibrationAlgorithm(dirs, subjectID, session, p)
% Function generates pitch shifted audio files for all three different
% 'pitchShiftAlgorithms' ('pp_none', 'pp_valleys', and 'pp_peaks'), 
% each with 'noshift', 'shiftup' and 'shiftdown' variants. 
%
% INPUTS:
%   dirs, structure with directory information created by 'setDirs.m'
%   subjectID, ID associated with the current subject
%   session, current subjects session (1 or 2) 
%   p, parameters used to initialize Audapter
% 
% OUTPUT:
%   algo, 'algorithm selector' used in the GUI


%% read baseline recording and upsample
fName = fullfile(dirs.voiceCal, sprintf('sub-%s_ses-%d_task-voicecalibration_baselinerecording_%d.wav', ...
            subjectID, session, trialNum));
[baselineRec, baselineFS] = audioread(fName);
p.downFact = 3;
baselineRec=resample(baselineRec, baselineFS * p.downFact, baselineFS);


%% save all algorithm types

%%  pp_none
    % no shift
    shiftPitch([0,1],'noshift','pp_none');
    % shift up
    shiftPitch([0, 1.0595],'shiftup','pp_none');
    % shift down
    shiftPitch([0, 0.9439],'shiftdown','pp_none');

%% pp_valleys
    % no shift
    shiftPitch([0,1],'noshift','pp_valleys');
    % shift up
    shiftPitch([0, 1.0595],'shiftup','pp_valleys');
    % shift down
    shiftPitch([0, 0.9439],'shiftdown','pp_valleys');

%% pp_peaks
    % no shift
    shiftPitch([0,1],'noshift','pp_peaks');
    % shift up
    shiftPitch([0, 1.0595],'shiftup','pp_peaks');
    % shift down
    shiftPitch([0, 0.9439],'shiftdown','pp_peaks');

% open gui to check algorithm
currDir = cd;
cd(dirs.voiceCal);

%% gui
h = AlgorithmSelect;
global algoSelect
waitfor(h)
algo = algoSelect;

%% end
cd(currDir);

%% helper function used for shift pitching

    function shiftPitch(pitchShiftSchedule, shiftDirection, pitchShiftAlgorithm)
        % Helper function used to generate pitch shifted audio files
        % according to the input variables.
        % The expected inputs are the following: 
        %   shiftPitchSchedule, [0 1],  [0, 1.0595], or [0, 0.9439]
        %   shiftDirection, 'noshift', 'shiftup', or 'shiftdown'
        %   pitchShiftAlgorithm, 'pp_none', 'pp_valleys', or 'pp_peaks'
        p.timeDomainPitchShiftAlgorithm = pitchShiftAlgorithm;
        p.timeDomainPitchShiftSchedule = pitchShiftSchedule;
        AudapterIO('reset')
        checkAudapterParams(p);
        AudapterIO('init', p);
        sigInCell = makecell(baselineRec, p.frameLen*p.downFact);
        for n = 1 : length(sigInCell)
            Audapter('runFrame', sigInCell{n});
        end
        
        data = AudapterIO('getData');
        wavfileName = fullfile(dirs.voiceCal, sprintf('sub-%s_ses-%d_task-voicecalibration_%s-%s.wav', ...
            subjectID, session, p.timeDomainPitchShiftAlgorithm, shiftDirection));
        audiowrite(wavfileName, data.signalOut, baselineFS)
    end

end   
    