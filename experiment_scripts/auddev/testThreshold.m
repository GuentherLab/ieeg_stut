
rmsThresh=0.05;             % initial threshold value (in rms units)
rmsFF=.90;                   % rms forgetting factor (0-1)
minThreshTime = .100;        % minimum time above threshold to detect voice onset (in seconds)
adaptSpeed = .05;             % speed of adaptation (0-1)
adaptLevel = 1/10;            % level of adaptation (0=minrms 1=maxrms)

sf=48000/3;                    % audio sampling frequency (in Hz)
frameLen=32;                 % rms Audapter frame length (samples)
debug=false;

if ~debug
    try, a=audioDeviceReader('Device','asdf'); catch me; str=regexp(regexprep(me.message,'.*Valid values are:',''),'"([^"]*)"','tokens'); str=[str{:}]; end;
    disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,str{n}),1:numel(str),'uni',0))); ID=input('Input device # : ');
    micDevName=str{ID};
    deviceReader = audioDeviceReader('Device', micDevName, 'SamplesPerFrame', ceil(.050*sf), 'SampleRate', sf, 'BitDepth', '24-bit integer');
end

thrhist=[];
dethist=[];
niter=1;
clf
while 1
    if debug
        fprintf('\n');
        a=load('handel');
        times=rand(1,3); times=round(2.5*sf*sort(times)/max(times));
        signalIn = [zeros(times(1),1); a.y(1+mod(randi(numel(a.y))+(1:times(2)-times(1)),numel(a.y))); zeros(times(3)-times(2),1)];
        signalIn = 1*signalIn + 1*pinknoise(numel(signalIn));
    else
        % record audio
        setup(deviceReader);
        starting = true;
        signalIn = [];
        while numel(signalIn)<2.5*sf, signalIn = [signalIn ; deviceReader()]; if starting, fprintf('\nSpeak now '); starting=false; else fprintf('.'); end; end
        release(deviceReader)
    end
    
    % compute rms and detect voice onset
    rms=sqrt(mean(reshape(signalIn(1:floor(numel(signalIn)/frameLen)*frameLen),frameLen,[]).^2,1))';
    for n=2:numel(rms), rms(n)=rmsFF*rms(n-1)+(1-rmsFF)*rms(n); end
    rmsidx = find(diff([0; rms(:,1) > rmsThresh; 0]));
    rmsOnsetIdx = rmsidx(-1+2*find(rmsidx(2:2:end)-rmsidx(1:2:end-1) >= minThreshTime*sf/frameLen,1));
    
    % adapt voice onset detection threshold
    if ~isempty(rmsOnsetIdx)    % voice onset detected
        minRms = prctile(rms,10); % note: expects some portion (at least 10%) of audio sample to contain silence
        maxRms = prctile(rms(rmsOnsetIdx:end,1),90); % note: expects some portion (at least 10%) of audio sample after the detected voice onset to contain speech
    else
        minRms = prctile(rms,10); %minRms = 0;
        maxRms = prctile(rms(:,1),90);
    end
    tmpRmsThresh = minRms + (maxRms-minRms)*adaptLevel;
    rmsThresh = (1-adaptSpeed)*rmsThresh + adaptSpeed*tmpRmsThresh;
    
    if 0 % testing consistency with new detectVoiceOnset algorithm
        [voiceOnsetDetected,voiceOnsetTime,voiceOnsetState]=detectVoiceOnset(signalIn,sf,minThreshTime,rmsThresh);
        disp([rmsOnsetIdx*frameLen/sf voiceOnsetTime])
    end

    thrhist(niter)=rmsThresh;
    dethist(niter)=~isempty(rmsOnsetIdx);
    
    % plot stuff
    subplot(211); plot(1:niter,thrhist,'k-',find(~dethist),thrhist(dethist==0),'bx',find(dethist),thrhist(dethist>0),'ro','markersize',18); xlabel('iteration #'); ylabel('rms threshold');
    subplot(212); plot((0:numel(signalIn)-1)/sf, signalIn); xlabel('time (s)');
    if isempty(rmsOnsetIdx), title(sprintf('no voice onset detected (threshold = %.6f)',rmsThresh));
    else
        idx=max(1,round((rmsOnsetIdx-1))*frameLen):numel(signalIn);
        hold on; plot((idx-1)/sf, signalIn(idx),'r'); hold off;
        %idx=reshape((frameLen*(find(rms(:,1)>rmsThresh)-1)+[1:frameLen nan])',1,[]);
        %hold on; plot(idx/sf, signalIn(max(1,idx)),'g'); 
        xline((rmsOnsetIdx-1)*frameLen/sf,'g:','linewidth',2); 
        title(sprintf('voice onset detected (threshold = %.6f)',rmsThresh));
    end
    hold all; plot(reshape([0:numel(rms)-1; 1:numel(rms)],[],1)*frameLen/sf, reshape([rms rms]',[],1),'k-','linewidth',2); hold off;
    yline(rmsThresh,'k:','linewidth',2);
    set(gca,'ylim',[-1 1]*max([2*rmsThresh;abs(signalIn)]));
    
    fprintf(' (threshold = %.6f) ',rmsThresh);
    if debug, pause(1);
    else fprintf('Press ENTER to continue '); pause; 
    end
    niter=niter+1;
end

