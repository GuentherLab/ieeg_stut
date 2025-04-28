function setup_subj_ieeg_stut_jackson20(subjID)
% 
% Write experiment desc text files for implementation of Jackson et al. 2020 stuttering elicitaiton protocol
% By Andrew Meier @ Guenther Lab, 2024
%%%% you must already have a list of anticipated/unanticipated words 
%%%% ... format into tsv with 'anticipated' column (logical) and 'word' column (text)
%
% to generated a dummy list, can use the following ChatGPT prompt:.....
%    ..."generate a list of 10 words that are likely to elicit stuttering and a list of 10 words that are not likely to elicit stuttering" 

op.ses = 2; 
op.run = 1; % need to add overwrite protection/checking

op.repetitions_per_word = 2; 
% op.repetitions_per_word = 1; % use for remote session

op.shuffle_list = 1;
% op.shuffle_list = 0;

op.num_run_digits = 2; % number of digits to include in run number labels in filenames

%% should change paths so that they are all determined by set_paths_ieeg_stut

projpath = 'C:\ieeg_stut';

% stim_master_file = 'stim_master_dbsmulti.xlsx'; 
% stim_master = readtable(stim_master_file); 

runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], op.run); % add zero padding

taskpath = fullfile(projpath, sprintf('sub-%s', subjID),sprintf('ses-%d', op.ses),'beh','jackson20');
if ~isfolder(taskpath); mkdir(taskpath); end

% the following text file must already have been created and placed in taskpath
unique_words_file = fullfile(taskpath, sprintf('sub-%s_ses-%d_task-jackson20_run-%s_word-list.tsv',subjID,op.ses,runstring));
unique_words = readtable(unique_words_file,'FileType','text');
trials_words = repmat(unique_words, op.repetitions_per_word, 1); % copy each word repetitions_per_word times
ntrials = height(trials_words); 

if op.shuffle_list
    trials_words = trials_words(randperm(ntrials), :); % shuffle
end

trials_words_save_path = fullfile(taskpath, sprintf('sub-%s_ses-%d_run-%s_task-jackson20_trials-words.tsv',subjID,op.ses,runstring));
writetable(trials_words,trials_words_save_path, 'FileType','text', 'Delimiter','tab') % 

% save visual stim list [all green screens]
go_stim_list = repmat({'green_screen_beep'}, ntrials, 1);
stim_save_path = fullfile(taskpath, sprintf('sub-%s_ses-%d_run-%s_task-jackson20_desc-stimulus.txt',subjID,op.ses,runstring));
writetable(table(go_stim_list),stim_save_path,'WriteVariableNames',false) % writetable rather than writecell for use w/ older matlab versions







end