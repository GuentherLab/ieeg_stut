function setup_subj_ieeg_stut_jackson2020(subjID)

% Write experiment desc text files for implementation of Jackson et al. 2020 stuttering elicitaiton protocol
% By Andrew Meier @ Guenther Lab, 2024

ntrials = 100; 

projpath = 'C:\ieeg_stut_data';

% stim_master_file = 'stim_master_dbsmulti.xlsx'; 
% stim_master = readtable(stim_master_file); 


%% familiarization
taskpath = fullfile(projpath, sprintf('sub-%s', subjID),sprintf('ses-%d', 1),'beh','jackson2020');
if ~isfolder(taskpath); mkdir(taskpath); end

go_stim_list = repmat({'green_screen_beep'}, ntrials, 1);

spath = fullfile(taskpath, sprintf('sub-%s_ses-1_run-1_task-jackson2020_desc-stimulus.txt',subjID));
writetable(table(go_stim_list),spath,'WriteVariableNames',false) % writetable rather than writecell for use w/ older matlab versions







end