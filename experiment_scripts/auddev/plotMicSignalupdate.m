function plotMicSignal(p, trialData, expParams, ii, fnum, movrmsExp)
% function plotMicSignal(p, trialData, expParams, ii)
%
% 
% generate the following plots for a given trial:
%           mic signal + rms trace, the rmsThresh and voice onset time
%           F1 mic and headphone trace
%           F0 mic and headphone trace (under construction)
%
% INPUTS    p = SAP data structure with audapter parameters
%           trialData = SAP data structure with trial data
%           expParams = SAP data structure with experimental parameters
%           ii = trial number
%           fnum = figure handle #
%           movrmsExp = dsp.movRMS object
%
% Developed by Elaine Kearney, Jan 2021 (elaine-kearney.com)
% Modified by Jason Tourville, Jan 2021 to add plots of F1 and F0 Mic and
% Headphones signals (jtour@bu.edu)

%% function
% create time vector for plotting in seconds
recFs = p.sr; % sampling rate
recLength = length(trialData(ii).audapData.signalIn); % length mic signal
time = 0 : 1/recFs : (recLength-1)/recFs; % time

% figure
%%Note: As currently written this will generate a new plot for every trial
%%      To update the same figure, change if check to 0 which will update
%%

if 1,
    figure(ii+1);
else,
    figure(2)
end


subplot(3,1,1);
plot(time, trialData(ii).audapData.signalIn)
hold on

% add rms trace
%rmsplot = repelem(trialData(ii).audapData.rms(:,1),p.frameLen);

%JT mod to use same Matlab-derived RMS method for both Mic and Phones
%signal
rmsMic = movrmsExp(trialData(ii).audapData.signalIn);
rmsPhones = movrmsExp(trialData(ii).audapData.signalOut);

plot(time, rmsMic, 'k', 'LineWidth', 2)
plot(time,rmsPhones, 'r','LineWidth', 2)

%constrain ylim to make it easier to visually compare RMS traces
maxWav = min([max(trialData(ii).audapData.signalIn),1]);
minWav = min([1,min(trialData(ii).audapData.signalIn)]);
set(gca,'xlim',[0,max(time)],'ylim',[minWav*1.01 maxWav*1.01]);

title('RMS Traces Over Mic Waveform');

% add voice onset
if trialData(ii).onsetDetected == 1
    yline(p.rmsThresh, 'LineWidth', 2, 'LineWidth', 1);
    xline(trialData(ii).rmsVoiceOnset, 'r--','LineWidth', 2);
else
    xlim=get(gca,'xlim');
    ylim=get(gca,'ylim');
    text(xlim(2)*.6,ylim(2)*.85,'Voice onset not detected', 'Color', 'r', 'Fontsize', 14)
end

% labels
%pTitle = sprintf('%s run %d trial %d Condition: %s', expParams.subjectID, expParams.runNum, ii, trialData(ii).condLabel);
%title(pTitle, 'Fontsize', 16)

ax = gca;
ax.YAxis.Exponent = 0;
ylabel('Sound Pressure');
if trialData(ii).onsetDetected == 1
    legend([], 'Mic RMS', 'Phones RMS', 'rmsThresh', 'Voice detect', 'Location', 'southeast')
else
    legend([], 'Mic RMS', 'Phones RMS', 'Location', 'southeast')
end

hold off;

%%%%%%%%%%%% F1 Trace Plots %%%%%%%%%%%%%%%%%%
p2 = subplot(3, 1, 2);

%Mic Spectrogram
[s,f,t]=spectrogram(trialData(ii).audapData.signalIn,...
    128,96,1024,recFs);
imagesc(t,f,10*log10(abs(s)));
axis xy;
%Focus on F1-F2 range to make easier to compare traces
set(gca,'ylim',[0 2000]);
hold on;
ylabel('Frequency (Hz)');

%F1 Mic
F1inplot = repelem(trialData(ii).audapData.fmts(:,1),p.frameLen);
plot(time, F1inplot, 'k','LineWidth',2);
hold on;

%F1 Phones
F1outplot = repelem(trialData(ii).audapData.sfmts(:,1),p.frameLen);
plot(time, F1outplot, 'r','LineWidth',2);
set(gca,'xlim',[0,max(time)])
title('F1 Traces Over Mic Spectrogram');

% add voice onset
if trialData(ii).onsetDetected == 1
    xline(trialData(ii).rmsVoiceOnset, 'k--','LineWidth', 2);
else
    xlim=get(gca,'xlim');
    ylim=get(gca,'ylim');
    text(xlim(2)*.6,ylim(2)*.85,'Voice onset not detected', 'Color', 'r', 'Fontsize', 14)
end

%labels
ax = gca;
ax.YAxis.Exponent = 0;
ylabel('Frequency (Hz)');
if trialData(ii).onsetDetected == 1
    legend('F1 Mic', 'F1 Phones', 'Voice detect', 'Location', 'northeast')
else
    legend('F1 Mic', 'F1 Phones', 'Location', 'northeast')
end

hold off;


%%%%%%%%%%%%%%F0 Trace Plots %%%%%%%%%%%%%%%%%%%%%%%
subplot(3,1,3);

%F0 Mic
F0inplot = repelem(trialData(ii).audapData.pitchHz,p.frameLen);
plot(time, F0inplot, 'k','LineWidth',2);
hold on;

%F0 Phones
F0outplot = repelem(trialData(ii).audapData.pitchHz,p.frameLen);
plot(time, F0outplot, 'b','LineWidth',2);

set(gca,'xlim',[0,max(time)]);

% add voice onset
if trialData(ii).onsetDetected == 1
    xline(trialData(ii).rmsVoiceOnset, 'r--','LineWidth', 2);
else
    xlim=get(gca,'xlim');
    ylim=get(gca,'ylim');
    text(xlim(2)*.6,ylim(2)*.85,'Voice onset not detected', 'Color', 'r', 'Fontsize', 14)
end

%label
xlabel('Time (s)')
ax = gca;
ax.YAxis.Exponent = 0;
ylabel('F0 (Hz)');
if trialData(ii).onsetDetected == 1
    legend('F0 Mic', 'F0 Phones', 'Voice onset detected', 'Location', 'southeast')
else
    legend('F0 Mic', 'F0 Phones', 'Location', 'southeast')
end

hold off;

end