function StimListSet = stimListGenerator(task, stims, conds, nTrials, nRuns, outputFile)
% This function is used to generate pseudo-randomized stimulus lists with no condition or stimulus repetitions. 
% The stimuli are counter-balanced across conditions. 
% The function also generates an accompanying practice list with one trial per condition.
%
% INPUTS    task        character array: 'aud' or 'som' representing auditory or somatosensory experiment
%           stims       cell array: list of stimuli (if empty, defaults to 5 beC words, e.g., bed, beck)
%           conds       cell array: list of conditions (if empty, defaults to
%                           aud: {'Base','N0','N1','U0','U1','D0','D1'}
%                           som: {'Base','J','L','Js','Ls','S'}
%           nTrials     1 x no. conds vector: each element specifies number of trials per condition, e.g., [5, 5, 5]
%           nRuns       integer: number of runs to generate
%           outputFile  output file name
%
% OUTPUTS   Output stim list file saved to:
%           /AudDev/code/experiment/stimLists/[outputFile]_[task].mat
%           /AudDev/code/experiment/stimLists/[outputFile]_practice_[task].mat
%
% NOTES     A min of 3 conditions are required for randomization
%           The no. of trials per cond must be a multiple of the number of stimuli
%           Use 'Base' OR 'J' OR 'L' to indicate baseline condition; these trials will
%           automatically be assigned 'yyy' as the stimulus
%
% e.g.      Generate stim list for auditory experiment, specifying stimuli and conditions
%           stimListGenerator('aud',{'bed', 'beck'},{'U1','D1','N1'},[10,10,10],3,'StimList')
%
%           Generate stim list for somatosensory experiment, using default stimuli and conditions
%           stimListGenerator('som',{},{},[10,10,10,10,10,10],4,'StimList')
%
% Devised from Jason's 'cond_seq_generatorSAP.m' script,
% revised / edited by Riccardo Falsini (rfalsini@bu.edu) & Elaine Kearney (elaine-kearney.com)
%
%% setup and check validity of inputs
dirs = setDirs('AudDev');

if strcmp(task, {'aud', 'som'}) == 0
    error('Task input not recognized: Must be ''aud'' (auditory) or ''som'' (somatosensory)')
end

if isempty(stims)
    stims = {'bed','bet','beg','beck','ben'};
elseif iscell(stims) == 0
    error('Stims input must be a cell array, e.g., {''bed'', ''beck'', ''bet''}')
end
nStims = numel(stims);

if isempty(conds)
    if strcmp(task, 'aud')
        conds = {'Base','N0','N1','U0','U1','D0','D1'};
    elseif strcmp(task, 'som')
        conds = {'Base','J','L','Js','Ls','S'};
    end
elseif iscell(conds) == 0
    error('Conds input must be a cell array, e.g., {''U1'', ''N1'', ''D1''}')
elseif numel(conds) < 3
    error('A minimum of 3 conditions are required for randomization without repeats')
elseif sum(strcmp(conds, 'Base')) || sum(strcmp(conds, 'J')) || sum(strcmp(conds, 'L'))
    fprintf('\n=================\n\nAll baseline (''Base'', ''J'', ''L'') trials will be assigned ''yyy'' as the stimulus\n\n=================\n')
end
nConds = numel(conds);

baseIdx = [];
if sum(strcmp(conds, 'Base'))
    baseIdx = vertcat(baseIdx, find(strcmp(conds, 'Base')));
end
if sum(strcmp(conds, 'J'))
    baseIdx = vertcat(baseIdx, find(strcmp(conds, 'J')));
end
if sum(strcmp(conds, 'L'))
    baseIdx = vertcat(baseIdx, find(strcmp(conds, 'L')));
end

if length(nTrials)~=nConds
    error('Number of elements in nTrials must be equal to number of conditions')
elseif sum(mod(nTrials,nStims))~=0
    error('Values of nTrials must be divisible by the number of stimuli')
end
totalNtrials = sum(nTrials);

%% Generate Condition Order (with no repeats)

% initialize structure
StimLists = struct;
StimLists.Condition = [];
StimLists.CondLabel = [];
StimLists.Stims = [];

% set up condition letters for randomization
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
labels = alphabet(1:nConds);
for i = 1:nConds
    cellLabels{i} = labels(i);
end
condlabels = char(labels(1:nConds).*(nTrials~=0)); % exclude conditions with nTrials = 0
condlabels(nTrials==0) = '0';

% max # of consecutive repeats allowed in sequence of conditions
maxrepeats=1; 

% create unrandomized string of labels (e.g. [AAAAABBBB])
cstring=[];
for i = 1:nConds
    cstring=[cstring, repmat(condlabels(i),1,nTrials(i))];
end

for curRun = 1:nRuns
    
    fprintf('\n=================\n\nRun %d\n\n', curRun);
    
    % initialize following variables
    runConds=[];
    multiRepCount=0;
    
    % loop until get nruns with no repetitions
    while size(runConds,1)<1
        
        cidx = randperm(totalNtrials); %randomized run list indices
        cstringrand=cstring(cidx); %randomized order of condition
        
        % determine number of consecutive repetitions in randomized stim list
        cdiffs=[true, diff(cstringrand) ~= 0, true];
        crepeats=diff(find(cdiffs));
        
        if max(crepeats)<maxrepeats+1
            runConds=[runConds;cstringrand];
        else
            multiRepCount=multiRepCount+1; % unnecessary variable that keeps track
            % of runs tossed out due to repeats
            %if mod(multiRepCount, 100000 ) == 0 % uncomment to check if this section is hannging
            %    disp(multiRepCount)
            %end
        end
    end
    
    % Turn conditions order into arrays and store
    % Converting to cell array for easier indexing later
    cellCondRun = cell(1,totalNtrials);
    for i = 1:totalNtrials
        cellCondRun{i} = runConds(i);
    end
    
    % Generating 'labelled' version of the sequence
    runCondLabels = cell(1,totalNtrials);
    for i = 1:totalNtrials
        cond = runConds(i);
        idx = strcmp(cellLabels, cond);
        runCondLabels{i} = conds{idx};
    end
    
    StimLists.Condition = [StimLists.Condition, cellCondRun'];
    StimLists.CondLabel = [StimLists.CondLabel, runCondLabels'];
    
    disp('Condition List Generated')
    
    %% Generate stimuli
    % Use condition order to create corresponding stim list
    % this section will likely be re-run several times due to its
    % reliance on random chance (this occurs automatically)
    
    % Setting up stims for different cases
    stimCounts = zeros(nConds,nStims); % each col is a different stim, each row is a condition
    maxCounts = nTrials ./ nStims; % Array of maximum number of repititions for a stimulus+condition pair
    
    disp('Starting Stim List Generation')
    stimRun = cell(1,totalNtrials); % pre-allocating
    done = 0; % successful completition flag
    i = 1;
    retry = 0;
    while done == 0
        while i <(totalNtrials+1) % for each condition in the sequence
            stimInserted = 0;
            reps = 0;
            
            while stimInserted == 0
                if reps == 100 % loop hangs due to not being able to satisfy conditions
                    fprintf('On index %d: ', i);
                    disp(['Was not able to satisfy all stimuli conditions ' ...
                        'for this sequence, rerunning stimuli generation for this run']);
                    i = 0;
                    stimInserted = 1;
                    % Set up counters for each condition to ensure even distribution of stims
                    stimCounts = zeros(nConds,nStims);
                    retry = retry + 1;
                    continue
                end
                
                currCond = runConds(i);
                if i == 1 || nStims == 1 % for first instance or when only 1 stim, randomly choose stim among all
                    stimPick = stims{randi(nStims)};
                else % for subsequent cases, previous stim will be excluded from stim choice
                    prevStim = stimRun{i-1};
                    prevStimIdx = strcmp(prevStim, stims);
                    candStims = stims(~prevStimIdx);  % candidate stims, did not occur on previous trial
                    stimPick = candStims{randi(numel(candStims))};   % randomly select from candidate stims
                end
                
                labelIdx = find(currCond == labels); % find index of the current label in labels vector (e.g. A = 1 = 'yyy', B = 2 = 'bed')
                if sum(labelIdx == baseIdx) % baseline = 'yyy'
                    if stimCounts(labelIdx,:) < nTrials(labelIdx)
                        stimCounts(labelIdx,:) = stimCounts(labelIdx,:) + 1;
                        stimRun{i} = 'yyy';
                        stimInserted = 1;
                    end
                else
                    temp = ... % call function
                        increase_cond_stim_counter(stimCounts(labelIdx,:),maxCounts(labelIdx),stimPick,stims);
                    if ~isempty(temp{2}) % record if it was not above the maxCount for that stimulus+condition pair
                        stimCounts(labelIdx,:) = temp{1};
                        stimRun{i} = temp{2};
                        stimInserted = temp{3};
                        if i > 1 && strcmp(stimRun{i}, stimRun{i-1}) && nStims > 1
                            error('Same stimulus repeated: Will require code debugging') % shouldn't occur but just in case
                        end
                    end % Otherwise do another loop
                end
                reps = reps + 1; % ensure while loop doesn't get stuck on unresolvable scenarios
            end % end 'inserted stim' while
            i = i + 1;
        end % end for-loop iteration through runConds
        done = 1;
        disp('Complete!') % Done! didn't reach an unresolvable scenario
        fprintf('It took %d re-tries! \n', retry)
    end % end outer while
    
    StimLists.Stims = [StimLists.Stims, stimRun'];
    
end

%% save matfile with all stim lists
fprintf('\n=================\n\n');
StimListSet = StimLists; % added to maintain compatability with runExp.m
setfileName = fullfile(dirs.stim, sprintf('%s_%s.mat', outputFile, task));
if isfile(setfileName)
    overwrite = questdlg('A stim list with the same filename already exists, do you want to over-write it?','Answer', 'Yes - overwrite', 'No - quit','No - quit');
    switch overwrite
        case 'No - quit'
            return
    end
end
save(setfileName,'StimListSet');
disp('Stim list mat file was sucessfully created and saved!')

%% generate practice lists (1 trial per condition)
StimListSet = struct;
StimListSet.CondLabel = conds(randperm(nConds))';
for i = 1:nConds
    if i == 1 || nStims == 1
        StimListSet.Stims(i,1) = stims(randi([1 nStims]));
    else
        prevStim = StimListSet.Stims(i-1);
        prevStimIdx = strcmp(prevStim, stims);
        candStims = stims(~prevStimIdx);  % candidate stims, did not occur on previous trial
        StimListSet.Stims(i,1) = candStims(randi(numel(candStims)));
    end
end

setfileName = fullfile(dirs.stim, sprintf('%s_practice_%s.mat', outputFile, task));
save(setfileName,'StimListSet');
fprintf('Practice stim list mat file was sucessfully created and saved!\n')

%% function output - experimental stim list
StimListSet = StimLists;

end % End of original function

%% FUNCTIONS
function retValue = increase_cond_stim_counter(stimCounts,maxCount,stimPick,stimsList)
% find out which stimulus was picked (stimPick)
% and if it is less than the maxCount for the stimulus+condition pair, add it to stimCounts

stimInserted = 1;

stimIdx = find(strcmp(stimPick,stimsList)); % get index of selected stimulus in the overall list of stimuli;
if ~isempty(stimIdx) % if the picked stimulus is in the list of stimuli
    if stimCounts(stimIdx) < maxCount % if the stimulus+condition pair is less than the max number allowed
        stimCounts(stimIdx) = stimCounts(stimIdx) + 1;
        stimRun = stimPick;
        stimInserted = 1;
    else
        stimRun = [];   % If the value was above maxCount, then stimRun should be an empty value
                        % And if stimRun is empty, then it won't be counted in main loop
                        % If it is not empty, then the run will count in the main loop
    end
end

retValue = {stimCounts,stimRun,stimInserted};
end