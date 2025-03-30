%%% analyze jackson protocol, irani protocol, and Emotional Reactivity Scale in pilot subjects
% for Oxford Disfluency Conference abstract
% 
%  assume only 1 run for each task will be analyzed per subject


 clear

[dirs, host] = set_paths_ieeg_stut(); 

op.num_run_digits = 2; % must match the value used during data acquisition; usually 2 digits
op.num_trials_digits = 3; 

runs = readtable([dirs.projrepo, filesep, 'ieeg_stut_runs.tsv'],'FileType','text'); % load table of runs from all subs to cut into trial clips
runs = runs(logical(runs.analyze),:); % only analyze runs for which this table variable is true
nrunrows = height(runs); 

subs = table(unique(runs.subject),'VariableNames',{'sub'},'RowNames',unique(runs.subject));
nsubs = height(subs);
subnan = nan(nsubs,1);
subs.st_prop_jackson = subnan;
subs.st_prop_irani = subnan;

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
    trials =  readtable(beh_scoring_filepath,'FileType','text','Delimiter','tab');
    trials = trials(isnan(trials.unusable_trial) | trials.unusable_trial==0,:);

    % some trials not yet scored may be indicated w/ nans, so use nanmean (these are not necessarily unusable trials)
    switch task
        case 'jackson20'
            subs.st_prop_jackson(sub) = nanmean(trials.stuttered) / 2;
        case 'irani23'
            trials.stuttered_trial = max([trials.stuttered_1, trials.stuttered_2], [], 2); % maximum 'amount' (non-ambiguity) of stuterring across both syls in a trial
             subs.st_prop_irani(sub) = nanmean(trials.stuttered_trial) / 2;;
        otherwise
            error('task not recognized')
    end
end

% ERS
subs.ers = subnan;

%%% getting error when trying to run readtable on these .tsv files
% for isub = [1 2 3 5]; % sub 4 missing data for now
%     sub = subs.sub{isub};
%     ers_filepath = [dirs.data, filesep, 'sub-',sub, filesep, 'ses-2', filesep, 'sub-',sub, '_ERS.tsv',]
%     ers_tab = readtable(ers_filepath, 'FileType','text', 'Delimiter','tab');
% end

mean_jackson = mean(subs.st_prop_jackson)
    sem_jackson = std(subs.st_prop_jackson) / sqrt(nsubs)
mean_irani = mean(subs.st_prop_irani)
    sem_irani = std(subs.st_prop_irani) / sqrt(nsubs)    
[~, p_irani_vs_jackson] = ttest(subs.st_prop_jackson, subs.st_prop_irani)

subs.ers(1) = 1.28571428571429;
subs.ers(2) = 1.47619047619048; 
subs.ers(3) = 2.0952380952381; 
subs.ers(5) = 2.15; 

subs.irani_jackson_ratio = subs.st_prop_irani ./ subs.st_prop_jackson; 
subs.irani_jackson_dif = subs.st_prop_irani - subs.st_prop_jackson;
    
subs = subs([1 2 3 5],:); % sub 4 missing data for now

[r_ers_irani_jackson_ratio, p_ers_irani_jackson_ratio] = corrcoef(subs.ers, subs.irani_jackson_ratio)
[r_ers_irani_jackson_dif, p_ers_irani_jackson_dif] = corrcoef(subs.ers, subs.irani_jackson_dif)


