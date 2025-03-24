 %%% generate audio-video files for each trial
 % written for windows; ffmpeg path must be on the system path - see https://archive.ph/AQE03

 op.sub = 'pilot001'; 
 op.ses = 1; 
 op.run = 1; 
 op.task = 'jackson20'; 
 op.trialdur = 4; % duration of trial video clip; starts after green screen GO cue

%%
[dirs, host] = set_paths_ieeg_stut(); 

dirs.src_ses = [dirs.data, filesep, 'sub-',op.sub, filesep, 'ses-',num2str(op.ses)]; 
dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, op.task]; 
dirs.src_trialdata = [dirs.src_task, filesep, 'trialdata']; 
dirs.src_av = [dirs.src_ses, filesep, 'audio-video']; 
dirs.annot = [dirs.src_ses, filesep, 'annot']; 
recording_file_suffix = 'recording-ipad_physio.mp4'; 

file_prepend = ['sub-',op.sub, '_ses-',num2str(op.ses), '_task-',op.task, '_run-',num2str(op.run),  '_']; 
trial_table_tsv = [dirs.src_task, filesep, file_prepend,'trials-words.tsv']; 
run_subj_video_file = [dirs.src_av, filesep, file_prepend, recording_file_suffix]; % video file to chop up
landmarks_file = [dirs.annot, filesep, file_prepend,'landmarks.tsv'];
dirs.trial_video = [dirs.src_av, filesep, 'task-',op.task, '_run-',num2str(op.run), '_', getfname(recording_file_suffix), '_trials']; % store chopped up video here

% load files, make trials video dir
ldmks = readtable(landmarks_file,'FileType','text'); 
recording_file = [dirs.src_av, filesep, ldmks.file{string(ldmks.computer)=='recording'}]; 
mkdir(dirs.trial_video); 

trials = readtable(trial_table_tsv,'FileType','text'); 
ntrials = height(trials);

% sync
video_time_minus_stimcomp_time = ldmks.time(string(ldmks.computer)=='recording') - ldmks.time(string(ldmks.computer)=='stim'); 

% could also get tData.s and tData.fs from each trial..... audio recording
for itrial = 1:ntrials
    %%%%%%%% load and tabulate trial timing
    load([dirs.src_trialdata, filesep, file_prepend, 'trial-', num2str(itrial), '.mat'])
    trials.t_go_on(itrial) = tData.timingTrial(1); % referrred to as TIME_GOSIGNAL_ACTUALLYSTART in FLVoice_Run
    trials.t_voice_on(itrial) = tData.timingTrial(2);  % referrred to as TIME_VOICE_START in FLVoice_Run

    %%%%%%% not yet sure what these times mean
    % trials.t_stim(itrial) = tData.timeStim; 
    % trials.t_poststim(itrial) = tData.timePostStim;
    % trials.t_postonset(itrial) = tData.timePostOnset;
    % trials.t_prestim(itrial) = tData.timePreStim;
    % trials.t_voice_onset(itrial) = tData.voiceOnsetTime;

    %%%%%%%%% cut video trials
    % Calculate  timepoints
    time_trial_start =  trials.t_go_on(itrial) + video_time_minus_stimcomp_time; 
    time_trial_end = trials.t_go_on(itrial) + video_time_minus_stimcomp_time + op.trialdur;

    trial_video_filename = [dirs.trial_video, filesep, getfname(recording_file), '_trial-',num2str(itrial), '.avi']; 
       ffmpeg_command = sprintf(...
            'ffmpeg -y -i "%s" -ss %f -to %f -c copy "%s"', ... %%%%%%%% the -y flag will overwrite pre-existing trial files
            recording_file, time_trial_start, time_trial_end, trial_video_filename);

       [status, cmdout] = system(ffmpeg_command);
end

