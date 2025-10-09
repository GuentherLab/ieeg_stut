%%% analyze jackson protocol, irani protocol, and Emotional Reactivity Scale in pilot subjects
% for Oxford Disfluency Conference abstract
% 
%  assume only 1 run for each task will be analyzed per subject


 clear
 close all force

sub_inds_to_analyze = 1:12; 

figure_font_size = 25;


[dirs, host] = set_paths_ieeg_stut(); 

op.num_run_digits = 2; % must match the value used during data acquisition; usually 2 digits
op.num_trials_digits = 3; 

runs = readtable([dirs.projrepo, filesep, 'ieeg_stut_runs.tsv'],'FileType','text'); % load table of runs from all subs to cut into trial clips
runs = runs(logical(runs.analyze),:); % only analyze runs for which this table variable is true
nrunrows = height(runs); 

subs = table(unique(runs.subject),'VariableNames',{'sub'},'RowNames',unique(runs.subject));
    subs = subs(sub_inds_to_analyze',:); 
nsubs = height(subs);
subnan = nan(nsubs,1);
subs.st_prop_jackson = subnan;
subs.st_prop_irani = subnan;

for irun = 1:nrunrows
    sub = runs.subject{irun};
    ses = runs.session(irun); 
    task = runs.task{irun};
    taskrun = runs.run(irun); % run label within this subject / session / task
        runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], taskrun); % add zero padding

    dirs.src_ses = [dirs.data, filesep, 'sub-',sub, filesep, 'ses-',num2str(ses)]; 
    dirs.src_task = [dirs.src_ses, filesep, 'beh', filesep, task]; 
    dirs.src_trialdata = [dirs.src_task, filesep, 'run-',runstring]; 
    dirs.der_sub = [dirs.derivatives, filesep, 'sub-',sub];
    dirs.annot = [dirs.der_sub, filesep, 'annot']; 

    file_prepend = ['sub-',sub, '_ses-',num2str(ses), '_task-',task, '_run-',runstring,  '_']; 
    beh_scoring_filepath = [dirs.annot, filesep, file_prepend, 'beh_scoring.tsv']; 
    trials =  readtable(beh_scoring_filepath,'FileType','text','Delimiter','tab');
    trials = trials(isnan(trials.unusable_trial) | trials.unusable_trial==0,:);

    % some trials not yet scored may be indicated w/ nans, so use nanmean (these are not necessarily unusable trials)
    switch task
        case 'jackson20'
            subs.st_prop_jackson(sub) = nanmean(trials.stuttered) / 2;
        case 'irani23'
            trials.stuttered_trial = max([trials.stuttered_1, trials.stuttered_2], [], 2); % maximum 'amount' (non-ambiguity) of stuterring across both syls in a trial
             subs.st_prop_irani(sub) = nanmean(trials.stuttered_trial) / 2;;
        otherwise
            error('task not recognized')
    end
end

% ERS
subs = subs(sub_inds_to_analyze',:); 
subs.ers_mean = subnan;
for isub = 1:nsubs
    sub = subs.sub{isub}
    dirs.der_sub = [dirs.derivatives, filesep, 'sub-',sub];
    dirs.sub = [dirs.data, filesep, 'sub-',sub]; 
    ers_file = [dirs.sub, filesep, 'sub-',sub, '_ers.tsv']; 
    if exist(ers_file,'file')
        ers_table = readtable(ers_file,'FileType','text');
        subs.ers_mean(isub) = mean(ers_table.Rating_0_4_); 
    end
end



%%% getting error when trying to run readtable on these .tsv files
% for isub = [1 2 3 5]; % sub 4 missing data for now
%     sub = subs.sub{isub};
%     ers_filepath = [dirs.data, filesep, 'sub-',sub, filesep, 'ses-2', filesep, 'sub-',sub, '_ERS.tsv',]
%     ers_tab = readtable(ers_filepath, 'FileType','text', 'Delimiter','tab');
% end

% nsubs = 6; % extra subject added

mean_jackson = mean(subs.st_prop_jackson)
    sem_jackson = std(subs.st_prop_jackson) / sqrt(nsubs)
mean_irani = mean(subs.st_prop_irani)
    sem_irani = std(subs.st_prop_irani) / sqrt(nsubs)    
[~, p_irani_vs_jackson] = ttest(subs.st_prop_jackson, subs.st_prop_irani)


subs.irani_jackson_ratio = subs.st_prop_irani ./ subs.st_prop_jackson; 
subs.irani_jackson_dif = subs.st_prop_irani - subs.st_prop_jackson;

close all

hfig = figure('Color',[1 1 1]) ; 
hbar = bar([mean_jackson, mean_irani]) ;
hax = gca; 
hold on
ylabel ('proportion trials stuttered')
hax.XTickLabel = {'jackson2020', 'irani2023'};
errorbar([mean_jackson, mean_irani], [sem_jackson, sem_irani], 'LineStyle','none', 'LineWidth',2, 'Color',[0 0 0])
box off

%% plot individual subjects
hfig = figure('Color',[1 1 1]) ; 
hbar = bar([subs.st_prop_jackson, subs.st_prop_irani]);
hax = gca; 
ylabel ('proportion trials stuttered')
xlabel ('subject ID')
hleg = legend ({['Anticipation (' num2str(round(100*mean_jackson)), '%)'],['Pseudoword Pair (' num2str(round(100*mean_irani)), '%)']});
hax = gca;
hax.FontSize = figure_font_size; 


% Get the current outer position
op = hax.OuterPosition;

% Adjust the new position to remove the whitespace
ti = hax.TightInset;
hax.Position = [op(1)+ti(1), op(2)+ti(2), op(3)-ti(1)-ti(3), op(4)-ti(2)-ti(4)];

box off

%% plot ers vs irani-jackson comparison
subs = subs(~isnan(subs.ers_mean),:);


hfig = figure('Color',[1 1 1]) ; 
hscat = scatter(subs.irani_jackson_dif, subs.ers_mean,'filled','o','SizeData',100);

ylabel ('emotional reactivity score')
xlabel('Pseuword Pair > Anticipation difference')

hold on 
p = polyfit(subs.irani_jackson_dif, subs.ers_mean, 1);
x_fit = linspace(min(subs.irani_jackson_dif), max(subs.irani_jackson_dif), 100);
y_fit = polyval(p, x_fit);
hplot = plot(x_fit, y_fit, 'r-', 'LineWidth', 2, 'Color',[0 0 0]);

hax = gca;
% hax.XLabel.FontSize = axis_font_size; 
% hax.YLabel.FontSize = axis_font_size; 
hax.FontSize = figure_font_size; 

% Get the current outer position
op = hax.OuterPosition;

% Adjust the new position to remove the whitespace
ti = hax.TightInset;
hax.Position = [op(1)+ti(1), op(2)+ti(2), op(3)-ti(1)-ti(3), op(4)-ti(2)-ti(4)];


[r, p] = corrcoef(subs.irani_jackson_dif,subs.ers_mean)

box off


