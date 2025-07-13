function dOut = AudDevTrialTimingCheck(task)
%

%task = 'som';
if exist('setDirs', 'file') ~= 2 || exist('setUpAnalysis', 'file') ~= 2    % not files in search path
    error('Cannot find setDirs or setUpAnalysis function: Make sure that you add path to AudDev/code in your local GitHub repo')
end
[dirs, subjId, sessID, useRun] = setUpAnalysis(task);
f1 = figure;
f2 = figure;
f3 = figure;
f4 = figure;
% f5 = figure;

for rNum = 1:numel(useRun) 
    runID = useRun{rNum};
    dirs.run = [dirs.sess filesep runID filesep];
    nameMatFile = [dirs.run subjId '_' sessID '_' runID '_task-' task '.mat']; %find mat file
    load(nameMatFile, 'trialData'); %load in the mat file

    fCell = fieldnames(trialData);
    dCell = struct2cell(trialData);

    %tTiming is 6 X numTrials array derived from the trialData.timingTrial listing the seconds since trial onset for:
    %Auditory task:
        %Row 1: TIME_TRIAL_START
        %Row 2: TIME_TRIAL_ACTUALLYSTART
        %Row 3: TIME_VOICE_START
        %Row 4: TIME_PERT_START
        %Row 5: TIME_SCAN_START
        %Row 6: TIME_SCAN_ACTUALLYSTART
        %Row 7: TIME_SCAN_END
    %Somatosensory task:
        %Row 1: TIME_TRIAL_START; 
        %Row 2: TIME_TRIAL_ACTUALLYSTART; 
        %Row 3: TIME_VOICE_START; 
        %Row 4: TIME_PERT_START; 
        %Row 5: TIME_PERT_ACTUALLYSTART; 
        %Row 6: TIME_PERT_END; 
        %Row 7: TIME_PERT_ACTUALLYEND;
        %Row 8: TIME_SCAN_START; 
        %Row 9: TIME_SCAN_ACTUALLYSTART; 
        %Row 10: TIME_SCAN_END]
        
    tTiming = cell2mat(dCell(find(contains(fCell,'timingTrial')),:));
    
    %Plot trial onset time relative to start of run
   % tOnset = cell2mat(dCell(find(contains(fCell,'trialOnsetTime')),:));
    figure(f1); plot(tTiming(1,:),'linewidth',2); 
    hold on; title('TrialOnset');legend(useRun);
    
    %Plot Difference b/w Trial Onset 
    tInt = diff(tTiming(1,:)); 
    figure(f2); plot(tInt,'linewidth',2);
    hold on; title('Interval Between Consecutive Trials');legend(useRun);
    xlabel('Trial Interval');
    ylabel('Time (s)');
    
    %Keep mean/min/max
    dOut.tIntAvg(rNum) = nanmean(tInt);
    dOut.tIntMin(rNum) = nanmin(tInt);
    dOut.tIntMax(rNum) = nanmax(tInt);
    
    %Growth of trial interveal
    tIntGrowth = diff(tInt); %remove unstable 1st couple intervals
    figure(f3); plot(tIntGrowth,'linewidth',2);
    hold on; title('Growth of Interval Between Consecutive Trials');legend(useRun);
    xlabel('Trial Interval');
    ylabel('Time (s)');
    dOut.tIntGrowthAvg(rNum) = nanmean(tIntGrowth);
    


     %Plot voice onset time (TrialEnd) 
     figure(f4);
     vOnset = tTiming(3,:)-tTiming(1,:);
     plot(vOnset,'linewidth',2); 
     hold on; title('Voice Onset');legend(useRun);
     xlabel('Trial #');
     ylabel('Time (s)');
     %Keep mean/min/max for each run
     dOut.vOnset(rNum,:) = vOnset;
     
     eventInt = diff(tTiming,1,1);
     
    
%     %Plot Voice Onset time relative to the start of the trial
%     if strmatch('som',task),
%         vOnset = cell2mat(dCell(find(contains(fCell,'voiceOnsetTime')),:));
%     else
%         vOnset = cell2mat(dCell(find(contains(fCell,'rmsVoiceOnset')),:));
%     end
%     figure(f5)
%     plot(vOnset,'linewidth',2); 
%     hold on; title('Voice Onset Relative to Trial Onset');legend(useRun);
%     %Keep mean/min/max for each run
%     dOut.vOnsetAvg(rNum) = nanmean(vOnset); 
%     dOut.vOnsetMin(rNum) = nanmin(vOnset); 
%     dOut.vOnsetMax(rNum) = nanmax(vOnset);
   



end

