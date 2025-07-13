function plotMicSignal(p, trialData, ii, h1, h2, h3, pitchMethod)
% function plotMicSignal(p, trialData, ii, h1, h2, h3, pitchMethod)
%
% Updates axes data (h1, h2, h3) with the following data for a given trial 
% in the the signal figure:
%           mic signal + rms trace, the rmsThresh and voice onset time
%           F1 mic and headphone trace
%           F0 mic and headphone trace (under construction)
%
% INPUTS    p = SAP data structure with audapter parameters
%           trialData = SAP data structure with trial data
%           ii = trial number
%           h1, h2, h3 = handles to plot elements for subplots
%                        (axes) 1, 2, and 3 of signal figure
%           pitchMethod = 'phase-vocoder' or 'time-domain' 
%
% Developed by Elaine Kearney, Jan 2021 (elaine-kearney.com)
% Modified by Jason Tourville, Jan 2021 to add plots of F1 and F0 Mic and
% Headphones signals (jtour@bu.edu)

%% function
% create time vector for plotting in seconds
recFs = p.sr; % sampling rate
recLength = length(trialData(ii).audapData.signalIn); % length mic signal
time = 0 : 1/recFs : (recLength-1)/recFs; % time

set(h1.p1,'xdata',time,'ydata',trialData(ii).audapData.signalIn);

%JT Addition for online RMS plots: initiate rms object
%JT mod to use same Matlab-derived RMS method for both Mic and Phones
%signal
%movrmsExp = dsp.MovingRMS('Method','Exponential weighting',...
%    'ForgettingFactor',.999);
%rmsMic = movrmsExp(trialData(ii).audapData.signalIn);
%QrmsPhones = movrmsExp(trialData(ii).audapData.signalOut);
%alternative if you prefer not to need dsp toolbox
rmsMic = mrms(trialData(ii).audapData.signalIn);
rmsPhones = mrms(trialData(ii).audapData.signalOut);

set(h1.p2,'xdata',time, 'ydata',rmsMic);
set(h1.p3,'xdata',time, 'ydata',rmsPhones);

% add voice onset
if trialData(ii).onsetDetected == 1
    set(h1.p4,'value',p.rmsThresh,'visible','on');
    set(h1.p5,'value',trialData(ii).rmsVoiceOnset,'visible','on');
    set(h1.t1,'visible','off');
else
    set([h1.p4, h1.p5],'visible','off');
    set(h1.t1,'position',[time(1),max(trialData(ii).audapData.signalIn) 0],'string','Voice onset not detected','visible','on');
end

%%%%%%%%%%%% F1 Trace Plots %%%%%%%%%%%%%%%%%%

%Mic Spectrogram
[s,f,t]=spectrogram(trialData(ii).audapData.signalIn,...
    128,96,1024,recFs);
set(h2.i1,'xdata',t,'ydata',f,'cdata',10*log10(abs(s)));
F1inplot = repelem(trialData(ii).audapData.fmts(:,1),p.frameLen);
set(h2.p1,'xdata',time, 'ydata',F1inplot);
%F1 Phones
F1outplot = repelem(trialData(ii).audapData.sfmts(:,1),p.frameLen);
set(h2.p2,'xdata',time, 'ydata',F1outplot);

% add voice onset
if trialData(ii).onsetDetected == 1
    set(h2.p3,'value',trialData(ii).rmsVoiceOnset, 'visible','on');
else
    set(h2.p3,'visible','off');
end

%%%%%%%%%%%%%%F0 Trace Plots %%%%%%%%%%%%%%%%%%%%%%%

switch pitchMethod
    case 'phase-vocoder'
        %F0 Mic
        [f0_mic,idx] = pitch(trialData(ii).audapData.signalIn,recFs,'Method','PEF');
        time_f0 = (idx - 1)/recFs;
        set(h3.p1, 'xdata', time_f0, 'ydata', f0_mic);

        %F0 Phones
        [f0_phones,~] = pitch(trialData(ii).audapData.signalOut,recFs,'Method','PEF');
        %plot(time_f0, f0_phones, 'b','LineWidth',2);
        set(h3.p2, 'xdata', time_f0, 'ydata', f0_phones);

    case 'time-domain'
        %F0 Mic
        F0inplot = repelem(trialData(ii).audapData.pitchHz,p.frameLen);
        set(h3.p1, 'xdata', time, 'ydata', F0inplot);
        
        %F0 Phones
        F0outplot = repelem(trialData(ii).audapData.shiftedPitchHz,p.frameLen);
        
        %plot(time, F0outplot, 'b','LineWidth',2);
        set(h3.p2, 'xdata', time, 'ydata', F0outplot);
end

% add voice onset
if trialData(ii).onsetDetected == 1
    set(h3.p3, 'value', trialData(ii).rmsVoiceOnset, 'visible','on');
else
    set(h3.p3,'visible','off');
end

% add perturbation onset
%NEEDS TO BE UPDATED HERE AND ADDED TO RUNEXP AFTER CONFLICTS ADDRESSED
%if ~isnan(trialData(ii).pertOnset)
%    xline(trialData(ii).pertOnset, 'r--','LineWidth', 2);
%end

drawnow
end

function rms = mrms(x, N)
if nargin<2||isempty(N), N=220; end
    m=movsum(x,N)/N;
    s=movsum(x.^2,N)/N;
    rms=sqrt(s-m.^2);
    rms = rms(rms==real(rms));
%     if isempty(rms), rms=.0001; end
end