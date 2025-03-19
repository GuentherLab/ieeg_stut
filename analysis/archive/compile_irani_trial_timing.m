 %%% compile a single trial table from individual trial timing files
 % this script shouldn't be necessary in the future, because we are now saving the full trial table after each trial
% ..... in this case, the full table with trial timing did not get saved if the run was ended early (only individual trial files)


 op.sub = 'pilot001'; 
 op.ses = 2; 
 op.run = 2; % need to change this to do the compiling on multiple incomplete runs
 op.task = 'irani23'; 


 %%
 num_run_digits = 2; 

 [dirs] = set_paths_ieeg_stut();

sesstr = ['ses-',num2str(op.ses)];
runstr = ['run-',num2str(op.run)]; 
runstr_pad = ['run-',num2str(op.run, ['%0', num2str(num_run_digits), 'd'])];



 sesdir = [dirs.data, filesep, 'sub-',op.sub, filesep, sesstr, filesep, 'beh', filesep, op.task]; 
 rundir = [sesdir, filesep, runstr_pad]; 
trial_file_str = ['sub-',op.sub, '_', sesstr, '_', runstr, '_task-', op.task, 'trial-']; % future versions may reverse run/task order to match table file
table_filename = [sesdir, filesep, 'sub-',op.sub, '_', sesstr, '_task-', op.task, '_', runstr, '_trials.mat']; 

copyfile(table_filename, strrep(table_filename,'.mat','_orig.mat')); % back up original trial file

 dd = struct2table(dir(rundir)); dd = dd.name; 
trial_file_list = dd(contains(dd,'_trial-')); 
ntrials = length(trial_file_list);

 % load(table_filename,'trials')
 % 
 % trials = trials(1:ntrials,:);

 trialnums = cellfun(@(x2)str2num(x2{1}),cellfun(@(x)regexp(x, 'trial-(\d+)\.mat', 'tokens'),trial_file_list)); 

 trials = table; 
 for itrial = 1:ntrials
     trial_fname = [rundir, filesep, trial_file_list{itrial}];
     load(trial_fname, 'trialdat')
     trials = [trials; trialdat];
 end

 trials.trialnum = trialnums; 
 trials = sortrows(trials,'trialnum'); 

save(table_filename, 'trials','-append')
