% generate a trial list of stimuli, following the protocol from:
%%% Irani et al., 2023 - https://doi.org/10.1016/j.jcomdis.2023.106353 
%
%%% 'op' struct contains fields:
% sub [string] = subject name.... no default
% ntrials [num] = total trials (this will also be the number of unique nonwords to pick)... default 100; Irani used 100 trials per block, 4 blocks per session
% allow_same_first_letter_within_pair [logical] = whether or not to allow the words within a pair to start with the same letter... default false, following Irani
% word_list_master_filename = .tsv file containing word list to draw from; must have headers 'word' and 'first letter'... default 'C:\docs\code\ieeg_stut\stimuli\irani23_word_list_master.tsv'


function [trials, stimops] = setup_subj_ieeg_stut_irani23(op)

field_default('op','ntrials',100);
field_default('op','allow_same_first_letter_within_pair',false); 
field_default('op','word_list_master_filename','C:\docs\code\ieeg_stut\stimuli\irani23_word_list_master.tsv');


word_master_list = readtable(op.word_list_master_filename,'FileType','text');
nmaster = height(word_master_list);
% % % % % % % word_master_list.used = false(nmaster,1); % to check off when a word is used
master_remain = word_master_list; % words that haven't been used yet

ntrials = op.ntrials;
cel1 = cell(ntrials,1); 
cel2 = cell(ntrials,2);
trials = table(cel2,'VariableNames',{'word'});
trials.first_letter = cel2; 
trials.fullstim = cell1; 


for itrial = 1:ntrials
    % get first word of this pair
    clear randind nremain 
    nremain = height(master_remain); 
    % master_remain = word_master_list(~word_master_list.used,:); 
    randind = randi(nremain);
    trials.word{itrial,1} = master_remain.word{randind}; 
    trials.first_letter{itrial,1} = master_remain.first_letter{randind}; 
    master_remain(randind,:) = []; % remove word now that it's been used

    % get second word of this pair
    clear randind nremain 
    nremain = height(master_remain); 
    if op.allow_same_first_letter_within_pair
        randind = randi(nremain);
    elseif ~op.allow_same_first_letter_within_pair
        duplicate_letter = true; % initialize to start the loop
        while duplicate_letter % pick new word if first and second word start with same letter
            randind = randi(nremain);
            duplicate_letter = trials.first_letter{itrial,1} == master_remain.first_letter{randind}; % check whether first and second word start with same letter
        end
    end
    trials.word{itrial,2} = master_remain.word{randind}; 
    trials.first_letter{itrial,2} = master_remain.first_letter{randind}; 
    master_remain(randind,:) = []; % remove word now that it's been used

    trials.fullstim{itrial} = [trials.word{itrial,1}, ' ', trials.word{itrial,2}]; 
end

stimops = op; 