% script for generating tables for manual scoring of trials
% ... get behavioral data from beh folders for each task
% ... check whether these files already exist to avoid overwriting
%
% also make landmarks table for syncing timing across files
%
%   table contains an option for 'stuttered'; intended to use 0 (unambiguous fluent), 1 (ambiguous), or 2 (unambiguous stuttered)
%`  ..... following jackson ea 2020 - doi 10.1044/2019_JSLHR-S-19-0173


 clear

[dirs, host] = set_paths_ieeg_stut(); 

op.num_run_digits = 2; % must match the value used during data acquisition; usually 2 digits
op.num_trials_digits = 3; % number of digits to include in trial number labels in filenames

runs = readtable([dirs.projrepo, filesep, 'ieeg_stut_runs.tsv'],'FileType','text'); % load table of runs from all subs to cut into trial clips
runs = runs(logical(runs.make_annot_tables),:); % only make scoring sheets for runs for which this table variable is true
nrunrows = height(runs); 


for irun = 1:nrunrows
    sub = runs.subject{irun};
    ses = runs.session(irun); 
    task = runs.task{irun};
    taskrun = runs.run(irun); % run label within this subject / session / task
        runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], taskrun); % add zero padding

    dirs.src_ses = [dirs.data, filesep, 'sub-',sub, filesep, 'ses-',num2str(ses)]; 
    dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, task]; 
    dirs.src_trialdata = [dirs.src_task, filesep, 'run-',runstring]; 
    dirs.der_sub = [dirs.derivatives, filesep, 'sub-',sub];
    dirs.annot = [dirs.der_sub, filesep, 'annot']; 

    file_prepend = ['sub-',sub, '_ses-',num2str(ses), '_task-',task, '_run-',runstring,  '_']; 
    beh_scoring_filepath = [dirs.annot, filesep, file_prepend, 'beh_scoring.tsv']; 
    landmarks_filepath = [dirs.annot, filesep, file_prepend, 'landmarks.tsv']; 

        
    if ~exist(dirs.der_sub,'dir')
        mkdir(dirs.der_sub)
    end
    if ~exist(dirs.annot,'dir')
        mkdir(dirs.annot)
    end

%%     make landmarks files
    if exist(landmarks_filepath)
         fprintf(['\n Landmarks scoring file already exists, not overwriting:\n       %s \n'], beh_scoring_filepath)
    elseif ~exist(landmarks_filepath)
        landmarks_blank_table = table([inf; inf],{'recording';'stim'},{'FILL IN AUDIO/VIDEO FILE HERE';'FILL IN BEHAVIORAL TIMING FILE HERE'},{'DESCRIBE TIMEPOINT HERE';'DESCRIBE TIMEPOINT HERE'},...
            'VariableNames',{'time','computer','file','description'}); 
        writetable(landmarks_blank_table,landmarks_filepath, 'FileType','text', 'Delimiter','tab')
    end


    %% make beh scoring files
    if exist(beh_scoring_filepath)
         fprintf(['\n Behavior scoring file already exists, not overwriting:\n       %s \n'], beh_scoring_filepath)
    elseif ~exist(beh_scoring_filepath)
        switch task
            case 'jackson20'
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
        nancol = nan(ntrials,1);
        celcol = cell(ntrials,1); 
        trials.unusable_trial = nancol;
        trials.notes = celcol; 
        trials.trialnum = [1:ntrials]'; 

        switch task
            case 'jackson20'
                trials.stuttered = nancol;
                if any(contains(trials.Properties.VariableNames,'word'))
                    firstvars = {'question','word','stuttered'}; 
                elseif any(contains(trials.Properties.VariableNames,'answer'))
                    firstvars = {'question','answer','stuttered'}; 
                else
                    firstvars = {'question','stuttered'}; 
                end
            case 'irani23'
                trials.stuttered_1 = nancol;
                trials.stuttered_2 = nancol;
                firstvars = {'word','stuttered_1','stuttered_2'}; 
        end

        trials = movevars(trials,{'trialnum',firstvars{:},'unusable_trial','notes'},'Before',1);

        writetable(trials,beh_scoring_filepath, 'FileType','text', 'Delimiter','tab')
    end


end