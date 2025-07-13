function p = setAudapterParams(gender, shiftType, varargin)
% function p = setAudapterParams(gender, shiftType, varargin)
%
% Function to create or update structure to initialize Audapter
%
% INPUTS
%               gender          'male' or 'female'
%               shiftType       'formant' or 'pitch'
%
% INPUTS (optional; specify as name-value pairs)
%               pitchMethod     'phase-vocoder' or 'time-domain' shift
%                                - must be specified if shiftType = pitch
%               p               structure with parameters to initialize Audapter (if updating existing p structure)
%
% OUTPUT
%               p               structure with parameters to initialize Audapter
%
% REQUIRES      getAudapterDefaultParams.m
%               fsic.m
%
% Note: You will still need to set individual and trial-specific parameters in the
% experimental scripts, e.g., rmsThresh, pitchLowerBoundHz,
% pitchUpperBoundHz, timeDomainPitchShiftSchedule, timeDomainPitchShiftAlgorithm
%
% Developed by Elaine Kearney (elaine-kearney.com, May 2021)
% Matlab 2019a
%

% if pitch shift, check which method
if strcmp(shiftType, 'pitch')
    if isempty(fsic(varargin, 'pitchMethod'))
        error('pitchMethod (''phase-vocoder'' or ''time-domain'') must be specifed when shiftType is set to ''pitch''');
    else
        pitchMethod = varargin{fsic(varargin, 'pitchMethod') + 1};
    end
end
            
% start with audapter defaults or existing p structure
if isempty(fsic(varargin, 'p'))
    p = getAudapterDefaultParams(gender);
    p.timeDomainPitchShiftAlgorithm = 'pp_none';    % sets default pitch algorithm to 'pp_none' 
                                                    % (only used in pitch shifts, but specified for 
                                                    % both so that the fieldnames are the same)
    switch shiftType
        
        case 'pitch'
            
            switch pitchMethod
                case 'time-domain'
                    switch gender
                        case 'male'
                            p.pitchLowerBoundHz = 60;
                            p.pitchUpperBoundHz = 170;

                        case 'female'
                            p.pitchLowerBoundHz = 100;
                            p.pitchUpperBoundHz = 400;

                        otherwise
                            error('specify gender (male / female');
                    end
            end
    end
else
    p = varargin{fsic(varargin, 'p') + 1};
end

% update params based on Guenther lab setup
p.dScale = 1;                                   % no scaling of headphone signal
p.nDelay = 7;                                   % default is 5
p.stereoMode = 0;                               % mono - left channel only; default is 1 (stereo)
                                                % this prevents clipping at thelevel of the motu
%p.eqfilter = 1;                                 % equalization filter for MR headphones (note: see setUpEQfilter; 21-length a*y=x*b filter coefficients of headphone equalization filter combined with 8Khz low-pass for upsampling)
%                                                % values below based on EQF_504 headset
%p.eqfilter_a = [1 -5.75471474086736 15.9791443224195 -27.8453958746592 33.8679184114231 -31.3865228777312 25.3492709502468 -20.9153500856605 17.9606358134845 -14.8555875997507 12.3637115362324 -11.1903050536838 9.94268179949726 -7.71432259505361 5.60413356746172 -4.47470820603634 3.63628524621226 -2.38742427225541 1.08430775892996 -0.299453305156428 0.0383804002233832];
%p.eqfilter_b = [0.00570966595476346 -0.0112376169798971 0.0145754220683358 -0.0113190264529328 0.00644652023695776 -0.00365396238219983 0.00136510405311595 -0.00117107203692529 0.000170416836377158 2.10131851304439e-05 0.000131176108787179 -0.000742544816345201 0.00207734085707366 -0.0023577953561914 0.00677480722095782 -0.0118854702086538 0.0145060836128372 -0.0111439409018681 0.00491146766886396 -0.000997814774383153 -0.000235130515760644];
                                                
% update params based on shift type
switch shiftType
    
    case 'formant'
        p.bShift = 1;                   % turn on formant shift
        p.bPitchShift = 0;              % turn off phase-vocoder pitch shift
        p.bBypassFmt = 0;               % don't bypass formant tracking
        p.frameLen = 32;                % formant shift works with shorter frame length
        p.bTimeDomainShift = 0;         % turns off time-domain pitch shift
        p.bCepsLift = 0;                % turns off cepstral lifetering
    
    case 'pitch'
        switch pitchMethod
            case 'phase-vocoder'
                p.bShift = 0;           % turn off formant shift
                p.bPitchShift = 1;      % turn on phase-vocoder pitch shift
                p.bBypassFmt = 1;       % bypass formant tracking
                p.frameLen = 32;        % phase-vocoder pitch shift works with shorter frame length
                p.bTimeDomainShift = 0; % turn off time-domain pitch shift
                p.bCepsLift = 0;        % turn off cepstral lifetering
                
            case 'time-domain'
                p.bShift = 0;           % turn off formant shift
                p.bPitchShift = 0;      % turn off phase-vocoder pitch shift
                p.bBypassFmt = 0;       % don't bypass formant tracking (this MUST be 0 for the time-domain pitch shift to work)
                p.frameLen = 64;        % time-domain pitch shift requires longer frame length
                p.bTimeDomainShift = 1; % turn on time-domain pitch shift
                p.bCepsLift = 1;        % turn on cepstral lifetering, necessary only for time-domain pitch shift
        end
        
    otherwise
        error('specify shiftType (formant / pitch');
end

% update params that are dependent on other params
p.frameShift = p.frameLen/p.nWin;
p.bufLen = (2*p.nDelay-1)*p.frameLen;
p.anaLen = p.frameShift+2*(p.nDelay-1)*p.frameLen;
p.rmsMeanPeak = 6*p.rmsThresh;
p.timeDomainPitchShiftSchedule = [0,1]; % AA: Adding a statement for this because if you set 
% an erroneous pitch shift schedule and the script crashes, this schedule will remain persistent and will not allow Audapter to run

end