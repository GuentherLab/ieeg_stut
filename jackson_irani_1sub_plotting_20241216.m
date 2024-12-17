% plot behavioral results from subject 

%% jackson20

 op.sub = 'pilot001'; 
 op.ses = 1; 
 op.run = 1; 
 op.task = 'jackson20'; 

%
[dirs, host] = set_paths_ieeg_stut(); 

dirs.src_ses = [dirs.data, filesep, 'sub-',op.sub, filesep, 'ses-',num2str(op.ses)]; 
dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, op.task]; 
dirs.src_trialdata = [dirs.src_task, filesep, 'trialdata']; 
dirs.src_av = [dirs.src_ses, filesep, 'audio-video']; 
dirs.annot = [dirs.src_ses, filesep, 'annot']; 

file_prepend = ['sub-',op.sub, '_ses-',num2str(op.ses), '_task-',op.task, '_run-',num2str(op.run),  '_']; 
trial_table_tsv = [dirs.annot, filesep, file_prepend,'scoring.tsv']; 

trials = readtable(trial_table_tsv,'FileType','text'); 
trials = trials(~[trials.unusable_trial==1],:);
trials.anticipated = logical(trials.anticipated);
ntrials = height(trials);

close all
hfig = figure('Color','w')

subplot(1,2,1)
hbar = bar([mean(trials.sld(trials.anticipated)), 1-mean(trials.sld(trials.anticipated)); ...
            mean(trials.sld(~trials.anticipated)), 1-mean(trials.sld(~trials.anticipated))]);
box off

hax = gca;
hax.XTickLabels = {'Anticipated','Not Anticipated'}
hleg = legend('Stuttering','Fluent');
ylabel('Proportion of trials')
title('Jackson 2020 protocol')


subplot(1,2,2)
hbar = bar([0, 1; 0.02, 0.98]);
box off

hax = gca;
hax.XTickLabels = {'Word-Go','Cue-Word'}
hleg = legend('Stuttering','Fluent');
ylabel('Proportion of trials')
title('Irani 2023 protocol')