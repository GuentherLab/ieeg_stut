function StimListSet = stimListGeneratorAdaptive(name)
%
% Generates a stimulus list for running adaptive experiments
%
% Guenther Lab, Boston University
% Written by Alexander Acosta, August 2023

% setup

if nargin > 1, error('Dont forget to name your stim list!'), end

[dirs, ~] = setDirs('AudDev');
StimListSet = struct();

%% Take user inputs via dialogue box
prompt1 = {'Max Perturbation Magnitude (cents/F1F2 magnitude)', 'Baseline trials', ...
    'Ramp trials','Hold trials', 'After-effect trials', 'Direction', ...
    'Angle (radians) (formants only)', 'Stimuli?','Repeat Stimuli How Many Times?',...
    'Maintain Stimuli Order?'};
pertType = questdlg('What type of perturbation would you like to implement?', ...
    'Perturbation Type', 'formant', 'pitch', 'pitch');
switch pertType
    case 'formant'
        defaultInput = {'.30', '45', '45', '45', '45', 'Up', '0', ...
            'bed', '0', 'No'};
    case 'pitch'
        defaultInput = {'100', '45', '45', '45', '45', 'Up', '0', ...
            'bed','0','No'};
end
dlgtitle = 'aud-adaptive Task Additional Parameters';
runPrompt1 = inputdlg(prompt1, dlgtitle, [1 50], defaultInput);
switch pertType
    case 'formant'
        if str2double(prompt1{1}) > 1 || str2double(prompt1{1}) < -1
            error('Formant perturbation magnitude should not exceed 1 or be less than -1.')
        end
    case 'pitch'
        if str2double(prompt1{1}) > 3000 || str2double(prompt1{1}) < 0
            error('Please reconsider your maximum pitch perturbation magnitude.')
        end
end

%% Send user inputs to discrete variables

StimListSet.magnitude = str2num(runPrompt1{1});
baseline = str2num(runPrompt1{2});
ramp = str2num(runPrompt1{3});
hold = str2num(runPrompt1{4});
afterEffect = str2num(runPrompt1{5});
StimListSet.pertDirect = runPrompt1{6};
StimListSet.pertAngle = runPrompt1{7};

%Formation of stimuli list
        if contains(runPrompt1{8},',')
            runPrompt1{8} = strrep(runPrompt1{8}, ' ', '');
            stimList = strsplit(runPrompt1{8}, ',').';
        else
            stimList = strsplit(runPrompt1{8}, ' ').';
        end
        nStims = size(stimList, 1);

repeatStims = str2num(runPrompt1{9}); nStimsPresent = repeatStims +1; % number of times reach stimulus is presented consecutively. makes things easier
if strcmp(runPrompt1{10}, 'yes') || strcmp(runPrompt1{10}, 'Yes'), maintainOrder = 1; else maintainOrder = 0; end

numTrials = baseline + ramp + hold + afterEffect;

%Check to make sure stimuli fit evenly into entire run as well as
%into each phase
if mod(numTrials, nStims) ~= 0
    error('Number of stimuli does not fit in number of trials.')
elseif mod(baseline, nStims) ~= 0
    error('Number of stimuli does not fit in number of trials of baseline phase.')
elseif mod(ramp, nStims) ~= 0
    error('Number of stimuli does not fit in number of trials of ramp phase.')
elseif mod(hold, nStims) ~= 0
    error('Number of stimuli does not fit in number of trials of baseline phase.')
elseif mod(afterEffect, nStims) ~= 0
    error('Number of stimuli does not fit in number of trials of baseline phase.')
end

if repeatStims ~= 0
    if mod(numTrials, (nStims * (nStimsPresent)))
        error('Number of trials is not divisible by product of number of stimuli and stimuli repetitions.')
    end
end

%% Create vectors of each trial's data

StimListSet.CondLabel = {};
StimListSet.trialPhases = {};
StimListSet.trialMagnitudes = [];
adaptiveRamp = linspace(0, 1, ramp+1);

switch pertType
    case 'pitch'
        switch StimListSet.pertDirect
            case 'Up', conditionOptions = {'U0', 'N0'};
            case 'Down', conditionOptions = {'D0', 'N0'};
            case 'Control', conditionOptions = {'N0', 'N0'};
        end
    case 'formant'
        switch StimListSet.pertDirect
            case 'Up',conditionOptions = {'U1', 'N1'};
            case 'Down',conditionOptions = {'D1', 'N1'};
            case 'Control',conditionOptions = {'N1', 'N1'};
        end
end

%conditions and magnitudes for each phase
for i = (1:baseline)
    StimListSet.CondLabel = cat(1,StimListSet.CondLabel,conditionOptions(1,2));
    StimListSet.trialPhases = cat(1,StimListSet.trialPhases,{'baseline'});
    StimListSet.trialMagnitudes = cat(1,StimListSet.trialMagnitudes,0);
end

for i = (1:ramp)
    StimListSet.CondLabel = cat(1,StimListSet.CondLabel,conditionOptions(1,1));
    StimListSet.trialPhases = cat(1,StimListSet.trialPhases,{'ramp'});
    StimListSet.trialMagnitudes = cat(1,StimListSet.trialMagnitudes,adaptiveRamp(i+1));
end

for i = (1:hold)
    StimListSet.CondLabel = cat(1,StimListSet.CondLabel,conditionOptions(1,1));
    StimListSet.trialPhases = cat(1,StimListSet.trialPhases,{'hold'});
    StimListSet.trialMagnitudes = cat(1,StimListSet.trialMagnitudes,1);
end

for i = (1:afterEffect)
    StimListSet.CondLabel = cat(1,StimListSet.CondLabel,conditionOptions(1,2));
    StimListSet.trialPhases = cat(1,StimListSet.trialPhases,{'after-effect'});
    StimListSet.trialMagnitudes = cat(1,StimListSet.trialMagnitudes,0);
end

% Order stimuli
if maintainOrder
    StimListSet.Stims = {};
    if repeatStims==0 
        for i = 1:(numTrials/nStims), StimListSet.Stims = cat(1,StimListSet.Stims, stimList); end
    else
        stimNameNumM = zeros(nStims * (nStimsPresent),1); stimNameNum = []; % Microlist for concatenation into full list; full list
        for i = 1:nStims
            starting = 1+((nStimsPresent)*(i-1)); ending = nStimsPresent*i;
            stimNameNumM(starting:ending) = i;
        end
        for i = 1:(numTrials/(nStims*nStimsPresent)), stimNameNum = cat(1,stimNameNum,stimNameNumM); end % cat stimnameM as many times as needed to create full list
        StimListSet.Stims = stimList(stimNameNum);
    end
else
    trialCounter = 0;
    stimNameNum = zeros(numTrials,1);
    if repeatStims==0
        for i = 1:(numTrials/nStims)
            order = randperm(nStims); % Generate in groups of numStims
            for j = 1:nStims
                trialCounter = trialCounter + 1;
                stimNameNum(trialCounter) = order(j);
                if j == 2 && trialCounter ~= 2 % Check for repeats
                    if stimNameNum(trialCounter-1) == stimNameNum(trialCounter-2)
                        stimNameNum([trialCounter-1 trialCounter]) = stimNameNum([trialCounter trialCounter-1]); % Swap if repeating
                    end
                end
            end
        end
    else
        n = numTrials/(nStims * nStimsPresent); % number times each stimulus is presented, excluding repeats
        m = zeros(n * nStims,1); % List of stimulus presentations excluding repeats
        
        % Generate micro stim list
        for i = 1:n
            order = randperm(nStims); % Generate in groups of numStims
            for j = 1:nStims
                trialCounter = trialCounter + 1; % trial counter WITHOUT REPEATS!!! 
                m(trialCounter) = order(j);
                if j == 2 && trialCounter ~= 2 % Check for repeats
                    if m(trialCounter-1) == m(trialCounter-2)
                        m([trialCounter-1 trialCounter]) = m([trialCounter trialCounter-1]); % Swap if repeating
                        stimNameNum(1+(nStimsPresent * (trialCounter-2)):(1+(nStimsPresent * (trialCounter-2))+repeatStims)) = m(trialCounter-1); % rectify stimNameNum
                    end
                end
                stimNameNum(1+(nStimsPresent * (trialCounter-1)):(1+(nStimsPresent * (trialCounter-1))+repeatStims)) = m(trialCounter); % Insert every stimulus's presentation
            end
        end
    end
    StimListSet.Stims = stimList(stimNameNum);
end

%% save stim list

save(fullfile(dirs.stim, sprintf('%s_aud-adaptive.mat',name)), 'StimListSet');

end