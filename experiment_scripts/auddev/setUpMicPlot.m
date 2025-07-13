function [h1,h2,h3,sigplotTitle] = setUpMicPlot
% [h1,h2,h3] = setUpMicPlot;
%
% Function to initialize figure for plotting the mic waveform and
% spectrograms during the AudDev experiment
%
% OUTPUTS    h1             handle to mic waveform subplot
%            h2             handle to formant spectrogram subplot
%            h3             handle to pitch spectrogram waveform subplot
%            sigplotTitle   handle to plot title
%
% Developed by Jason Tourville, August 2021
%
%% create figure
figure;
set(gcf,'Units','normalized','Position',[.01 .05 .3 .7])
sigplotTitle = sgtitle('Here We Go','fontsize',16);

% waveform plot
s1 = subplot(3,1,1);
s1.YAxis.Exponent = 0;
h1.p1 = plot(nan, nan); hold on
h1.p2 = plot(nan, nan, 'k', 'LineWidth', 2);
h1.p3 = plot(nan, nan, 'r','LineWidth', 2);
h1.p4 = yline(0, 'LineWidth', 2, 'LineWidth', 1);
h1.p5 = xline(0, 'r--','LineWidth', 2);
h1.t1 = text(nan,nan,'', 'Color', 'r', 'Fontsize', 14);
title('RMS Traces Over Mic Waveform');
ylabel('Sound Pressure');
hold off
legend([h1.p2 h1.p3 h1.p4 h1.p5], 'Mic RMS', 'Phones RMS', 'rmsThresh', 'Voice detect', 'Location', 'southeast')

% formant plot
h2.s2 = subplot(3,1,2);
h2.s2.YAxis.Exponent = 0;
h2.i1 = imagesc([]);
axis xy
%Focus on F1-F2 range to make easier to compare traces
set(h2.s2,'ylim',[0 2500]);
hold on
h2.p1 = plot(nan, 'k','LineWidth',2);
h2.p2 = plot(nan, 'r','LineWidth',2);
h2.p3 = xline(0, 'r--','LineWidth', 2);
title('F1 Traces Over Mic Spectrogram');
ylabel('Frequency (Hz)');
legend([h2.p1,h2.p2,h2.p3],'F1 Mic', 'F1 Phones', 'Voice detect', 'Location', 'northeast')
hold off

%pitch plot
s3 = subplot(3,1,3);
s3.YAxis.Exponent = 0;
h3.p1 = plot(nan, 'k','LineWidth',2); hold on;
h3.p2 = plot(nan, 'b','LineWidth',2);
h3.p3 = xline(0, 'r--','LineWidth', 2);
title('f0 Traces');
ylabel('Frequency (Hz)');
xlabel('Time (s)');
legend([h3.p1,h3.p2,h3.p3],'F0 Mic', 'F0 Phones', 'Voice onset detected', 'Location', 'southeast')
hold off

end