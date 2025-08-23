 %%% generate audio-video files for each trial
 % written for windows; ffmpeg path must be on the system path - see https://archive.ph/AQE03
%
% before running this script, first run make_blank_annot_tables.m to create landmarks table, then fill out that table
% ..... for visual landmarks, may want to use video editor like OpenShot; use arrow keys to advance one frame at a time
% ..... for audio landmarks, enable 'waveform' property in openshot for the track, or use audacity with codecs

 clear

[dirs, host] = set_paths_ieeg_stut(); 

op.num_run_digits = 2; % must match the value used during data acquisition; usually 2 digits
op.num_trials_digits = 3; % number of digits to include in trial number labels in filenames

runs = readtable([dirs.projrepo, filesep, 'ieeg_stut_runs.tsv'],'FileType','text'); % load table of runs from all subs to cut into trial clips
runs = runs(logical(runs.cut_into_trials),:);
nrunrows = height(runs); 


for irun = 1:nrunrows
    sub = runs.subject{irun}
    ses = runs.session(irun); 
    task = runs.task{irun};
    taskrun = runs.run(irun); % run label within this subject / session / task
        runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], taskrun); % add zero padding
    recording_file_suffix = runs.suffix{irun};
    trialdur = runs.trialdur(irun);
    
    dirs.src_ses = [dirs.data, filesep, 'sub-',sub, filesep, 'ses-',num2str(ses)]; 
    dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, task]; 
    dirs.src_trialdata = [dirs.src_task, filesep, 'run-',runstring]; 
    dirs.src_av = [dirs.src_ses, filesep, 'audio-video']; 

    dirs.der_sub = [dirs.derivatives, filesep, 'sub-',sub];
    dirs.annot = [dirs.der_sub, filesep, 'annot']; 
    
    file_prepend = ['sub-',sub, '_ses-',num2str(ses), '_task-',task, '_run-',runstring,  '_']; 
    run_subj_video_file = [dirs.src_av, filesep, file_prepend, recording_file_suffix]; % video file to chop up
    landmarks_file = [dirs.annot, filesep, file_prepend,'landmarks.tsv'];
    dirs.trial_video = [dirs.der_sub, filesep, 'trial-videos', filesep, 'ses-',num2str(ses), '_task-',task, '_run-',runstring]; % store chopped up video here
    
    % load files, make trials video dir
    ldmks = readtable(landmarks_file,'FileType','text','Delimiter','tab'); 
    recording_file = [dirs.src_av, filesep, ldmks.file{string(ldmks.computer)=='recording'}]; 
    mkdir(dirs.trial_video); 
    
    switch task
        case {'jackson20','daf'}
            trial_table_tsv = [dirs.src_task, filesep, file_prepend,'trials.tsv']; % has stim plus timing data
            trial_table_words_tsv = [dirs.src_task, filesep, file_prepend,'trials-words.tsv']; % only contains stim
            if exist(trial_table_tsv,'file') % if there's trial tables file with more data, use that
                trials = readtable(trial_table_tsv,'FileType','text'); 
            else
                trials = readtable(trial_table_words_tsv,'FileType','text'); 
            end
        case 'irani23'
            load([dirs.src_task, filesep, file_prepend,'trials.mat'], 'trials')
        otherwise
            error('task not recognized')
    end

    ntrials = height(trials);
    
    % sync
    video_time_minus_stimcomp_time = ldmks.time(string(ldmks.computer)=='recording') - ldmks.time(string(ldmks.computer)=='stim'); 
    
    % for jackson: could also get tData.s and tData.fs from each trial..... audio recording
    for itrial = 1:ntrials
        %%%%%%%% load and tabulate trial timing
        switch task
            case {'jackson20','irani23'}
                trial_filename = [dirs.src_trialdata, filesep, file_prepend, 'trial-', num2str(itrial), '.mat']; 
                if ~exist(trial_filename,'file')
                    fprintf(['\n Missing trial file: %s \n'], trial_filename)
                elseif exist(trial_filename,'file') && strcmp(task,'jackson20')
                        load(trial_filename)
                        trials.t_go_on(itrial) = tData.timingTrial(1); % referred to as TIME_GOSIGNAL_ACTUALLYSTART in FLVoice_Run
                        trials.t_voice_on(itrial) = tData.timingTrial(2);  % referred to as TIME_VOICE_START in FLVoice_Run
                    
                        %%%%%%% not yet sure what these times mean
                        % trials.t_stim(itrial) = tData.timeStim; 
                        % trials.t_poststim(itrial) = tData.timePostStim;
                        % trials.t_postonset(itrial) = tData.timePostOnset;
                        % trials.t_prestim(itrial) = tData.timePreStim;
                        % trials.t_voice_onset(itrial) = tData.voiceOnsetTime;
                end
            case 'daf'
                trials.t_go_on(itrial) = trials.sentence_onset(itrial); % go cue = sentence appears
        end
        
        %%%%%%%%% cut video trials
        % Calculate  timepoints - both of these timepoints should already irani trialtable
        % time_trial_start =  trials.t_go_on(itrial) + video_time_minus_stimcomp_time; 
        time_trial_start =  trials.t_go_on(itrial) + video_time_minus_stimcomp_time; 
        time_trial_end = time_trial_start + trialdur;
    
        trial_video_filename = [dirs.trial_video, filesep, getfname(recording_file), '_trial-',...
            sprintf(['%0',num2str(op.num_trials_digits),'d'], itrial), '.avi']; % zero pad trial number

        % if reencode_video is turned on (recommended), running while memory is limited may result in losing video (getting audio only) in some output files
            %%%% might need to close browser while running.... this option is slower than running without re-encoding
        % if reencode_video is turned off, you may get A-V desync issues

        %%% in ffmpeg command, the -y flag will overwrite pre-existing trial files
        if runs.reencode_video(irun)

            % re-encode video to avoid A/V desync issues - this was a problem when cutting subs pilot01 through 05
            %%%% running while memory is limited may result in losing video and getting audio only in some trial videos
           ffmpeg_command = sprintf(...
             'ffmpeg -y -i "%s" -ss %f -to %f -map 0 -c:v libx264 -force_key_frames "expr:gte(t,0)" -c:a aac -avoid_negative_ts make_zero "%s"', ...
             recording_file, time_trial_start, time_trial_end, trial_video_filename);

        else % may produce desync issues
           ffmpeg_command = sprintf(...
                'ffmpeg -y -i "%s" -ss %f -to %f -c copy -metadata:s:v rotate=0  "%s"', ... 
                recording_file, time_trial_start, time_trial_end, trial_video_filename);
        end

        [status, cmdout] = system(ffmpeg_command);
    end
end






