function run_exp_ieeg_stut_jackson20(varargin)
close all;

CMRR = true;

% set priority for matlab to high for running experiments
system(sprintf('wmic process where processid=%d call setpriority "high priority"', feature('getpid')));

beepoffset = 0.100;

%%%%%%%%%%%%%%% comments below mostly apply to original FLVoice_run script, not jackson20 protocol
%
%
% FLVOICE_RUN(option_name1, option_value1, ...)
% specifies additional options:
%       visual                      : type of visual presentation ['figure']
%       root                        : root directory [pwd]
%       audiopath                   : directory for audio stimuli [pwd/stimuli/audio/Adults]
%       figurespath                 : directory for visual stimuli [pwd/stimuli/figures/Adults]
%       subject                     : subject ID ['TEST01']
%       session                     : session number [1]
%       run                         : run number [1]
%       task                        : task name ['test']
%       timePostStim                : time (s) from end of the audio stimulus presentation to the GO signal (D1 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [.25 .75] 
%       timePostOnset               : time (s) from subject's voice onset to the scanner trigger (or to pre-stimulus segment, if scan=false) (D2 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [4.5] 
%       timeMax                     : maximum time (s) before GO signal and scanner trigger (or to pre-stimulus segment, if scan=false) (D3 in schematic above) (recording portion in a trial may end before this if necessary to start scanner) [5.5] 
%       timeScan                    : (if scan=true) duration (s) of scan (D4 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [1.6] 
%       timePreStim                 : time (s) from end of scan to start of next trial stimulus presentation (D5 in schematic above) (one value for fixed time, two values for minimum-maximum range of random times) [.25] 
%       timePreSound                : time (s) from start of orthographic presentation to the start of sound stimulus (D6 in schematic above) [.5]
%       timePostSound               : time (s) from end of sound stimulus to the end of orthographic presentation (D7 in schematic above) [.47]
%       minVoiceOnsetTime           : time (s) to exclude from onset detection (use when beep sound is recorded)
%       prescan                     : (if scan=true) true/false include prescan sequence at the beginning of experiment [1] 
%       rmsThresh                   : voice onset detection: initial voice-onset root-mean-square threshold [.02]
%       rmsBeepThresh               : voice onset detection: initial voice-onset root-mean-square threshold [.1]
%       rmsThreshTimeOnset          : voice onset detection: mininum time (s) for intentisy to be above RMSThresh to be consider voice-onset [0.1] 
%       rmsThreshTimeOffset         : voice offset detection: mininum time (s) for intentisy to be above and below RMSThresh to be consider voice-onset [0.25 0.25] 
%       deviceMic                   : device name for sound input (microphone) (see audiodevinfo().input.Name for details)
%       deviceHead                  : device name for sound output (headphones) (see audiodevinfo().output.Name for details) 
%


%%%%%%%%%%%% NOTE - if running experiment on single screen, pressing button to proceed in each trial may return focus to Matlab, hiding stim window from experimenter
%%%%%%%%%%%% .... ideally, run on 2 screens, with Matlab on main screen and stim window on 2nd screen
%%% if op.preview_answer  _to_subject is true, orthography of the expected answer will be shown to the subject before investigator asks question
% op.preview_answer_to_subject = 0; % use for in-person jackson20 task
op.preview_answer_to_subject = 1; % use for remote session Answer-Question task
    op.preview_answer_duration = 3; % duration of preview in sec
 
% wait period between experimenter finishing question and playing of the GO beep and green screen
% op.anticipation_dur_sec = 4; % use for in-person jackson20 task
op.anticipation_dur_sec = 2; % use for remote session Answer-Question task
% op.anticipation_dur_sec = 0.0; % use for rtMRI piloting version

show_mic_trace_figure = 0; % if false, make mic trace figure invisible

op.experimenter_warning_latency_sec = 0.8; % warn experimenter this soon before the screen turns green
% op.experimenter_warning_latency_sec = 0.0;  % no warning - use this option when there is suppose to be zero delay

op.ntrials_between_breaks = 34; %%%% not currently implemented, because experimenter has control of pausing at every trial

%%%%% not working when this option is false ???
manually_choose_config_file = 0; % if false, use default config file C:\docs\code\ieeg_stut\config\ieeg_stut_jackson20.json

op.background_color = [0 0 0]; % text will be inverse of this color

op.ortho_font_size = 120; %  used for Answer preview..... if stim window not maximized, font sizes larger than 100 may result in cut off orthography
% op.ortho_font_size = 60; % for rtmri version with full sentences

op.num_run_digits = 2; % number of digits to include in run number labels in filenames

%% audio device setup

pause('on') % enable to use of pause.m to hold code execution until keypress

[dirs, computername] = set_paths_ieeg_stut();
    computername = deblank(computername); 
auddevs = audiodevinfo; 
    auddevs_in = {auddevs.input.Name};
    auddevs_out = {auddevs.output.Name};

if any(contains(auddevs_out,'Focusrite') )  % Full experimental setup with Focusrite
        default_audio_in = 'Focusrite';
        default_audio_out = 'Focusrite';
else
    % default device names do not have to be full device names, just need to be included in a single device name
    switch computername
        case '677-GUE-WL-0010'  % AM work laptop - Thinkpad X1
            if any(contains(auddevs_out,'Headphones (WF-C500)') ) % if using bluetooth headphones

                default_audio_in = 'Default';
                default_audio_out = 'Headphones (WF-C500)'; 
                    % default_audio_out = 'Headset (WF-C500)'; 
            else % Thinkpad X1 without headphones
                default_audio_in = 'Microphone'; 
                default_audio_out = 'Realtek'; 
                    % default_audio_out = 'ARZOPA'; % portable screen speakers
            end
        case 'MSI' % AM's MSI laptop
            default_audio_in = 'Microphone (Realtek(R) Audio)'; 
            if any(contains(auddevs_out,'Headphones (MP43250)') )   % if using bluetooth headphones
                default_audio_out = 'Headphones (MP43250)'; 
            else
                default_audio_out = 'Speakers (Realtek(R) Audio)'; 
            end
        case 'amsmeier' % AM's AMD stryx laptop
            default_audio_in = 'Microphone Array (Realtek(R) Audio)';
            default_audio_out = 'Speakers (Realtek(R) Audio)'; 
        otherwise 
            error('unknown computer; please add preferred devices to "audio device section" of main experiment file')
    end
end

%%
ET = tic;
if ispc, [nill,host]=system('hostname');
else [nill,host]=system('hostname -f');
end
host=regexprep(host,'\n','');

if strcmp(host, '677-GUE-WL-0009')
    default_fontsize = 10;
else
    default_fontsize = 15;
end

preFlag = false;
expRead = {};

%% functions for manually choosing config file
function preCall1(varargin)
    [fileName, filePath] = uigetfile('./config/*.json', 'Select .json file');
    fileFull = [filePath fileName];
    if isequal(fileName,0)
        return
    else
        set(prePath, 'String', fileFull);
    end
end

function preCall2(varargin)
    path = get(prePath, 'String');
    assert(~isempty(dir(path)), 'unable to find input file %s',path);
    if ~isempty(dir(path))
        expRead=spm_jsonread(path);
        uiresume;
        preFlag = true;
    end
end
%%

if manually_choose_config_file
    presfig=dialog('units','norm','position',[.3,.3,.3,.1],'windowstyle','normal','name','Load preset parameters','color','w','resize','on');
    uicontrol(presfig,'style','text','units','norm','position',[.05, .475, .6, .35],'string','Select preset exp config file (.json):','backgroundcolor','w','fontsize',default_fontsize-2,'fontweight','bold','horizontalalignment','left');
    prePath=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.55 .55 .3 .3],'Parent',presfig);
    preBrowse=uicontrol('Style', 'pushbutton','String','Browse','Units','norm','FontUnits','norm','FontSize',0.5,'Position',[.85 .55 .15 .3],'Parent',presfig, 'Callback',@preCall1);
    preConti=uicontrol('Style', 'pushbutton','String','Continue','Units','norm','FontUnits','norm','FontSize',0.5,'Position',[.3 .12 .15 .3],'Parent',presfig, 'Callback',@preCall2);
    preSkip=uicontrol('Style', 'pushbutton','String','Skip','Units','norm','FontUnits','norm','FontSize',0.5,'Position',[.55 .12 .15 .3],'Parent',presfig, 'Callback','uiresume');
    
    uiwait(presfig);
    ok=ishandle(presfig);
    if ~ok, return; end
    
    delete(presfig);
elseif ~manually_choose_config_file
    expRead = spm_jsonread('C:\docs\code\ieeg_stut\config\ieeg_stut_jackson20.json'); % default config file
    preFlag = true; 
end



% create structure to save experimental parameters
if preFlag
    expParams = expRead;
else % if no preset config file defined
    expParams=struct(...
        'visual', 'orthography', ...
        'root', pwd, ...
        'audiopath', fullfile(pwd, 'stimuli', 'audio', 'exp'), ...
        'figurespath', fullfile(pwd, 'stimuli', 'figures', 'Adults'), ...
        'subject','TEST01',...
        'session', 1, ...
        'run', 1,...
        'task', 'test', ...
        'gender', 'unspecified', ...
        'timePostStim', [.25 .75],...
        'timePostOnset', 4.5,...
        'timePreStim', .25,...
        'timeMax', 5.5, ...
        'timePreSound', .5, ...
        'timePostSound', .47, ...
        'rmsThresh', .02,... %'rmsThresh', .05,...
        'rmsBeepThresh', .1,...
        'rmsThreshTimeOnset', .02,...% 'rmsThreshTimeOnset', .10,...
        'rmsThreshTimeOffset', [.25 .25],...
        'minVoiceOnsetTime', 0.4, ...
        'deviceMic','',...
        'deviceHead',''...
        )
end

expParams.computer = host;
runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], expParams.run); % add zero padding

for n=1:2:numel(varargin)-1, 
    assert(isfield(expParams,varargin{n}),'unrecognized option %s',varargin{n});
    expParams.(varargin{n})=varargin{n+1};
end

try, a=audioDeviceReader('Device','asdf'); catch me; str=regexp(regexprep(me.message,'.*Valid values are:',''),'"([^"]*)"','tokens'); strINPUT=[str{:}]; end;
audiodevreset;
info=audiodevinfo;
strOUTPUT={info.output.Name};
try, a=audioDeviceWriter('Device','asdf'); catch me; str=regexp(regexprep(me.message,'.*Valid values are:',''),'"([^"]*)"','tokens'); strOUTPUT=[str{:}]; end;

% Look for default input and output indices
if contains(default_audio_in,'Focusrite')
    ipind = find(contains(strINPUT, 'Analogue')&contains(strINPUT, default_audio_in));
    opind = find(contains(strOUTPUT, 'Speakers')&contains(strOUTPUT, default_audio_out));
    tgind = find(contains(strOUTPUT, 'Playback')&contains(strOUTPUT, default_audio_out));
else
    ipind = find(contains(strINPUT, default_audio_in));
    opind = find(contains(strOUTPUT, default_audio_out));
    tgind = find(contains(strOUTPUT, default_audio_out));
end
    
strVisual={'figure', 'fixpoint', 'orthography'};

% GUI for user to modify options
fnames=fieldnames(expParams);
fnames=fnames(~ismember(fnames,{'visual', 'root', 'audiopath', 'figurespath', 'subject', 'session', 'run', 'task', 'gender', 'deviceMic','deviceHead','deviceScan'}));
for n=1:numel(fnames)
    val=expParams.(fnames{n});
    if ischar(val), fvals{n}=val;
    elseif isempty(val), fvals{n}='';
    else fvals{n}=mat2str(val);
    end
end

out_dropbox = {'visual', 'root', 'audiopath', 'figurespath', 'subject', 'session', 'run', 'task', 'gender'};
for n=1:numel(out_dropbox)
    val=expParams.(out_dropbox{n});
    if ischar(val), fvals_o{n}=val;
    elseif isempty(val), fvals_o{n}='';
    else fvals_o{n}=mat2str(val);
    end
end

default_width = 0.04; %0.08;
default_intvl = 0.05; %0.10;

thfig=dialog('units','norm','position',[.3,.3,.3,.5],'windowstyle','normal','name','FLvoice_run options','color','w','resize','on');
uicontrol(thfig,'style','text','units','norm','position',[.1,.92,.8,default_width],'string','Experiment information:','backgroundcolor','w','fontsize',default_fontsize,'fontweight','bold');

ht_txtlist = {};
ht_list = {};
for ind=1:size(out_dropbox,2)
    ht_txtlist{ind} = uicontrol(thfig,'style','text','units','norm','position',[.1,.75-(ind-3)*default_intvl,.35,default_width],'string',[out_dropbox{ind}, ':'],'backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
    if strcmp(out_dropbox{ind}, 'visual')
        ht_list{ind} = uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-(ind-3)*default_intvl,.4,default_width],'string', strVisual, 'value',find(strcmp(strVisual, expParams.visual)),'fontsize',default_fontsize-1,'callback',@thfig_callback4);
    else
        ht_list{ind} = uicontrol(thfig,'style','edit','units','norm','position',[.5,.75-(ind-3)*default_intvl,.4,default_width],'string', fvals_o{ind}, 'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1,'callback',@thfig_callback3);
    end
end

ht1=uicontrol(thfig,'style','popupmenu','units','norm','position',[.1,.75-8*default_intvl,.4,default_width],'string',fnames,'value',1,'fontsize',default_fontsize-1,'callback',@thfig_callback1);
ht2=uicontrol(thfig,'style','edit','units','norm','position',[.5,.75-8*default_intvl,.4,default_width],'string','','backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1,'callback',@thfig_callback2);

uicontrol(thfig,'style','text','units','norm','position',[.1,.75-9*default_intvl,.35,default_width],'string','Microphone:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
ht3a=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-9*default_intvl,.4,default_width],'string',strINPUT,'value',ipind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);

uicontrol(thfig,'style','text','units','norm','position',[.1,.75-10*default_intvl,.35,default_width],'string','Sound output:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
ht3b=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-10*default_intvl,.4,default_width],'string',strOUTPUT,'value',opind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);

ht3c0=uicontrol(thfig,'style','text','units','norm','position',[.1,.75-11*default_intvl,.35,default_width],'string','Scanner trigger:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
ht3c=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-11*default_intvl,.4,default_width],'string',strOUTPUT,'value',tgind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);

uicontrol(thfig,'style','pushbutton','string','Start','units','norm','position',[.1,.01,.38,.10],'callback','uiresume','fontsize',default_fontsize-1);
uicontrol(thfig,'style','pushbutton','string','Cancel','units','norm','position',[.51,.01,.38,.10],'callback','delete(gcbf)','fontsize',default_fontsize-1);

ind2 = find(strcmp(out_dropbox, 'figurespath'));
if ~strcmp(expParams.visual, 'figure'), set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'off'); end


thfig_callback1;
    function thfig_callback1(varargin)
        tn=get(ht1,'value');
        set(ht2,'string',fvals{tn});
    end
    function thfig_callback2(varargin)
        tn=get(ht1,'value');
        fvals{tn}=get(ht2,'string');
    end
    function thfig_callback3(varargin)
        for tn=1:size(out_dropbox,2)
            if strcmp(out_dropbox{tn}, 'visual'), continue; end
            fvals_o{tn}=get(ht_list{tn}, 'string');
            if strcmp(out_dropbox{tn},'scan')
                if isequal(str2num(fvals_o{tn}),0), set([ht3c0,ht3c],'visible','off'); 
                else set([ht3c0,ht3c],'visible','on'); 
                end
            end
        end
    end
    function thfig_callback4(varargin)
        ind = find(strcmp(out_dropbox, 'visual'));
        choice=get(ht_list{ind}, 'value');
        fvals_o{ind}=strVisual{choice};
        ind2 = find(strcmp(out_dropbox, 'figurespath'));
        if ~strcmp(strVisual{choice}, 'figure')
            set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'off'); 
        else 
            set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'on');
        end
    end

uiwait(thfig);
ok=ishandle(thfig);
if ~ok, return; end
expParams.deviceMic=strINPUT{get(ht3a,'value')};
expParams.deviceHead=strOUTPUT{get(ht3b,'value')};
expParams.deviceScan=strOUTPUT{get(ht3c,'value')};
delete(thfig);
for n=1:numel(fnames)
    val=fvals{n};
    if ischar(expParams.(fnames{n})), expParams.(fnames{n})=val;
    elseif isempty(val), expParams.(fnames{n})=[];
    else
        assert(~isempty(str2num(val)),'unable to interpret string %s',val);
        expParams.(fnames{n})=str2num(val);
    end
end
for n=1:numel(out_dropbox)
    val=fvals_o{n};
    if ischar(expParams.(out_dropbox{n})), expParams.(out_dropbox{n})=val;
    elseif isempty(val), expParams.(out_dropbox{n})=[];
    else
        assert(~isempty(str2num(val)),'unable to interpret string %s',val);
        expParams.(out_dropbox{n})=str2num(val);
    end
end

% visual setup
annoStr = setUpVisAnnot_HW(op);
annoStr.Stim.FontSize = op.ortho_font_size; 

CLOCKp = ManageTime('start');
TIME_PREPARE = 0.5; % Waiting period before experiment begin (sec)
set(annoStr.Stim, 'String', 'Preparing...');
set(annoStr.Stim, 'Visible','on');



% locate files
dirs.task = fullfile(expParams.root, sprintf('sub-%s',expParams.subject), sprintf('ses-%d',expParams.session),'beh', expParams.task);
dirs.run = [dirs.task, filesep, 'run-',runstring]; 
mkdir(dirs.run) % make directory for trial files in this run
Input_audname  = fullfile(dirs.task,sprintf('sub-%s_ses-%d_task-%s_run-%s_desc-stimulus.txt',expParams.subject, expParams.session, expParams.task, runstring));
Input_condname  = fullfile(dirs.task,sprintf('sub-%s_ses-%d_task-%s_run-%s_desc-conditions.txt',expParams.subject, expParams.session, expParams.task, runstring));
desc_audio_filename = fullfile(dirs.task,sprintf('sub-%s_ses-%d_task-%s_run-%s_desc-audio.mat',expParams.subject, expParams.session, expParams.task, runstring));
assert(~isempty(dir(Input_audname)), 'unable to find input file %s',Input_audname);
if ~isempty(dir(desc_audio_filename))&&~isequal('Yes - overwrite', questdlg(sprintf('This subject %s already has a data file for this ses-%d_run-%s (task: %s), do you want to overwrite?',...
        expParams.subject, expParams.session, runstring, expParams.task),'Answer', 'Yes - overwrite', 'No - quit','No - quit')), return; end
% read audio files and condition labels
Input_files=regexp(fileread(Input_audname),'[\n\r]+','split');

Input_files_temp=Input_files(cellfun('length',Input_files)>0);
NoNull = find(~strcmp(Input_files_temp, 'NULL'));

% load words table
trials_words_file = [dirs.task, filesep, 'sub-',expParams.subject, '_ses-',num2str(expParams.session), '_task-',expParams.task, '_run-',runstring, '_trials-words.tsv'];
trials_words = readtable(trials_words_file,'FileType','text','Delimiter','\t'); % must specify delimiter or certain characters like ? cause problems

if ispc
    Input_files=arrayfun(@(x)fullfile(expParams.audiopath, expParams.task, strcat(strrep(x, '/', '\'), '.wav')), Input_files_temp);
else
    Input_files=arrayfun(@(x)fullfile(expParams.audiopath, expParams.task, strcat(x, '.wav')), Input_files_temp);
end


if strcmp(expParams.visual, 'figure')
    All_figures_str = dir(fullfile(expParams.figurespath, '*.png'));
    All_figures = arrayfun(@(x)fullfile(All_figures_str(x).folder, All_figures_str(x).name), 1:length(All_figures_str), 'uni', 0);
    figures=arrayfun(@(x)fullfile(expParams.figurespath, strcat(x, '.png')), Input_files_temp);
    figureseq=arrayfun(@(x)find(strcmp(All_figures, x)), figures, 'uni', 0);
    if sum(arrayfun(@(x)isempty(figureseq{x}), 1:length(figureseq))) ~= 0
        disp('Some images not found or image names don''t match');
        return
    end
end

ok=cellfun(@(x)exist(x,'file'), Input_files(NoNull));
assert(all(ok), 'unable to find files %s', sprintf('%s ',Input_files{NoNull(~ok)}));
dirFiles=cellfun(@dir, Input_files(NoNull), 'uni', 0);
NoNull=NoNull(cellfun(@(x)x.bytes>0, dirFiles));
Input_sound=cell(size(Input_files));
Input_fs=num2cell(ones(size(Input_files)));
[Input_sound(NoNull),Input_fs(NoNull)]=cellfun(@audioread, Input_files(NoNull),'uni',0);
[silent_sound,silent_fs]=audioread(fullfile(expParams.audiopath, 'silent.wav'));
stimreads=cell(size(Input_files));
stimreads(NoNull)=cellfun(@(x)dsp.AudioFileReader(x, 'SamplesPerFrame', 2048),Input_files(NoNull),'uni',0);
stimreads(setdiff(1:numel(stimreads), NoNull))=arrayfun(@(x)dsp.AudioFileReader(fullfile(expParams.audiopath, 'silent.wav'), 'SamplesPerFrame', 2048),1:numel(Input_files(setdiff(1:numel(stimreads), NoNull))),'uni',0);
sileread = dsp.AudioFileReader(fullfile(expParams.audiopath, 'silent.wav'), 'SamplesPerFrame', 2048);

if isempty(dir(Input_condname))
    [nill,Input_conditions]=arrayfun(@fileparts,Input_files,'uni',0);
else
    Input_conditions=regexp(fileread(Input_condname),'[\n\r]+','split');
    Input_conditions=Input_conditions(cellfun('length',Input_conditions)>0);
    assert(numel(Input_files)==numel(Input_conditions),'unequal number of lines/trials in %s (%d) and %s (%d)',Input_audname, numel(Input_files), Input_condname, numel(Input_conditions));
end
expParams.numTrials = length(Input_conditions); % pull out the number of trials from the stimList

Input_duration=cellfun(@(a,b)numel(a)/b, Input_sound, Input_fs);
%meanInput_duration=mean(Input_duration(Input_duration>0));
silence_dur=size(silent_sound,1)/silent_fs;
[Input_sound{Input_duration==0}]=deal(zeros(ceil(44100*silence_dur),1)); % fills empty audiofiles with average-duration silence ('NULL' CONDITIONS)
[Input_fs{Input_duration==0}]=deal(44100);
[Input_conditions{Input_duration==0}]=deal('NULL');

% create random number stream so randperm doesn't call the same thing everytime when matlab is opened
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setGlobalStream(s);

% set audio device variables: deviceReader: mic input; beepPlayer: beep output; triggerPlayer: trigger output
if isempty(expParams.deviceMic)
    disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,strINPUT{n}),1:numel(strINPUT),'uni',0))); ID=input('MICROPHONE input device # : ');
    expParams.deviceMic=strINPUT{ID};
end
if ~ismember(expParams.deviceMic, strINPUT), expParams.deviceMic=strINPUT{find(strncmp(lower(expParams.deviceMic),lower(strINPUT),numel(expParams.deviceMic)),1)}; end
assert(ismember(expParams.deviceMic, strINPUT), 'unable to find match to deviceMic name %s',expParams.deviceMic);
if isempty(expParams.deviceHead)||(expParams.scan&&isempty(expParams.deviceScan))
    %disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,info.output(n).Name),1:numel(info.output),'uni',0)));
    disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,strOUTPUT{n}),1:numel(strOUTPUT),'uni',0)));
    if isempty(expParams.deviceHead),
        ID=input('HEADPHONES output device # : ');
        expParams.deviceMic=strOUTPUT{ID};
    end
end
% set up device reader settings for accessing audio signal during recording
expParams.sr = 48000;            % sample frequenct (Hz)
frameDur = .050;                 % frame duration in seconds
expParams.frameLength = expParams.sr*frameDur;      % framelength in samples
deviceReader = audioDeviceReader(...
    'Device', expParams.deviceMic, ...
    'SamplesPerFrame', expParams.frameLength, ...
    'SampleRate', expParams.sr, ...
    'BitDepth', '24-bit integer');    
% set up sound output players
if ~ismember(expParams.deviceHead, strOUTPUT), expParams.deviceHead=strOUTPUT{find(strncmp(lower(expParams.deviceHead),lower(strOUTPUT),numel(expParams.deviceHead)),1)}; end
assert(ismember(expParams.deviceHead, strOUTPUT), 'unable to find match to deviceHead name %s',expParams.deviceHead);
[ok,ID]=ismember(expParams.deviceHead, strOUTPUT);
beepfile = [dirs.stim, filesep, 'audio', filesep, expParams.task, filesep, 'green_screen_beep.wav'];
[twav, tfs] = audioread(beepfile);
beepdur = numel(twav)/tfs;
%stimID=info.output(ID).ID;
% beepPlayer = audioplayer(twav*0.2, tfs, 24, info.output(ID).ID);
beepread = dsp.AudioFileReader(beepfile, 'SamplesPerFrame', 2048);
% headwrite = audioDeviceWriter('SampleRate',beepread.SampleRate,'Device',expParams.deviceHead, 'SupportVariableSizeInput', true, 'BufferSize', 2048);
headwrite = audioDeviceWriter('SampleRate',beepread.SampleRate,'Device',expParams.deviceHead);

% checks values of timing variables
expParams.beepoffset = beepoffset;

if numel(expParams.timePostStim)==1, expParams.timePostStim=expParams.timePostStim+[0 0]; end
if numel(expParams.timePostOnset)==1, expParams.timePostOnset=expParams.timePostOnset+[0 0]; end
if numel(expParams.timePreStim)==1, expParams.timePreStim=expParams.timePreStim+[0 0]; end
if numel(expParams.timeMax)==1, expParams.timeMax=expParams.timeMax+[0 0]; end
expParams.timePostStim=sort(expParams.timePostStim);
expParams.timePostOnset=sort(expParams.timePostOnset);
expParams.timePreStim=sort(expParams.timePreStim);
expParams.timeMax=sort(expParams.timeMax);
rmsThresh = expParams.rmsThresh; % params for detecting voice onset %voiceCal.rmsThresh; % alternatively, run a few iterations of testThreshold and define rmsThreshd here with the resulting threshold value after convergence
rmsBeepThresh = expParams.rmsBeepThresh;
% nonSpeechDelay = .75; % initial estimate of time between go signal and voicing start
nonSpeechDelay = .5; % initial estimate of time between go signal and voicing start

%%%%% set up figure for real-time plotting of audio signal of next trial
if show_mic_trace_figure
    rtfig = figure('units','norm','position',[.1 .2 .4 .5],'menubar','none', 'Visible',show_mic_trace_figure);
    micSignal = plot(nan,nan,'-', 'Color', [0 0 0.5]);
    micLine = xline(0, 'Color', [0.984 0.352 0.313], 'LineWidth', 3);
    micLineB = xline(0, 'Color', [0.46 1 0.48], 'LineWidth', 3);
    micTitle = title('', 'Fontsize', default_fontsize-1, 'interpreter','none');
    xlabel('Time(s)');
    ylabel('Sound Pressure');
end

% set up picture display

if strcmp(expParams.visual, 'figure'), imgBuf = arrayfun(@(x)imread(All_figures{x}), 1:length(All_figures),'uni',0); end

pause(1);
save(desc_audio_filename, 'expParams');

%Initialize trialData structure
trialData = struct;

ok=ManageTime('wait', CLOCKp, TIME_PREPARE);
set(annoStr.Stim, 'Visible','off');     % Turn off preparation page
TIME_PREPARE_END=ManageTime('current', CLOCKp);

set(annoStr.Stim, 'String', 'READY');
set(annoStr.Stim, 'Visible','on');
while ~isDone(sileread); sound=sileread();headwrite(sound);end;release(sileread);reset(headwrite);
ok=ManageTime('wait', CLOCKp, TIME_PREPARE_END+2);
set(annoStr.Stim, 'Visible','off');     % Turn off preparation page
CLOCK=[];                               % Main clock (not yet started)
expParams.timeNULL = expParams.timeMax(1) + diff(expParams.timeMax).*rand;
intvs = [];

%% LOOP OVER TRIALS
for itrial = 1:expParams.numTrials

    set(annoStr.Plus, 'Visible','on');
    
    % print current and upcoming stimulus questions 
    % print trial number and total trials
    if itrial ~= expParams.numTrials % if not last trial
        next_trial_string = ['\n      Next trials question/word will be:\n ''', trials_words.question{itrial+1}, ''' /// ''', trials_words.word{itrial+1}, ''''];
    elseif itrial == expParams.numTrials % if last trial
        next_trial_string = '';
    end
    fprintf([...
        '\nThis trial''s stimulus question: ''', trials_words.question{itrial}, '''', ...
        '\n      Answer = ''',trials_words.word{itrial}, '''',...
        '\n      ........ Trial ', num2str(itrial), '/' num2str(expParams.numTrials), ', Run ', num2str(expParams.run), ...
        next_trial_string,...
        '\n      As you finish asking this trial''s question, please press Spacebar to start the ', num2str(op.anticipation_dur_sec), ' second anticipation period',...
        '\n']);

    %%% for the 'Answer-Question' veresion of the task to be run remotely, show preview of answer
    if op.preview_answer_to_subject %%% if true, orthography of the expected answer will be shown to the subject before investigator asks question
        set(annoStr.Stim,'String',trials_words.word{itrial})
        set(annoStr.Stim,'FontSize', op.ortho_font_size); 
        set(annoStr.Stim,'Visible','on'); 

        pause(op.preview_answer_duration) % time allowed for subject to read Answer on screen

        set(annoStr.Stim,'Visible','off'); 
        set(annoStr.Plus, 'Visible','on'); % switch back to fixation cross - cue for investigator to start asking question
    end



    % % % % % % % if (mod(itrial,op.ntrials_between_breaks) == 0) && (itrial ~= expParams.numTrials)  % Break after every X trials  , but not on the last
    % % % % % % %     pause()
    % % % % % % % 
    % % % % % % % end

    % pause at the beginning of every trial while experimenter asks question....
    % .... after they press any key, proceed to anticipation period 
    pause()

    pause(op.anticipation_dur_sec - op.experimenter_warning_latency_sec) % anticipation delay period
    fprintf(['\nGO cue will appear in ' num2str(op.experimenter_warning_latency_sec) ' seconds. Please look toward the subject now.\n'])
    pause(op.experimenter_warning_latency_sec) 

    
    trialData(itrial).stimName = Input_files{itrial};
    trialData(itrial).condLabel = Input_conditions{itrial};
    [fp, nm, ext] = fileparts(Input_files{itrial});
    trialData(itrial).display = upper(nm);
    if strcmp(trialData(itrial).display, 'NULL'); trialData(itrial).display = 'yyy'; end
%     trialData(ii).timeStim = numel(Input_sound{ii})/Input_fs{ii}; 
    trialData(itrial).timeStim = size(Input_sound{itrial},1)/Input_fs{itrial}; 
    trialData(itrial).timePostStim = expParams.timePostStim(1) + diff(expParams.timePostStim).*rand; 
    trialData(itrial).timePostOnset = expParams.timePostOnset(1) + diff(expParams.timePostOnset).*rand; 
    trialData(itrial).timePreStim = expParams.timePreStim(1) + diff(expParams.timePreStim).*rand; 
    trialData(itrial).timeMax = expParams.timeMax(1) + diff(expParams.timeMax).*rand; 
    trialData(itrial).timePostSound = expParams.timePostSound;
    trialData(itrial).timePreSound = expParams.timePreSound;
    %stimPlayer = audioplayer(Input_sound{ii},Input_fs{ii}, 24, stimID);
    stimread = stimreads{itrial};
    SpeechTrial=~strcmp(trialData(itrial).condLabel,'NULL');
%     SpeechTrial=~strcmp(trialData(ii).condLabel,'S');

    % set up variables for audio recording and voice detection
    recordLen= trialData(itrial).timeMax; % max total recording time
    recordLenNULL = expParams.timeNULL;
    nSamples = ceil(recordLen*expParams.sr);
    nSamplesNULL = ceil(recordLenNULL*expParams.sr);
    time = 0:1/expParams.sr:(nSamples-1)/expParams.sr;
    recAudio = zeros(nSamples,1);       % initialize variable to store audio
    nMissingSamples = 0;                % cumulative n missing samples between frames
    beepDetected = 0;
    voiceOnsetDetected = 0;             % voice onset not yet detected
    frameCount = 1;                     % counter for # of frames (starting at first frame)
    endIdx = 0;                         % initialize idx for end of frame
    voiceOnsetState = [];
    beepOnsetState = [];
        
    % set up figure for real-time plotting of audio signal of next trial
    if show_mic_trace_figure
        figure(rtfig)
        set(micTitle,'string',sprintf('%s %s run %d trial %d condition: %s', expParams.subject, expParams.task, expParams.run, itrial, trialData(itrial).condLabel));
    end

        
    %t = timer;
    %t.StartDelay = 0.050;   % Delay between timer start and timer function
    %t.TimerFcn = @(myTimerObj, thisEvent)play(beepPlayer); % Timer function plays GO signal
    setup(deviceReader) % note: moved this here to avoid delays in time-sensitive portion

    if isempty(CLOCK)
        CLOCK = ManageTime('start');                        % resets clock to t=0 (first-trial start-time)
        TIME_TRIAL_START = 0;
        TIME_STIM_START = 0;
    else
        TIME_TRIAL_START = ManageTime('current', CLOCK);
    end



    TIME_GOSIGNAL_ACTUALLYSTART = ManageTime('current', CLOCK); % actual time for GO signal 


% show the green GO screen
        set(annoStr.Plus, 'Visible','off');
        imshow(imgBuf{figureseq{itrial}}, 'Parent', annoStr.Pic);

    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if strcmp(expParams.visual, 'fixpoint'),set(annoStr.Plus, 'color','g');drawnow;end
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if strcmp(expParams.visual, 'orthography'),set(annoStr.Plus, 'color','g');drawnow;end
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if ~ok, fprintf('i am late for this trial TIME_GOSIGNAL_START\n'); end
    TIME_VOICE_START = TIME_GOSIGNAL_ACTUALLYSTART + nonSpeechDelay;                   % expected voice onset time


    endSamples = SpeechTrial * nSamples + (1-SpeechTrial)*nSamplesNULL;
    while endIdx < endSamples
        % find beginning/end indices of frame
        begIdx = (frameCount*expParams.frameLength)-(expParams.frameLength-1) + nMissingSamples;
        endIdx = (frameCount*expParams.frameLength) + nMissingSamples;

        % read audio data
        [audioFromDevice, numOverrun] = deviceReader();     % read one frame of audio data % note: audio t=0 corresponds to first call to deviceReader, NOT to time of setup(...)
        numOverrun = double(numOverrun);    % convert from uint32 to type double
        if numOverrun > 0, recAudio(begIdx:begIdx+numOverrun-1) = 0; end      % set missing samples to 0
        recAudio(begIdx+numOverrun:endIdx+numOverrun) = audioFromDevice;    % save frame to audio vector
        nMissingSamples = nMissingSamples + numOverrun;     % keep count of cumulative missng samples between frames

        % plot audio data
        if show_mic_trace_figure
            set(micSignal, 'xdata',time, 'ydata',recAudio(1:numel(time)))
        end
        drawnow()

        % voice onset exclusion
        minVoiceOnsetTime = max(0, expParams.minVoiceOnsetTime-(begIdx+numOverrun)/expParams.sr);
        
        % detect beep onset
        if SpeechTrial && beepDetected == 0 && expParams.minVoiceOnsetTime > (begIdx+numOverrun)/expParams.sr
            % look for beep onset
            [beepDetected, bTime, beepOnsetState]  = detectVoiceOnset(recAudio(begIdx+numOverrun:endIdx+numOverrun), expParams.sr, expParams.rmsThreshTimeOnset, rmsBeepThresh, 0, beepOnsetState);
            if beepDetected
                beepTime = bTime + (begIdx+numOverrun)/expParams.sr; 
                 if show_mic_trace_figure
                    set(micLineB,'value',beepTime,'visible','on');
                 end
            end
        elseif SpeechTrial && voiceOnsetDetected == 0,% && frameCount > onsetWindow/frameDur
            if ~beepDetected; beepTime = 0; 
                % disp('Beep not detected. Assign beepTime = 0.'); 
            end
            trialData(itrial).beepTime = beepTime;

            % look for voice onset in previous onsetWindow
            [voiceOnsetDetected, voiceOnsetTime, voiceOnsetState]  = detectVoiceOnset(recAudio(begIdx+numOverrun:endIdx+numOverrun), expParams.sr, expParams.rmsThreshTimeOnset, rmsThresh, minVoiceOnsetTime, voiceOnsetState);
            % update voice onset time based on index of data passed to voice onset function

            if voiceOnsetDetected
                voiceOnsetTime = voiceOnsetTime + (begIdx+numOverrun)/expParams.sr - beepTime;
                TIME_VOICE_START = TIME_GOSIGNAL_ACTUALLYSTART + voiceOnsetTime; % note: voiceonsetTime marks the beginning of the minThreshTime window
                nonSpeechDelay = .5*nonSpeechDelay + .5*voiceOnsetTime;  % running-average of voiceOnsetTime values, with alpha-parameter = 0.5 (nonSpeechDelay = alpha*nonSpeechDelay + (1-alph)*voiceOnsetTime; alpha between 0 and 1; alpha high -> slow update; alpha low -> fast update)
                TIME_SCAN_START =  TIME_VOICE_START + trialData(itrial).timePostOnset;
                nSamples = min(nSamples, ceil((TIME_SCAN_START-TIME_GOSIGNAL_ACTUALLYSTART)*expParams.sr));
                endSamples = nSamples;
                % add voice onset to plot
                if show_mic_trace_figure
                    set(micLine,'value',voiceOnsetTime + beepTime,'visible','on');
                    
                   
                end
                drawnow update
            end

        end

        frameCount = frameCount+1;

    end
    if SpeechTrial && voiceOnsetDetected == 0 
        % fprintf('warning: voice was expected but not detected (rmsThresh = %f)\n',rmsThresh); 
    end
    release(deviceReader); % end recording
    
    switch expParams.visual
        % % % % % % % % % % % case 'fixpoint'
        % % % % % % % % % % %     set(annoStr.Plus, 'color','w');
        case 'figure'
            imshow([], 'Parent', annoStr.Pic);
        % % % % % % % % case 'orthography'
        % % % % % % % %     set(annoStr.Plus, 'color','w');
    end


    
    
   
    %stop(t);
    %delete(t);

    %% save voice onset time and determine how much time left before sending trigger to scanner
    if voiceOnsetDetected == 0 %if voice onset wasn't detected
        trialData(itrial).onsetDetected = 0;
        trialData(itrial).voiceOnsetTime = NaN;
        trialData(itrial).nonSpeechDelay = nonSpeechDelay;
    else
        trialData(itrial).onsetDetected = 1;
        trialData(itrial).voiceOnsetTime = voiceOnsetTime;
        trialData(itrial).nonSpeechDelay = NaN;
    end


        TIME_SCAN_ACTUALLYSTART=nan;
        %TIME_TRIG_RELEASED = nan;
        TIME_SCAN_END = nan;
        % NEXTTRIAL = TIME_SCAN_START + trialData(itrial).timePreStim;

        
    trialData(itrial).timingTrial = [TIME_GOSIGNAL_ACTUALLYSTART;TIME_VOICE_START];
    expParams.timingTrialNames = split('TIME_GOSIGNAL_ACTUALLYSTART;TIME_VOICE_START', ';');


    % DON'T adapt rmsThresh
%     if 1, %isfield(expParams,'voiceCal')&&expParams.voiceCal.threshType == 1
%         if SpeechTrial   % If the current trial is not a baseline trial
%             rmsFF=.90; winDur=.002; winSize=ceil(winDur*expParams.sr); % note: match rmsFF and rmsFrameDur values to those in detectVoiceOnset.m
%             rms=sqrt(mean(reshape(recAudio(1:floor(nSamples/winSize)*winSize),winSize,[]).^2,1));
%             rms=filter(1,[1 -rmsFF],(1-rmsFF)*rms); % note: just like "rms(1)=0+(1-rmsFF)*rms(1); for n=2:numel(rms), rms(n)=rmsFF*rms(n-1)+(1-rmsFF)*rms(n); end"
%             if  voiceOnsetDetected    % voice onset detected
%                 minRms = prctile(rms,10);
%                 maxRms = prctile(rms(max(1,ceil(voiceOnsetTime/winDur)):end),90);
%             else
%                 minRms = 0;
%                 maxRms = prctile(rms,90);
%             end
%             tmpRmsThresh = minRms + (maxRms-minRms)/10;
%             rmsThresh = .9*rmsThresh + .1*tmpRmsThresh
%         end
%     end

    %% save for each trial
    trialData(itrial).s = recAudio(1:nSamples);
    trialData(itrial).fs = expParams.sr;
    if SpeechTrial&&voiceOnsetDetected, trialData(itrial).reference_time = voiceOnsetTime;
    else trialData(itrial).reference_time = nonSpeechDelay;
    end
    trialData(itrial).percMissingSamples = (nMissingSamples/(recordLen*expParams.sr))*100;

    %JT save update test 8/10/21
    % save only data from current trial
    tData = trialData(itrial);

    % fName_trial will be used for individual trial files (which will
    % live in the run folder)
    fName_trial = fullfile(dirs.run,sprintf('sub-%s_ses-%d_task-%s_run-%s_trial-%d.mat',expParams.subject, expParams.session, expParams.task, runstring, itrial));
    save(fName_trial,'tData');
end

release(headwrite);
release(beepread);


%% end of experiment
close all

% experiment time
expParams.elapsed_time = toc(ET)/60;    % elapsed time of the experiment
fprintf('\nElapsed Time: %f (min)\n', expParams.elapsed_time)
save(desc_audio_filename, 'expParams', 'trialData');

% number of trials with voice onset detected
onsetCount = nan(expParams.numTrials,1);
for j = 1: expParams.numTrials
    onsetCount(j) = trialData(j).onsetDetected;
end
numOnsetDetected = sum(onsetCount);    

fprintf('Voice onset detected on %d/%d trials\n', numOnsetDetected, expParams.numTrials);

fprinft('Press any key to send final sync pulses and end this experimental phase')
pause()

end




function [voiceOnsetDetected, voiceOnsetTime, state]  = detectVoiceOnset(samples, Fs, onDur, onThresh, minVoiceOnsetTime, state)
% function [voiceOnsetDetected, voiceOnsetTime]  = detectVoiceOnset(samples, Fs, onDur, onThresh, minVoiceOnsetTime)
% 
% Function to detect onset of speech production in an audio recording.
% Input samples can be from a whole recording or from individual frames.
%
% INPUTS        samples                 vector of recorded samples
%               Fs                      sampling frequency of samples
%               onDur                   how long the intensity must exceed the
%                                       threshold to be considered an onset (s)
%               onThresh                onset threshold
%               minVoiceOnsetTime       time (s) before which voice onset
%                                       cannot be detected (due to
%                                       anticipation errors, throat
%                                       clearing etc) - often set to .09 at
%                                       beginning of recording/first frame
%
% OUTPUTS       voiceOnsetDetected      0 = not detected, 1 = detected
%               voiceOnsetTime          time (s) when voice onset occurred
%                                       (with respect of first sample)
%
% Adapted from ACE study in Jan 2021 by Elaine Kearney (elaine-kearney.com)
% Matlab 2019a 
%
%%

% set up parameters
winSize = ceil(Fs * .002);                  % analysis window = # samples per 2 ms (matched to Audapter frameLen=32 samples @ 16KHz)
Incr = ceil(Fs * .002);                     % # samples to increment by (2 ms)
rmsFF = 0.90;                               % forgetting factor (Audapter's ma_rms computation)
BegWin = 1;                                 % first sample in analysis window
EndWin = BegWin + winSize -1;               % last sample in analysis window
voiceOnsetDetected = false;                 % voice onset (not yet detected)
voiceOnsetTime = [];                        % variable for storing voice onset time
if nargin<5||isempty(minVoiceOnsetTime), minVoiceOnsetTime = 0; end % minimum voice onset time
if nargin<6||isempty(state), state=struct('rms',0,'count',0); end   % rms: last-call rms value; count: last-call number of supra-threshold rms values

% main loop
while EndWin <= length(samples)
    
    dat = samples(BegWin:EndWin);
    %dat = detrend(dat, 0);                 % legacy step: removes mean value from data in analysis window
    %dat = convn(dat,[1;-.95]);             % legacy step: applies a high pass filter to the data
                                            % and may reduce sensitivity to production onset,
                                            % especially if stimulus starts with a voiceless consonant
    int = mean(dat.^2);                      % mean of squares
    state.rms =  rmsFF*state.rms+(1-rmsFF)*sqrt(int);            % calculate moving-average rms (calcRMS1 function)
    if state.rms > onThresh && BegWin > minVoiceOnsetTime*Fs
        state.count = state.count + 1;
    else
        state.count = 0;
    end
    
    % criteria for voice onset:
    % (1) onThresh must have been continuously exceeded for the duration of onDur
    % (2) time of voice onset is greater than minVoiceOnsetTime
    
    if state.count >= onDur*Fs/Incr
        voiceOnsetDetected = true;                              % onset detected
        voiceOnsetTime = (BegWin-(state.count-1)*Incr-1)/Fs;    % time when onThresh was first reached
        break
    end
    
    % increment analysis window and iteration by 1 (until voice onset detected)
    BegWin = BegWin + Incr;          
    EndWin = EndWin + Incr;

    % pause(12)
end

end


function out = ManageTime(option, varargin)
% MANAGETIME time-management functions for real-time operations
%
% CLCK = ManageTime('start');             initializes clock to t=0
% T = ManageTime('current', CLCK);        returns current time T (measured in seconds after t=0)
% ok = ManageTime('wait', CLCK, T);       waits until time = T (measured in seconds after t=0)
%                                         returns ok=false if we were already passed T
%
% e.g.
%  CLCK = ManageTime('start');
%  ok = ManageTime('wait', CLCK, 10);
%  disp(ManageTime('current', CLCK));
%  disp(ManageTime('current', CLCK));
%  disp(ManageTime('current', CLCK));
%

DEBUG=false;
switch(lower(option))
    case 'start',
        out=clock;
    case 'wait'        
        out=true;
        t0=varargin{1};
        t1=varargin{2};
        t2=etime(clock,t0);
        if DEBUG, fprintf('had %f seconds to spare\n',t1-t2); end
        if t2>t1, out=false; return; end % i am already late
        if t1-t2>1, pause(t1-t2-1); end % wait until ~1s to go (do not waste CPU)
        while etime(clock,t0)<t1, end % wait until exactly the right time (~ms prec)
    case 'current'
        t0=varargin{1};
        out=etime(clock,t0);
end
end

        



