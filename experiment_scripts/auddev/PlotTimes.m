function PlotTimes(files)
% PlotTimes(files)
% 

% load data
data=cellfun(@load,cellstr(files),'uni',0); 
data=[data{:}];
if isfield(data,'trialData') % single multiple-trials file
    T=arrayfun(@(n)data.trialData(n).timingTrial,1:numel(data.trialData),'uni',0);
elseif isfield(data,'tData') % multiple single-trial files
    T=arrayfun(@(n)data(n).tData.timingTrial,1:numel(data),'uni',0);
else error('unrecognized file format');
end
T=cat(2,T{:});
    
% plot times
figure('units','norm','position',[.2 .2 .4 .6],'color','w');
axes('units','norm','position',[.2 .4 .6 .3]);
plot(T-T(1,:),'o-'); 
titles={'TIME_TRIAL_START','TIME_TRIAL_ACTUALLYSTART','TIME_VOICE_START','TIME_PERT_START','TIME_PERT_END','TIME_PERT_ACTUALLYEND','TIME_SCAN_START','TIME_SCAN_ACTUALLYSTART','TIME_SCAN_END'};
text(1:size(T,1), -ones(1,size(T,1)), titles(1:size(T,1)),'rotation',90,'HorizontalAlignment','right','interpreter','none'); 
set(gca,'xtick',1:size(T,1),'xticklabel',[]); 
grid on; 
ylabel('time since trial start (s)');
axes('units','norm','position',[.2 .72 .6 .2]);
plot(T,'o-'); 
set(gca,'xtick',1:size(T,1),'xticklabel',[]); 
grid on; 
ylabel('time since session start (s)');
box off;
end

