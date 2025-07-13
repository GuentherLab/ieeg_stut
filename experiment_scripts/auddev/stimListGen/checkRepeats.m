function checkRepeats(StimListSet)
% function checkRepeats(StimListSet)
% Function to check for condition and stimuli repeats within a SAP stim list
% 
% INPUT
%           StimListSet     stim list stucture generated with SAPstimListGenerator
%
% Elaine Kearney, Jul 2021 (elaine-kearney.com)
% Matlab 2020b

%% create matrix of repeats
nStims = size(StimListSet.Stims, 1);
nConds = size(StimListSet.Condition, 2);
condReps = nan(nStims, nConds);
stimReps = nan(nStims, nConds);
for i=1:nConds
    for j = 1:nStims
        if j > 1
            condReps(j,i) = strcmp(StimListSet.Condition{j,i}, StimListSet.Condition{j-1,i});
            if ~strcmp(StimListSet.Stims{j,i}, 'yyy')
                stimReps(j,i) = strcmp(StimListSet.Stims{j,i}, StimListSet.Stims{j-1,i});
            end
        end
    end
end

% sum matrices of repeats to get total # repeats
sumCondR = nansum(nansum(condReps));
sumStimR = nansum(nansum(stimReps));

% print results to screen
if sumCondR > 0
    fprintf('%d condition repeat(s) found in list\n',sumCondR)
else 
    fprintf('No condition repeats found in list\n')
end

if sumStimR > 0
    fprintf('%d stimuli repeat(s) found in list\n',sumStimR)
else
    fprintf('No stimuli repeats found in list\n')
end