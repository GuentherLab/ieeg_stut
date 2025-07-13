function testAudapterParams(wavFile, gender, param, value1, value2)
% testAduapterParams(wavfile, gender, param, value1, value2)
%
% offline testing of audapter parameters; can be used to assess effect
% of processing on voice quality
%
% INPUTS        wavfile = baseline voice recording
%               gender = male, female
%               param = audapter parameter to be tested
%               value1 = first parameter value to be tested
%               value2 = second parameter value to be tested
%
% OUTPUTS       audapter processed wavfiles, appended with parameter values
%                   & saved to same directory as input wavfile
%
% E.G.          testAduapterParams('recording.wav', frameLen, 32, 64)
%
% Developed by Elaine Kearney and Hilary Miller, October 2020
% Matlab 2019b
%

%% set up
% audapter
addpath(genpath('C:\speechres\Audapter\')); 

% file parts
[wavPath, wavName] = fileparts(wavFile);

% design
pitchAlgorithm = {'pp_none', 'pp_peaks','pp_valleys'};
shiftType = {'noshift', 'up', 'down', };
testVal = {value1, value2};

which Audapter; %makes sure audapter is mapped
Audapter info; %lets you know which sound card is being used

% get default params & initiate audapter
p = getAudapterDefaultParamsPitch(gender);
p.downFact = 1; % we don't want audapter to downsample again because the baseline recording is already at 16kHz

% initiate audapter
AudapterIO('init', p);
%EQfilters('set_audapter','input', 'micmri');
%EQfilters('set_audapter','output', 'S504');
EQfilters('set_audapter','input', 'none'); % uncomment these two lines (and comment the two lines above) to skip input/output filtering
EQfilters('set_audapter','output', 'none');
AudapterIO('reset');
Audapter('start')
Audapter('stop')

% read baseline voice recording
[baselineRec, baselineFS] = audioread(wavFile);

% find rmsThresh 
recDur = size(baselineRec,1);
rmsWindow = 5; % # of samples to estimate RMS over
nSamp = rmsWindow + (recDur - rem(recDur, rmsWindow)) - rmsWindow;
basePeriod = baselineRec(1:nSamp,:);
baseRMS = sqrt(mean(reshape(basePeriod, rmsWindow, []) .^ 2));
idx = findchangepts(baseRMS);
p.rmsThresh = baseRMS(idx);

% plot rmsThresh
% plot(baselineRec);
% hold on;
% yline(p.rmsThresh);
% xline(idx*rmsWindow);

% offline processing

for i = 1:numel(pitchAlgorithm)
    
    % algorithm
    p.timeDomainPitchShiftAlgorithm = pitchAlgorithm{i};
    
    for j = 1:numel(shiftType)
        
        % shift type
        switch shiftType{j}
            
            case 'noshift'
                p.timeDomainPitchShiftSchedule = [0, 1];
                
            case 'up'
                p.timeDomainPitchShiftSchedule = [0, 1.0595];
                
            case 'down'
                p.timeDomainPitchShiftSchedule = [0, 0.9439];
        end
        
        % parameter value
        for k = 1:numel(testVal)
            p.(param) = testVal{k};
            
            % initiate audapter
            AudapterIO('reset')
            AudapterIO('init', p);
            
            % format data
            sigInCell = makecell(baselineRec, p.frameLen);
            
            % processing
            for n = 1 : length(sigInCell)
                Audapter('runFrame', sigInCell{n});
            end
            
            % read data
            data = AudapterIO('getData');
            y = [data.signalIn data.signalOut];
            
            % write data
            saveFile = sprintf('%s\\%s-%s-%s-%s-%d.wav', wavPath, wavName, pitchAlgorithm{i}, shiftType{j}, param, testVal{k});
            audiowrite(saveFile, y, baselineFS);
            
        end
    end
end
end