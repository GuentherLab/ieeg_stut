% Temporary script that fixes the erroneous timingTrial and reference_time
% variables set in sub-FBFF-test005 and sub-FBFF-test006's reflexive data

subIDs = {'sub-FBFF-test004','sub-FBFF-test005','sub-FBFF-test006'};

remote = 0;
rootDir = fullfile('projectnb','busplab','Experiments','AudDev-PILOT');

% sub-FBFF-test005 files
numRuns = 15;
runs = [1 2 3 4 5 6 1 2 3 1 2 3 4 5 6];
sessions = [6 7 8];




% sub-FBFF-test006 files
sessions = [3 3 3 3 3 3 4 4 4 5 5 5 5 5 5];
sub = 'sub-FBFF-test006';

for r = 1:numRuns
    file = fullfile(rootDir,sub,['ses-' num2str(sessions(r))],'beh',...
        sprintf('%s_ses-%d_run-%d_task-aud-reflexive.mat',sub,sessions(r),runs(run)));
    load(file)

    for t = 1:30
        cond = trialData(t).condLabel;

        % Problem: timingTrial(5) is smaller than timingTrial(4)
        % Solution: Reset timingTrial(5) in all trials
        
        % Problem: reference_time is too brief in each trial
        % Solution: reference_time = pertJitter + time_voice_start
        if strcmp(cond,'U0')
            
            % timingTrial(5)
            pitchDiff = (trialData(t).audapData.shiftedPitchHz - trialData(t).audapData.pitchHz)...
                ./ trialData(t).audapData.pitchHz;
            trialData(t).timingTrial(5) = trialData(t).timingTrial(2)...
                + find(((pitchDiff+1)>=(1.0595-.01) & (pitchDiff+1)<=(1.0595+.01)),1,'first')...
            * trialData(ii).audapData.params.frameLen/trialData(ii).audapData.params.sr;
        
            % timingTrial(4) (PERT_START) & reference_time
            if r==1||r==2||r==3
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + 0.01;
            elseif r==4||r==5||r==6
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + .4;
            else
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + trialData(t).pertJitter;
            end
            trialData.timingTrial(4) = trialData.timingTrial(2) + trialData(t).reference_time;
                

        elseif strcmp(cond,'D0')
        
            % timingTrial(5)
            pitchDiff = (trialData(t).audapData.shiftedPitchHz - trialData(t).audapData.pitchHz)...
                ./ trialData(t).audapData.pitchHz;
            trialData(t).timingTrial(5) = trialData(t).timingTrial(2)...
                + find(((pitchDiff+1)>=(.9439-.01) & (pitchDiff+1)<=(.9439+.01)),1,'first')...
            * trialData(ii).audapData.params.frameLen/trialData(ii).audapData.params.sr;
        
            % timingTrial(4) (PERT_START) & reference_time
            if r==1||r==2||r==3
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + 0.01;
            elseif r==4||r==5||r==6
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + .4;
            else
                trialData(t).reference_time = trialData(t).rmsVoiceOnset + trialData(t).pertJitter;
            end
            trialData.timingTrial(4) = trialData.timingTrial(2) + trialData(t).reference_time;

        elseif strcmp(cond,'N0')

            % reference_time
            if r==1||r==2||r==3,trialData(t).reference_time = trialData(t).rmsVoiceOnset + .01;
            elseif r==4||r==5||r==6, trialData(t).reference_time = trialData(t).rmsVoiceOnset + .4;
            else trialData(t).reference_time = trialData(t).rmsVoiceOnset + trialData(t).pertJitter;
            end

        elseif strcmp(cond,'D1')||strcmp(cond,'U1')||strcmp(cond,'N1')

            % reference_time is set to where ost_stat turns to 3
            % timingTrial(5) (TIME_PERTACTUALLYSTART) is also set to this
            % value
            pertIdx = find(trialData(t).audapData.ost_stat == 3,1,'first');
            trialData(t).reference_time = pertIdx * 500;
            
            % timingTrial(3) and rmsVoiceOnset is set to 25 frames
            % (minThreshTime) before pert onset.
            rmsVoiceOnset = (pertIdx - 25) * 500;
            trialData(t).timingTrial(3) = trialData(2).timingTrial(
            
            % timinG=g
            
        end

        % Change pertJitter such that it always equals the time between voice onset
        % and pert onset
    end
end