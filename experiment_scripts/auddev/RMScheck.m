function [mrDiff mrRat] = RMScheck(trialData, expParams, trials, doPlots)
% Plots RMS traces from Mic and Phones signals, their raw difference, and
% difference relative to Mic signal for each trial in a SAP Experimental run 
%
% INPUTS    trialData:  SAP data structure with trial data from a run
%           expParams:  SAP data structure with experimental parameters
%           trials:     trial number(s) to be plotted
%           doPlots:    1=plot individual trial data
%                       0=do not plot individual 
%    
% OUTPUTS   mrDiff: 
%           mrRat: 
%
%%% Jason Tourville developing February 2021 to debug SAP F1 shift

close all;

if ~exist('doPlots'),
    doPlots = 0;
end

%If trial number(s) not specified, plot all trial in the run
if isempty(trials)
    trials = 1:length(trialData);
end

%Initialize mean difference arrays
mrDiff = nan(size(trialData));
mrRat = nan(size(trialData));

for ii = trials,
    p=trialData(ii).p;
    %           trialData = SAP data structure with trial data
    %           ii = trial number
    recFs = p.sr; % sampling rate
    recLength = length(trialData(ii).audapData.signalIn); % length mic signal
    time = 0 : 1/recFs : (recLength-1)/recFs;

    voiceOn = trialData(ii).rmsVoiceOnset;
    voiceOnIdx = voiceOn*recFs;

    movrmsExp = dsp.MovingRMS('Method','Exponential weighting',...
            'ForgettingFactor',.999);
    rmsMic = movrmsExp(trialData(ii).audapData.signalIn);
    rmsPhones = movrmsExp(trialData(ii).audapData.signalOut);
    
    %Raw difference b/w Mic and Phone signals 
    rdiff = rmsMic-rmsPhones;
    %mean raw difference over arbitrary intervial from voice onset+500ms 
    % to voice onset +1250ms or end of recording
    mrDiff(ii) = mean(rdiff(voiceOnIdx+recFs*.5:min([voiceOnIdx+recFs*1.25,length(rmsMic)])));
    
    %Percent change from Mic signals
    rrat = rdiff./rmsMic;
    mrRat(ii) = mean(rrat(voiceOnIdx+recFs*.5:min([voiceOnIdx+recFs*1.25,length(rmsMic)])));

    
    if doPlots,
        pcfFix = contains(expParams.pcfSuffix,'JMfix');
    
        figure;
        pTitle = sprintf('Run %d  Trial %d  Cond: %s, pcfFix=%d, gainAdapt=%d',...
        expParams.runNum, ii, trialData(ii).condLabel, pcfFix, ...
        trialData(ii).audapData.params.bGainAdapt);
        sgtitle(pTitle, 'Fontsize', 14)

        subplot(3,1,1)
        title('RMS Traces')
        hold on;
        %plot signals starting 100 ms prior to voice onset or from 1/2 time
        %prior to voice onset if is under 100ms
        tidx = max([voiceOnIdx-recFs*.1,round(voiceOnIdx/2)]);
        p2 = plot(time(tidx:end), rmsMic(tidx:end), 'k', 'LineWidth', 2);
        p3 = plot(time(tidx:end), rmsPhones(tidx:end), 'r','LineWidth', 2);
        p4 = xline(trialData(ii).rmsVoiceOnset, 'r--','LineWidth', 2);
        ylabel = 'Spund Pressure';
        legend('RMS Mic','RMS Phones','Location','Northeast');

        %raw differences
        subplot(3,1,2)
        p5 = plot(time(tidx:end),rdiff(tidx:end),'LineWidth',2);
        title(['Mean RMS Diff = ' num2str(mrDiff(ii))]);

        %% difference relative to Mic signal
        subplot(3,1,3)
        p6 = plot(time(tidx:end),100*rrat(tidx:end),'LineWidth',2);
        title(['% Change RMS = ' num2str(mrRat(ii))]);
    end
        
    
end