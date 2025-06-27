function rmsData = rmsIter(SubjId,sessId, gFixOrder, doPlots)

% OUTPUTS rmsData: structural array with fields:
%               .mrDiff:   trials x runs array of mean raw RMS difference b/w 
%                          Mic and Phone signals for all trials/runs from 
%                          SubjId in sessId
%               .mrRat:   trials x runs array of RMS ratio b/w Mic and Phone  
%                          signals expressed as % of Mic Signal and Phone
%                          for all trials/runs fromSubjId in sessId
%                          


%get computer-appropriate directories
dirs = setDirs('SAP');

%trial condition labels (make an input to generalize)
rmsData.condOrder = [{'U1'}, {'D1'},{'N1'}];

%gain fix mode order
%For now, this is an input (or one of following default order) rather than 
%pulled from the trialData or this
if isempty(gFixOrder),
    %JT's sub-test104 order
    if strmatch(SubjId,'sub-test104'),
        rmsData.gFixOrder = [{'noGain'},{'gAOnly'},{'pcfOnly'}];
    %EK's sub-test25 order
    elseif strmatch(SubjId,'sub-test25'),
        rmsData.gFixOrder = [{'noGain'},{'badgAOnly'},{'pcfOnly'},...
            {'pcf+badgA'},{'noGain'},{'gAOnly'}];
    else
        disp('Need to specify Gain Fix mode for each run.')
    end
end

%highly project-specific means of designating subject directory
if contains(SubjId,'test') || contains(SubjId,'pilot'),
    dirs.subjects=dirs.pilot;
else
    dirs.subjects=dirs.project;
end

subjFolder = fullfile(dirs.subjects, SubjId);
sessFolder = fullfile(subjFolder, sessId);


runs = dir([sessFolder filesep 'run-*' ]);
fprintf('\n detected %s runs \n', string(length(runs)))


rmsData.mrDiff = [];
rmsData.mrRat = [];

for nrun = 1:length(runs),
    tData = [];
    runPath = [runs(nrun).folder filesep runs(nrun).name];
    nameMatFile = [runPath filesep SubjId '_' sessId '_' runs(nrun).name '_task-auditory.mat'];
    tData = load(nameMatFile);
    [rmsData.mrDiff(:,nrun) rmsData.mrRat(:,nrun)] = RMScheck(tData.trialData, tData.expParams, [], doPlots);
    if doPlots,
        pause;
    end
    condLabels = {tData.trialData.condLabel};
    
    %Code below was to extract condition labels for each run 
    % Need to restructure array to make sure in same order for each run 
    % in order to make more flexible. For now using replacing with explicit
    % condition labels specified above. 
    %rmsData.condOrder(:,nrun) = unique(condLabels);

    for ncond = 1:length(rmsData.condOrder),
        rmsData.cidx(:,ncond,nrun) = find(strcmp(condLabels,rmsData.condOrder(ncond)));
        disp(['Indices for Condition Label:  ', rmsData.condOrder{ncond}, ...
            ' = ', num2str(rmsData.cidx(:,nrun)')]);
        rmsData.meanRaw(ncond,nrun)=mean(rmsData.mrDiff(rmsData.cidx(:,ncond),nrun))
        rmsData.meanRat(ncond,nrun)=mean(100*rmsData.mrRat(rmsData.cidx(:,ncond),nrun));
        
    end
end

figure;
plot(rmsData.meanRaw','linewidth',2);
title('Mean RMS signal difference')
legend(rmsData.condOrder,'location','Southeast');
xticks([1:size(rmsData.meanRaw,2)]);
set(gca,'xticklabels',rmsData.gFixOrder);

figure;
plot(rmsData.meanRat','linewidth',2);
title('Mean % RMS signal change')
legend(rmsData.condOrder,'location','Southeast');
xticks([1:size(rmsData.meanRat,2)]);
set(gca,'xticklabels',rmsData.gFixOrder);

end

