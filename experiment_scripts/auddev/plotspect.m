function data=plotspect(filename,newplot,DOPRINT)

if nargin<2||isempty(DOPRINT), DOPRINT=true; end
if nargin<1||isempty(filename), 
    [tfilename,tpathname]=uigetfile({'*.mat','Matlab batch structure (*.mat)'; '*',  'All Files (*)'},'Select data file');
    if ~ischar(tfilename)||isempty(tfilename), return; end
    filename=fullfile(tpathname,tfilename);
end
[file_path,file_name,file_ext]=fileparts(filename);
load(filename,'trialData');
s={};
borders={};
g1={};
g2={};
for n=1:numel(trialData)
    s{1,n}=trialData(n).audapData.signalOut;
    s{2,n}=trialData(n).audapData.signalIn;
    %fs=trialData(n).p.downFact*trialData(n).p.sr;
    %frame=trialData(n).p.downFact*trialData(n).p.frameLen;
    fs=trialData(n).p.sr;
    frame=trialData(n).p.frameLen;
    name=trialData(n).condLabel;
    delay = 6*frame; % guess (delay in samples between signalIn and signalOut)
    s{1,n}=s{1,n}(delay+1:end); % corrects delay in signalOut

    
    % selects "core" speech segment
    frame2=3*frame;
    a1=cumsum(abs(s{1,n})); a1=diff(a1(1:frame2:end))/frame;
    a2=cumsum(abs(s{2,n})); a2=diff(a2(1:frame2:end))/frame; % rms (note: same MSD scaling factor)
    segment_borders=find([1;a2/mean(abs(s{2,n}))<1;1]); % selects frame with average sound amplitude above 0.5*MAD
    segment_lengths=diff(segment_borders);
    [nill,idx]=max(segment_lengths);
    borders{n}=max(1,min(numel(s{1,n}), round([frame2*(segment_borders(idx)+1) frame2*segment_borders(idx+1)-1] + fs*[.050 -.050]) )); % 50ms after start to 50ms before end (units: samples)    
    for m=1:2,
        g1{m,n}=s{m,n}(borders{n}(1):borders{n}(2));
    end
    
    % computes spectrum
    t=abs(fft(g1{2,n}));
    f=(0:numel(t)-1)/numel(t)*fs;
    [nill,idx]=max(t(f<300));
    L=round(fs/f(idx)); % one pitch-length
    if 1
        temp1=0;temp2=0;
        for nrepeat=1:1e3,
            t0=randi(numel(g1{2,n})-L);
            t1=g1{1,n}(t0:t0+L-1);
            t1=hanning(L).*(t1-mean(t1));
            temp1=temp1+(abs(fft(t1,128*L)));
            t2=g1{2,n}(t0:t0+L-1);
            t2=hanning(L).*(t2-mean(t2));
            temp2=temp2+(abs(fft(t2,128*L)));
        end
        g2{1,n}=log10(temp1/1e3);
        g2{2,n}=log10(temp2/1e3);
    else
        for m=1:2,
            g2{m,n}=log10(abs(fft(g1{m,n})));
        end
    end
    
    % plots signal
    h=findobj('type','figure');
    if newplot,
        nfig=length(h)+1;
    else
        nfig=max([length(h),1]);
    end
    figure(nfig);
    subplot(211);
    h1=plot((0:numel(s{2,n})-1)/fs,s{2,n},'b-'); hold all;
    h2=plot((0:numel(s{1,n})-1)/fs,s{1,n},'r-'); hold off;
    hold on; plot(frame2/fs*(.5:numel(a2)),3*a2,'b-',frame2/fs*(.5:numel(a1)),3*a1,'r-','linewidth',2); hold off;
    xlabel('time (s)');
    patch(borders{n}/fs*[0 1 1 0;1 0 0 1],[-1 -1 1 1],'k','facealpha',.1,'edgecolor','none');
    axis tight;
    legend([h1 h2],'mic','headphones');
    title(sprintf('Trial %d: %s, PreEmph = %s',n,name,num2str(trialData(n).p.preempFact)));
    % plots the spectrum and filter
    subplot(212);
    f=(0:size(g2{1,n},1)-1)'/size(g2{1,n},1)*fs/1e3;
    %mic spectrum plot
    subplot(223); 
    plot(f,g2{2,n},'-','linewidth',2); hold on;
    plot(f,g2{1,n},'-','linewidth',2); hold off;
    fdiff = g2{2,n}-g2{1,n};
    d1500 = round(sum(abs(fdiff(1:1500))));
    d750 = round(sum(abs(fdiff(1:750))));
    txt1 = sprintf('d1500=%d, d750=%d',d1500,d750);
    text(0,min(g2{2,n})*.75,txt1);   
    xlabel('Frequency (KHz)'); ylabel('Power spectrum (dB)'); legend('mic','phones');
    set(gca,'xlim',[0 fs/2]/1e3);title('Spectral power');
    
    subplot(224); plot(f,g2{1,n}-g2{2,n},'-','linewidth',2); xlabel('Frequency (KHz)'); ylabel('Filter (dB)');set(gca,'xlim',[0 fs/2]/1e3);
    
    title('Filter shape');
    if ~DOPRINT
        drawnow;
    else
        out_filename=fullfile(file_path,[file_name, sprintf('_Trial_%d_%s.jpg',n,name)]);
        print(gcf,'-djpeg90','-r600','-opengl',out_filename);
        fprintf('created file %s\n',out_filename);
    end
end

if nargout>0
    data=struct('signal',{s},'borders',{borders},'cropped',{g1},'spectrum',{g2});
end

