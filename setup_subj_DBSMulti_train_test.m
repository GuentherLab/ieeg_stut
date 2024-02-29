function setup_subj_DBSMulti_train_test(subjID, subj_n_syls)

% Write experiment desc text files for Train and Test phases of SEQ experiment - DBS-Multisyllabic branch.
% By Andrew Meier @ Guenther Lab, 2023


ntrials_train = 100; % total trials in each training phase (divided between trained stim)
ntrials_test = 150; % total trials in each testing phase (divided between trained stim and test stim)

projpath = 'C:\dbsmulti';

stim_master_file = 'stim_master_dbsmulti.xlsx'; 
stim_master = readtable(stim_master_file); 

%% train a
taskpath = fullfile(projpath, sprintf('sub-%s', subjID),sprintf('ses-%d', 1),'beh','train-a');
if ~isfolder(taskpath); mkdir(taskpath); end

stim_thisphase = stim_master(strcmp(stim_master.stim_group,'test_a'),:); 

% select the stim set with the number of syllables selected for this subject
stim_thisphase = stim_thisphase(stim_thisphase.n_syllables==subj_n_syls,:); 

trainwords_1_tab = repmat(stim_thisphase,ntrials_train,1);
trainwords_1_tab = trainwords_1_tab(1:ntrials_train,:); 
trainwords_1_tab = trainwords_1_tab(randperm(ntrials_train),:); % shuffle
spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-train-a_trials.csv',subjID)); 
writetable(trainwords_1_tab,spath) % save table with condition labels

trainwords_1 = trainwords_1_tab.name; 

spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-train-a_desc-stimulus.txt',subjID));
writetable(table(trainwords_1),spath,'WriteVariableNames',false) % writetable rather than writecell for use w/ older matlab versions

%% train b
taskpath = fullfile(projpath, sprintf('sub-%s', subjID),sprintf('ses-%d', 1),'beh','train-b');
if ~isfolder(taskpath); mkdir(taskpath); end

stim_thisphase = stim_master(strcmp(stim_master.stim_group,'test_b'),:); 


% select the stim set with the number of syllables selected for this subject
stim_thisphase = stim_thisphase(stim_thisphase.n_syllables==subj_n_syls,:); 

trainwords_2_tab = repmat(stim_thisphase,ntrials_train,1);
trainwords_2_tab = trainwords_2_tab(1:ntrials_train,:); 
trainwords_2_tab = trainwords_2_tab(randperm(ntrials_train),:); % shuffle
spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-train-b_trials.csv',subjID)); 
writetable(trainwords_2_tab,spath) % save table with condition labels

trainwords_2 = trainwords_2_tab.name; 

spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-train-b_desc-stimulus.txt',subjID));
writetable(table(trainwords_2),spath,'WriteVariableNames',false) % writetable rather than writecell for use w/ older matlab versions

%% test
taskpath = fullfile(projpath, sprintf('sub-%s', subjID),sprintf('ses-%d', 1),'beh','test');
if ~isfolder(taskpath); mkdir(taskpath); end

stimrowmatch = strcmp(stim_master.stim_group,'test_a') | strcmp(stim_master.stim_group,'test_b') | strcmp(stim_master.stim_group,'test_novel'); 
stim_thisphase = stim_master(stimrowmatch,:); 

% select the stim set with the number of syllables selected for this subject
stim_thisphase = stim_thisphase(stim_thisphase.n_syllables==subj_n_syls,:); 

testwords_tab = repmat(stim_thisphase,ntrials_test,1);
testwords_tab = testwords_tab(1:ntrials_test,:); 
testwords_tab = testwords_tab(randperm(ntrials_test),:); % shuffle
spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-test_trials.csv',subjID)); 
writetable(table(testwords_tab),spath,'WriteVariableNames',false) % writetable rather than writecell for use w/ older matlab versions

testwords = testwords_tab.name; 
spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-test_desc-stimulus.txt',subjID));
writecell(testwords,spath)

end