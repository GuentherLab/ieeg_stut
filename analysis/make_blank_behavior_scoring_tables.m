% script for generating tables for manual scoring of trials
% ... get behavioral data from beh folders for each task
% ... check whether these files alreaedy exist to avoid overwriting
%
%   table contains an option for 'stuttered'; intended to use 0 (unambiguous fluent), 1 (ambiguous), or 2 (unambiguous stuttered)
%`  ..... following jackson ea 2020 - doi 10.1044/2019_JSLHR-S-19-0173


 clear

[dirs, host] = set_paths_ieeg_stut(); 

op.num_run_digits = 2; % must match the value used during data acquisition; usually 2 digits
op.num_trials_digits = 3; % number of digits to include in trial number labels in filenames

runs = readtable([dirs.projrepo, filesep, 'ieeg_stut_runs.tsv'],'FileType','text'); % load table of runs from all subs to cut into trial clips
runs = runs(logical(runs.make_beh_scoring_table),:); % only make scoring sheets for runs for which this table variable is true
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
        
    if exist(beh_scoring_filepath)
         fprintf(['\n File already exists, not overwriting:\n       %s \n'], beh_scoring_filepath)
    elseif ~exist(beh_scoring_filepath)
        switch task
            case 'jackson20'
                trial_table_tsv = [dirs.src_task, filesep, file_prepend,'trials-words.tsv']; 
                trials = readtable(trial_table_tsv,'FileType','text'); 
            case 'irani23'
                load([dirs.src_task, filesep, file_prepend,'trials.mat'], 'trials')
            otherwise
                error('task not recognized')
        end
    
        ntrials = height(trials);
        nancol = nan(ntrials,1);
        celcol = cell(ntrials,1); 
        trials.stuttered = nancol;
        trials.unusable_trial = nancol;
        trials.notes = celcol; 

        writetable(trials,beh_scoring_filepath, 'FileType','text', 'Delimiter','tab')
    end



end