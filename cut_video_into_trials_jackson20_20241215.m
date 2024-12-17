 %%% generate audio-video files for each trial

 op.sub = 'pilot001'; 
 op.ses = 1; 
 op.run = 1; 
 op.task = 'jackson20'; 

%%
[dirs, host] = set_paths_ieeg_stut(); 

dirs.src_ses = [dirs.data, filesep, 'sub-',op.sub, filesep, 'ses-',num2str(op.ses)]; 
dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, op.task]; 
dirs.src_trialdata = [dirs.src_task, filesep, 'trialdata']; 
dirs.src_av = [dirs.src_ses, filesep, 'audio-video']; 
dirs.annot = [dirs.src_ses, filesep, 'annot']; 

file_prepend = ['sub-',op.sub, '_ses-',num2str(op.ses), '_task-',op.task, '_run-',num2str(op.run),  '_']; 
trial_table_tsv = [dirs.src_task, filesep, file_prepend,'trials-words.tsv']; 
run_subj_video_file = [dirs.src_av, filesep, file_prepend, 'recording-xxx_.xxx']; % video file to chop up
landmarks_file = [dirs.annot, filesep, file_prepend,'landmarks.tsv'];


% load files
ldmks = readtable(landmarks_file,'FileType','text'); 
recording_file = [dirs.src_av, filesep, ldmks.file{string(ldmks.computer)=='recording'}]; 
vidob = VideoReader(recording_file);

trials = readtable(trial_table_tsv,'FileType','text'); 
ntrials = height(trials);

% could also get tData.s and tData.fs from each trial..... audio recording
for itrial = 1:ntrials
    % load and tabulate trial timing
    load([dirs.src_trialdata, filesep, file_prepend, 'trial-', num2str(itrial), '.mat'])
    trials.t_go_on(itrial) = tData.timingTrial(1); % referrred to as TIME_GOSIGNAL_ACTUALLYSTART in FLVoice_Run
    trials.t_voice_on(itrial) = tData.timingTrial(2);  % referrred to as TIME_VOICE_START in FLVoice_Run

    %%%%%%% not yet sure what these times are
    % trials.t_stim(itrial) = tData.timeStim; 
    % trials.t_poststim(itrial) = tData.timePostStim;
    % trials.t_postonset(itrial) = tData.timePostOnset;
    % trials.t_prestim(itrial) = tData.timePreStim;
    % trials.t_voice_onset(itrial) = tData.voiceOnsetTime;

    % cut video trials

end