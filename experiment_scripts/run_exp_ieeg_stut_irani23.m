% run stuttering elicitation protocol adapted from: 
%%% Irani et al., 2023 - https://doi.org/10.1016/j.jcomdis.2023.106353 
%
% stimulus script adapted from Guenther Lab FLVoice package

close all;

CMRR = true;

% set priority for matlab to high for running experiments
system(sprintf('wmic process where processid=%d call setpriority "high priority"', feature('getpid')));



%%%%%%%%%%%%%%% comments below mostly apply to original FLVoice_run script, not irani23 protocol
%% FLVoice help text 

% FLVOICE_RUN runs audio recording&scanning session
% [task]: 'train' or 'test'
% 
% INPUT:
%    [root]/sub-[subject]/ses-[session]/beh/[task]/sub-[subject]_ses-[session]_run-[run]_task-[task]_desc-stimulus.txt     : INPUT list of stimulus NAMES W/O suffix (one trial per line; enter the string NULL or empty audiofiles for NULL -no speech- conditions)
%    [root]/sub-[subject]/ses-[session]/beh/[task]/sub-[subject]_ses-[session]_run-[run]_task-[task]_desc-conditions.txt   : (optional) INPUT list of condition labels (one trial per line)
%                                                                                                                     if unspecified, condition labels are set to stimulus filename
%    [audiopath]/[task]/                       : path for audio stimulus files (.wav)
%    [figurespath]/                            : path for image stimulus files (.png) [if any]
%    The above should match names in stimulus.txt
%
% OUTPUT:
%    [root]/sub-[subject]/ses-[session]/beh/[task]/sub-[subject]_ses-[session]_run-[run]_task-[task]_desc-audio.mat        : OUTPUT audio data (see FLVOICE_IMPORT for format details) 
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
%       gender                      : subject gender ['unspecified']
%       scan                        : true/false include scanning segment in experiment sequence [1] 
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
%       ipatDur                     : prescan sequence: prescan IPAT duration (s) [4.75] 
%       smsDur                      : prescan sequence: prescan SMS duration (s) [7] 
%       deviceMic                   : device name for sound input (microphone) (see audiodevinfo().input.Name for details)
%       deviceHead                  : device name for sound output (headphones) (see audiodevinfo().output.Name for details) 
%       deviceScan                  : device name for scanner trigger (see audiodevinfo().output.Name for details)
%

%% params 

[dirs, host] = set_paths_ieeg_stut(); 
vardefault('op',struct);
% field_default('op','sub','qqq');
% field_default('op','ses',1); 

% op.sub = 'qqq'; 
op.sub = 'pilot012'; 
% op.sub = 'DM1049';
% op.sub = 'sap006';  

op.ses = 2; 

op.show_mic_trace_figure = 0; % if false, make mic trace figure invisible
        
% op.get_ready_stim_dur = 1; % duration in sec of the visual stimulus occurring before speech onset
op.get_ready_stim_dur = 1.7; % duration in sec of the visual stimulus occurring before speech onset


op.prespeech_delay_dur = 0.5; % time in sec between offset of get-ready visual stim and the GO stim triggering speech onset

op.go_stim_dur = 5.5; % duration in sec of visual cue instructing speech onset

op.task = 'irani23'; 

%%%%%%%%%%%% stimulus paradigm - see irani ea 2023, fig 1
% op.stim_prdm = 'word_go'; % get-ready cue = word orthography..... GO cue = "!!!"
op.stim_prdm = 'cue_word'; % get-ready cue = "+".... GO cue = word orthography


op.ntrials = 50; 
op.allow_same_first_letter_within_pair = 0; 
op.word_list_master_filename = [dirs.stim, filesep, 'irani23_word_list_master.tsv']; 


% op.ortho_font_size = 70; 
op.ortho_font_size = 140; % use font size 140 in mock scanner
op.background_color = [0 0 0]; % text will be inverse of this color

op.ntrials_between_breaks = 50; %%%% 

op.num_run_digits = 2; % number of digits to include in run number labels in filenames

pause('on') % enable to use of pause.m to hold code execution until keypress

%% generate trial stim list
[trials] = setup_subj_ieeg_stut_irani23(op);

%% audio device setup
[~,computername] = system('hostname'); % might not work on non-windows machines
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
        case 'MSI' % AM personal laptop
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
            error('unknown computer; please add preferred devices to "audio device section" of flvoice_run.m')
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


%% FLvoice setup .... 


% 
% % create structure to save experimental parameters
% if preFlag
%     op = expRead;
% else % if no preset config file defined
%     op=struct(...
%         'visual', 'orthography', ...
%         'root', pwd, ...
%         'audiopath', fullfile(pwd, 'stimuli', 'audio', 'exp'), ...
%         'figurespath', fullfile(pwd, 'stimuli', 'figures', 'Adults'), ...
%         'subject','TEST01',...
%         'session', 1, ...
%         'run', 1,...
%         'task', 'test', ...
%         'gender', 'unspecified', ...
%         'timePostStim', [.25 .75],...
%         'timePostOnset', 4.5,...
%         'timePreStim', .25,...
%         'timeMax', 5.5, ...
%         'timePreSound', .5, ...
%         'timePostSound', .47, ...
%         'rmsThresh', .02,... %'rmsThresh', .05,...
%         'rmsBeepThresh', .1,...
%         'rmsThreshTimeOnset', .02,...% 'rmsThreshTimeOnset', .10,...
%         'rmsThreshTimeOffset', [.25 .25],...
%         'minVoiceOnsetTime', 0.4, ...
%         'deviceMic','',...
%         'deviceHead',''...
%         )
% end
% 
% op.computer = host;
% 
% for n=1:2:numel(varargin)-1, 
%     assert(isfield(op,varargin{n}),'unrecognized option %s',varargin{n});
%     op.(varargin{n})=varargin{n+1};
% end
% 
% try, a=audioDeviceReader('Device','asdf'); catch me; str=regexp(regexprep(me.message,'.*Valid values are:',''),'"([^"]*)"','tokens'); strINPUT=[str{:}]; end;
% audiodevreset;
% info=audiodevinfo;
% strOUTPUT={info.output.Name};
% try, a=audioDeviceWriter('Device','asdf'); catch me; str=regexp(regexprep(me.message,'.*Valid values are:',''),'"([^"]*)"','tokens'); strOUTPUT=[str{:}]; end;
% 
% % Look for default input and output indices
% if contains(default_audio_in,'Focusrite')
%     ipind = find(contains(strINPUT, 'Analogue')&contains(strINPUT, default_audio_in));
%     opind = find(contains(strOUTPUT, 'Speakers')&contains(strOUTPUT, default_audio_out));
%     tgind = find(contains(strOUTPUT, 'Playback')&contains(strOUTPUT, default_audio_out));
% else
%     ipind = find(contains(strINPUT, default_audio_in));
%     opind = find(contains(strOUTPUT, default_audio_out));
%     tgind = find(contains(strOUTPUT, default_audio_out));
% end
% % 
% strVisual={'figure', 'fixpoint', 'orthography'};
% 
% % GUI for user to modify options
% fnames=fieldnames(op);
% fnames=fnames(~ismember(fnames,{'visual', 'root', 'audiopath', 'figurespath', 'subject', 'session', 'run', 'task', 'gender', 'deviceMic','deviceHead','deviceScan'}));
% for n=1:numel(fnames)
%     val=op.(fnames{n});
%     if ischar(val), fvals{n}=val;
%     elseif isempty(val), fvals{n}='';
%     else fvals{n}=mat2str(val);
%     end
% end
% 
% out_dropbox = {'visual', 'root', 'audiopath', 'figurespath', 'subject', 'session', 'run', 'task', 'gender'};
% for n=1:numel(out_dropbox)
%     val=op.(out_dropbox{n});
%     if ischar(val), fvals_o{n}=val;
%     elseif isempty(val), fvals_o{n}='';
%     else fvals_o{n}=mat2str(val);
%     end
% end
% 
% default_width = 0.04; %0.08;
% default_intvl = 0.05; %0.10;
% 
% thfig=dialog('units','norm','position',[.3,.3,.3,.5],'windowstyle','normal','name','FLvoice_run options','color','w','resize','on');
% uicontrol(thfig,'style','text','units','norm','position',[.1,.92,.8,default_width],'string','Experiment information:','backgroundcolor','w','fontsize',default_fontsize,'fontweight','bold');
% 
% ht_txtlist = {};
% ht_list = {};
% for ind=1:size(out_dropbox,2)
%     ht_txtlist{ind} = uicontrol(thfig,'style','text','units','norm','position',[.1,.75-(ind-3)*default_intvl,.35,default_width],'string',[out_dropbox{ind}, ':'],'backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
%     if strcmp(out_dropbox{ind}, 'visual')
%         ht_list{ind} = uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-(ind-3)*default_intvl,.4,default_width],'string', strVisual, 'value',find(strcmp(strVisual, op.visual)),'fontsize',default_fontsize-1,'callback',@thfig_callback4);
%     else
%         ht_list{ind} = uicontrol(thfig,'style','edit','units','norm','position',[.5,.75-(ind-3)*default_intvl,.4,default_width],'string', fvals_o{ind}, 'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1,'callback',@thfig_callback3);
%     end
% end
% 
% ht1=uicontrol(thfig,'style','popupmenu','units','norm','position',[.1,.75-8*default_intvl,.4,default_width],'string',fnames,'value',1,'fontsize',default_fontsize-1,'callback',@thfig_callback1);
% ht2=uicontrol(thfig,'style','edit','units','norm','position',[.5,.75-8*default_intvl,.4,default_width],'string','','backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1,'callback',@thfig_callback2);
% 
% uicontrol(thfig,'style','text','units','norm','position',[.1,.75-9*default_intvl,.35,default_width],'string','Microphone:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
% ht3a=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-9*default_intvl,.4,default_width],'string',strINPUT,'value',ipind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);
% 
% uicontrol(thfig,'style','text','units','norm','position',[.1,.75-10*default_intvl,.35,default_width],'string','Sound output:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
% ht3b=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-10*default_intvl,.4,default_width],'string',strOUTPUT,'value',opind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);
% 
% ht3c0=uicontrol(thfig,'style','text','units','norm','position',[.1,.75-11*default_intvl,.35,default_width],'string','Scanner trigger:','backgroundcolor','w','fontsize',default_fontsize-1,'fontweight','bold','horizontalalignment','right');
% ht3c=uicontrol(thfig,'style','popupmenu','units','norm','position',[.5,.75-11*default_intvl,.4,default_width],'string',strOUTPUT,'value',tgind,'backgroundcolor',1*[1 1 1],'fontsize',default_fontsize-1);
% 
% uicontrol(thfig,'style','pushbutton','string','Start','units','norm','position',[.1,.01,.38,.10],'callback','uiresume','fontsize',default_fontsize-1);
% uicontrol(thfig,'style','pushbutton','string','Cancel','units','norm','position',[.51,.01,.38,.10],'callback','delete(gcbf)','fontsize',default_fontsize-1);
% 
% ind2 = find(strcmp(out_dropbox, 'figurespath'));
% if ~strcmp(op.visual, 'figure'), set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'off'); end
% 
% 
% thfig_callback1;
%     function thfig_callback1(varargin)
%         tn=get(ht1,'value');
%         set(ht2,'string',fvals{tn});
%     end
%     function thfig_callback2(varargin)
%         tn=get(ht1,'value');
%         fvals{tn}=get(ht2,'string');
%     end
%     function thfig_callback3(varargin)
%         for tn=1:size(out_dropbox,2)
%             if strcmp(out_dropbox{tn}, 'visual'), continue; end
%             fvals_o{tn}=get(ht_list{tn}, 'string');
%             if strcmp(out_dropbox{tn},'scan')
%                 if isequal(str2num(fvals_o{tn}),0), set([ht3c0,ht3c],'visible','off'); 
%                 else set([ht3c0,ht3c],'visible','on'); 
%                 end
%             end
%         end
%     end
%     function thfig_callback4(varargin)
%         ind = find(strcmp(out_dropbox, 'visual'));
%         choice=get(ht_list{ind}, 'value');
%         fvals_o{ind}=strVisual{choice};
%         ind2 = find(strcmp(out_dropbox, 'figurespath'));
%         if ~strcmp(strVisual{choice}, 'figure')
%             set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'off'); 
%         else 
%             set([ht_txtlist{ind2}, ht_list{ind2}], 'visible', 'on');
%         end
%     end
% 
% uiwait(thfig);
% ok=ishandle(thfig);
% if ~ok, return; end
% op.deviceMic=strINPUT{get(ht3a,'value')};
% op.deviceHead=strOUTPUT{get(ht3b,'value')};
% op.deviceScan=strOUTPUT{get(ht3c,'value')};
% delete(thfig);
% for n=1:numel(fnames)
%     val=fvals{n};
%     if ischar(op.(fnames{n})), op.(fnames{n})=val;
%     elseif isempty(val), op.(fnames{n})=[];
%     else
%         assert(~isempty(str2num(val)),'unable to interpret string %s',val);
%         op.(fnames{n})=str2num(val);
%     end
% end
% for n=1:numel(out_dropbox)
%     val=fvals_o{n};
%     if ischar(op.(out_dropbox{n})), op.(out_dropbox{n})=val;
%     elseif isempty(val), op.(out_dropbox{n})=[];
%     else
%         assert(~isempty(str2num(val)),'unable to interpret string %s',val);
%         op.(out_dropbox{n})=str2num(val);
%     end
% end
% 
% visual setup
annoStr = setUpVisAnnot_HW(op); 
annoStr.Stim.FontSize = op.ortho_font_size; 
% 
% CLOCKp = ManageTime('start');
% TIME_PREPARE = 0.5; % Waiting period before experiment begin (sec)
% set(annoStr.Stim, 'String', 'Preparing...');
% set(annoStr.Stim, 'Visible','on');
% 
% 
% 
% % locate files
dirs.ses = fullfile(dirs.data, sprintf('sub-%s',op.sub), sprintf('ses-%d',op.ses),'beh', op.task);
% Input_audname  = fullfile(dirs.ses,sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-stimulus.txt',op.subject, op.session, op.run, op.task));
% Input_condname  = fullfile(dirs.ses,sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-conditions.txt',op.subject, op.session, op.run, op.task));
% Output_name = fullfile(dirs.ses,sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-audio.mat',op.subject, op.session, op.run, op.task));
% assert(~isempty(dir(Input_audname)), 'unable to find input file %s',Input_audname);
% if ~isempty(dir(Output_name))&&~isequal('Yes - overwrite', questdlg(sprintf('This subject %s already has an data file for this ses-%d_run-%d (task: %s), do you want to over-write?', op.subject, op.session, op.run, op.task),'Answer', 'Yes - overwrite', 'No - quit','No - quit')), return; end
% % read audio files and condition labels
% Input_files=regexp(fileread(Input_audname),'[\n\r]+','split');
% 
% Input_files_temp=Input_files(cellfun('length',Input_files)>0);
% NoNull = find(~strcmp(Input_files_temp, 'NULL'));
% 
% 

% 

%%% check whether session dir already exists; make it if it doesn't already exist
if ~isdir(dirs.ses)
    mkdir(dirs.ses)
end

% make new run folder
dd = struct2table(dir(dirs.ses)); dd = dd.name; % session dir contents
rundirnames = dd(cell2mat(cellfun(@(x)~isempty(regexp(x,'run-[0-9][0-9]')),dd,'UniformOutput',false))); % assume less than 100 runs per session
rundirnums = cell2mat(cellfun(@(x)str2num(strrep(x,'run-','')),rundirnames,'UniformOutput',false)); 
if nnz(rundirnums) == 0 % if there's not already a rundir here
    op.run = 1; % first run this session
elseif nnz(rundirnums) > 0 % if there's already a rundir here
    op.run = max(rundirnums) + 1; % this run = latest run plus 1
end
runstring = sprintf(['%0',num2str(op.num_run_digits),'d'], op.run); % add zero padding
dirs.run = [dirs.ses, filesep, 'run-', runstring]; 
mkdir(dirs.run) ; clear dd rundirnames rundirnums

% save stim list
fname_trialtable = [dirs.ses, filesep, 'sub-',op.sub, '_ses-',num2str(op.ses), '_task-',op.task, '_run-',runstring, '_trials']; 
save(fname_trialtable,'trials','op','dirs')


% if ispc
%     Input_files=arrayfun(@(x)fullfile(op.audiopath, op.task, strcat(strrep(x, '/', '\'), '.wav')), Input_files_temp);
% else
%     Input_files=arrayfun(@(x)fullfile(op.audiopath, op.task, strcat(x, '.wav')), Input_files_temp);
% end


% % % % % % % % % % % % % % % if strcmp(op.visual, 'figure')
% % % % % % % % % % % % % % %     All_figures_str = dir(fullfile(op.figurespath, '*.png'));
% % % % % % % % % % % % % % %     All_figures = arrayfun(@(x)fullfile(All_figures_str(x).folder, All_figures_str(x).name), 1:length(All_figures_str), 'uni', 0);
% % % % % % % % % % % % % % %     figures=arrayfun(@(x)fullfile(op.figurespath, strcat(x, '.png')), Input_files_temp);
% % % % % % % % % % % % % % %     figureseq=arrayfun(@(x)find(strcmp(All_figures, x)), figures, 'uni', 0);
% % % % % % % % % % % % % % %     if sum(arrayfun(@(x)isempty(figureseq{x}), 1:length(figureseq))) ~= 0
% % % % % % % % % % % % % % %         disp('Some images not found or image names don''t match');
% % % % % % % % % % % % % % %         return
% % % % % % % % % % % % % % %     end
% % % % % % % % % % % % % % % end

% % % % % % % % % % % % % % % % % % ok=cellfun(@(x)exist(x,'file'), Input_files(NoNull));
% % % % % % % % % % % % % % % % % % assert(all(ok), 'unable to find files %s', sprintf('%s ',Input_files{NoNull(~ok)}));
% % % % % % % % % % % % % % % % % % dirFiles=cellfun(@dir, Input_files(NoNull), 'uni', 0);
% % % % % % % % % % % % % % % % % % NoNull=NoNull(cellfun(@(x)x.bytes>0, dirFiles));
% % % % % % % % % % % % % % % % % % Input_sound=cell(size(Input_files));
% % % % % % % % % % % % % % % % % % Input_fs=num2cell(ones(size(Input_files)));
% % % % % % % % % % % % % % % % % % [Input_sound(NoNull),Input_fs(NoNull)]=cellfun(@audioread, Input_files(NoNull),'uni',0);
% % % % % % % % % % % % % % % % % % [silent_sound,silent_fs]=audioread(fullfile(op.audiopath, 'silent.wav'));
% % % % % % % % % % % % % % % % % % stimreads=cell(size(Input_files));
% % % % % % % % % % % % % % % % % % stimreads(NoNull)=cellfun(@(x)dsp.AudioFileReader(x, 'SamplesPerFrame', 2048),Input_files(NoNull),'uni',0);
% % % % % % % % % % % % % % % % % % stimreads(setdiff(1:numel(stimreads), NoNull))=arrayfun(@(x)dsp.AudioFileReader(fullfile(op.audiopath, 'silent.wav'), 'SamplesPerFrame', 2048),1:numel(Input_files(setdiff(1:numel(stimreads), NoNull))),'uni',0);
% % % % % % % % % % % % % % % % % % sileread = dsp.AudioFileReader(fullfile(op.audiopath, 'silent.wav'), 'SamplesPerFrame', 2048);

% % % % % % % % % % % % % % % if isempty(dir(Input_condname))
% % % % % % % % % % % % % % %     [nill,Input_conditions]=arrayfun(@fileparts,Input_files,'uni',0);
% % % % % % % % % % % % % % % else
% % % % % % % % % % % % % % %     Input_conditions=regexp(fileread(Input_condname),'[\n\r]+','split');
% % % % % % % % % % % % % % %     Input_conditions=Input_conditions(cellfun('length',Input_conditions)>0);
% % % % % % % % % % % % % % %     assert(numel(Input_files)==numel(Input_conditions),'unequal number of lines/trials in %s (%d) and %s (%d)',Input_audname, numel(Input_files), Input_condname, numel(Input_conditions));
% % % % % % % % % % % % % % % end
% % % % % % % % % % % % % % % op.numTrials = length(Input_conditions); % pull out the number of trials from the stimList
% 
% Input_duration=cellfun(@(a,b)numel(a)/b, Input_sound, Input_fs);
% %meanInput_duration=mean(Input_duration(Input_duration>0));
% silence_dur=size(silent_sound,1)/silent_fs;
% [Input_sound{Input_duration==0}]=deal(zeros(ceil(44100*silence_dur),1)); % fills empty audiofiles with average-duration silence ('NULL' CONDITIONS)
% [Input_fs{Input_duration==0}]=deal(44100);
% [Input_conditions{Input_duration==0}]=deal('NULL');
% 
% % create random number stream so randperm doesn't call the same thing everytime when matlab is opened
% s = RandStream.create('mt19937ar','seed',sum(100*clock));
% RandStream.setGlobalStream(s);
% 
% % set audio device variables: deviceReader: mic input; beepPlayer: beep output; triggerPlayer: trigger output
% if isempty(op.deviceMic)
%     disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,strINPUT{n}),1:numel(strINPUT),'uni',0))); ID=input('MICROPHONE input device # : ');
%     op.deviceMic=strINPUT{ID};
% end
% if ~ismember(op.deviceMic, strINPUT), op.deviceMic=strINPUT{find(strncmp(lower(op.deviceMic),lower(strINPUT),numel(op.deviceMic)),1)}; end
% assert(ismember(op.deviceMic, strINPUT), 'unable to find match to deviceMic name %s',op.deviceMic);
% if isempty(op.deviceHead)||(op.scan&&isempty(op.deviceScan))
%     %disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,info.output(n).Name),1:numel(info.output),'uni',0)));
%     disp(char(arrayfun(@(n)sprintf('Device #%d: %s ',n,strOUTPUT{n}),1:numel(strOUTPUT),'uni',0)));
%     if isempty(op.deviceHead),
%         ID=input('HEADPHONES output device # : ');
%         op.deviceMic=strOUTPUT{ID};
%     end
% end
% % set up device reader settings for accessing audio signal during recording
% op.sr = 48000;            % sample frequenct (Hz)
% frameDur = .050;                 % frame duration in seconds
% op.frameLength = op.sr*frameDur;      % framelength in samples
% deviceReader = audioDeviceReader(...
%     'Device', op.deviceMic, ...
%     'SamplesPerFrame', op.frameLength, ...
%     'SampleRate', op.sr, ...
%     'BitDepth', '24-bit integer');    
% % set up sound output players
% if ~ismember(op.deviceHead, strOUTPUT), op.deviceHead=strOUTPUT{find(strncmp(lower(op.deviceHead),lower(strOUTPUT),numel(op.deviceHead)),1)}; end
% assert(ismember(op.deviceHead, strOUTPUT), 'unable to find match to deviceHead name %s',op.deviceHead);
% [ok,ID]=ismember(op.deviceHead, strOUTPUT);
% [twav, tfs] = audioread(fullfile(fileparts(which(mfilename)),'flvoice_run_beep.wav'));
% beepdur = numel(twav)/tfs;
% %stimID=info.output(ID).ID;
% %beepPlayer = audioplayer(twav*0.2, tfs, 24, info.output(ID).ID);
% beepread = dsp.AudioFileReader(fullfile(fileparts(which(mfilename)),'flvoice_run_beep.wav'), 'SamplesPerFrame', 2048);
% %headwrite = audioDeviceWriter('SampleRate',beepread.SampleRate,'Device',op.deviceHead, 'SupportVariableSizeInput', true, 'BufferSize', 2048);
% headwrite = audioDeviceWriter('SampleRate',beepread.SampleRate,'Device',op.deviceHead);
% 
% % checks values of timing variables
% op.beepoffset = beepoffset;
% 
% if numel(op.timePostStim)==1, op.timePostStim=op.timePostStim+[0 0]; end
% if numel(op.timePostOnset)==1, op.timePostOnset=op.timePostOnset+[0 0]; end
% if numel(op.timePreStim)==1, op.timePreStim=op.timePreStim+[0 0]; end
% if numel(op.timeMax)==1, op.timeMax=op.timeMax+[0 0]; end
% op.timePostStim=sort(op.timePostStim);
% op.timePostOnset=sort(op.timePostOnset);
% op.timePreStim=sort(op.timePreStim);
% op.timeMax=sort(op.timeMax);
% rmsThresh = op.rmsThresh; % params for detecting voice onset %voiceCal.rmsThresh; % alternatively, run a few iterations of testThreshold and define rmsThreshd here with the resulting threshold value after convergence
% rmsBeepThresh = op.rmsBeepThresh;
% % nonSpeechDelay = .75; % initial estimate of time between go signal and voicing start
% nonSpeechDelay = .5; % initial estimate of time between go signal and voicing start
% 
% %%%%% set up figure for real-time plotting of audio signal of next trial
% if op.show_mic_trace_figure
%     rtfig = figure('units','norm','position',[.1 .2 .4 .5],'menubar','none', 'Visible',op.show_mic_trace_figure);
%     micSignal = plot(nan,nan,'-', 'Color', [0 0 0.5]);
%     micLine = xline(0, 'Color', [0.984 0.352 0.313], 'LineWidth', 3);
%     micLineB = xline(0, 'Color', [0.46 1 0.48], 'LineWidth', 3);
%     micTitle = title('', 'Fontsize', default_fontsize-1, 'interpreter','none');
%     xlabel('Time(s)');
%     ylabel('Sound Pressure');
% end
% 
% % set up picture display
% 
% if strcmp(op.visual, 'figure'), imgBuf = arrayfun(@(x)imread(All_figures{x}), 1:length(All_figures),'uni',0); end
% 
% pause(1);
% save(Output_name, 'op');
% 
% %Initialize trialData structure
% trialData = struct;
% 
% ok=ManageTime('wait', CLOCKp, TIME_PREPARE);
% set(annoStr.Stim, 'Visible','off');     % Turn off preparation page
% TIME_PREPARE_END=ManageTime('current', CLOCKp);
% 
% set(annoStr.Stim, 'String', 'READY');
% set(annoStr.Stim, 'Visible','on');
% while ~isDone(sileread); sound=sileread();headwrite(sound);end;release(sileread);reset(headwrite);
% ok=ManageTime('wait', CLOCKp, TIME_PREPARE_END+2);
% set(annoStr.Stim, 'Visible','off');     % Turn off preparation page
CLOCK=[];                               % Main clock (not yet started)
% op.timeNULL = op.timeMax(1) + diff(op.timeMax).*rand;
% intvs = [];

% starting message for each block
switch op.stim_prdm
    case 'cue_word'
        instruct_msg = {'On each trial, first look at the cross in the center of the screen.','',...
            'Two made-up words will show on screen.','',...
            'Say these two words as soon as they appear.'}; 
            % 'Say these two words as quickly and accurately as possible.'};

    case 'word_go'
        instruct_msg = {'On each trial, you will see two made-up words appear.','',...
                    'Wait until you see the ''!!!'' appear, then say these two words.'}; 
            % 'Wait until you see the ''!!!'' appear, then say these two words as quickly and accurately as possible'};


end

% set(annoStr.Instruction,'String',[instruct_msg, '\n\n When you''re ready, press any key to start']); %  use this option if subject has keyboard available; otherwise, experimenter does keypress
set(annoStr.Instruction,'String',[instruct_msg])
set(annoStr.Instruction,'FontSize', op.ortho_font_size / 2); 

set(annoStr.Instruction,'Visible','on'); 
pause()  % wait for keypress to start the run
set(annoStr.Instruction,'Visible','off'); 
pause(1)

%% LOOP OVER TRIALS



for itrial = 1:op.ntrials

    % set(annoStr.Plus, 'Visible','on');
    
    % print trial num and stim
    fprintf([   '\n      .... Trial ', num2str(itrial), '/' num2str(op.ntrials), ', Run ', num2str(op.run), '.....', trials.fullstim{itrial}]);

    if (mod(itrial,op.ntrials_between_breaks) == 0) && (itrial ~= op.ntrials)  % Break after every X trials  , but not on the last
        pause()
        fprintf(['\n    Break time; press any key to continue \n'])
    end





%     if strcmp(trialData(itrial).display, 'NULL'); trialData(itrial).display = 'yyy'; end
% %     trialData(ii).timeStim = numel(Input_sound{ii})/Input_fs{ii}; 
%     trialData(itrial).timeStim = size(Input_sound{itrial},1)/Input_fs{itrial}; 
%     trialData(itrial).timePostStim = op.timePostStim(1) + diff(op.timePostStim).*rand; 
%     trialData(itrial).timePostOnset = op.timePostOnset(1) + diff(op.timePostOnset).*rand; 
%     trialData(itrial).timePreStim = op.timePreStim(1) + diff(op.timePreStim).*rand; 
%     trialData(itrial).timeMax = op.timeMax(1) + diff(op.timeMax).*rand; 
%     trialData(itrial).timePostSound = op.timePostSound;
%     trialData(itrial).timePreSound = op.timePreSound;
%     %stimPlayer = audioplayer(Input_sound{ii},Input_fs{ii}, 24, stimID);
%     stimread = stimreads{itrial};
%     SpeechTrial=~strcmp(trialData(itrial).condLabel,'NULL');
% %     SpeechTrial=~strcmp(trialData(ii).condLabel,'S');
% 
%     % set up variables for audio recording and voice detection
%     recordLen= trialData(itrial).timeMax; % max total recording time
%     recordLenNULL = op.timeNULL;
%     nSamples = ceil(recordLen*op.sr);
%     nSamplesNULL = ceil(recordLenNULL*op.sr);
%     time = 0:1/op.sr:(nSamples-1)/op.sr;
%     recAudio = zeros(nSamples,1);       % initialize variable to store audio
%     nMissingSamples = 0;                % cumulative n missing samples between frames
%     beepDetected = 0;
%     voiceOnsetDetected = 0;             % voice onset not yet detected
%     frameCount = 1;                     % counter for # of frames (starting at first frame)
%     endIdx = 0;                         % initialize idx for end of frame
%     voiceOnsetState = [];
%     beepOnsetState = [];
% 
    % % set up figure for real-time plotting of audio signal of next trial
    % if op.show_mic_trace_figure
    %     figure(rtfig)
    %     set(micTitle,'string',sprintf('%s %s run %d trial %d condition: %s', op.subject, op.task, op.run, itrial, trialData(itrial).condLabel));
    % end
    % 
    % 
    % %t = timer;
    % %t.StartDelay = 0.050;   % Delay between timer start and timer function
    % %t.TimerFcn = @(myTimerObj, thisEvent)play(beepPlayer); % Timer function plays GO signal
    % setup(deviceReader) % note: moved this here to avoid delays in time-sensitive portion

    if isempty(CLOCK)
        CLOCK = ManageTime('start');                        % resets clock to t=0 (first-trial start-time)
        TIME_TRIAL_START = 0;
        TIME_STIM_START = 0;
    else
        TIME_TRIAL_START = ManageTime('current', CLOCK);
    end


    set(annoStr.Stim,'String',trials.fullstim{itrial}); % prepare this trial's word stim
    
    
    % show the get-ready stim
    switch op.stim_prdm
        case 'word_go'
            set(annoStr.Stim,'Visible','on'); 
        case 'cue_word'
            set(annoStr.Plus,'Visible','on'); 
    end
    trials.t_rdy_on(itrial) =  ManageTime('current', CLOCK);
    pause(op.get_ready_stim_dur)
    
    % remove the get-ready stim
    switch op.stim_prdm
        case 'word_go'
            set(annoStr.Stim,'Visible','off'); 
        case 'cue_word'
            set(annoStr.Plus,'Visible','off'); 
    end
    trials.t_rdy_off(itrial) =  ManageTime('current', CLOCK);
    
    % pause before GO cue
    pause(op.prespeech_delay_dur); 
    
    % present the GO cue
    switch op.stim_prdm
        case 'word_go'
            set(annoStr.Exclam,'Visible','on'); 
        case 'cue_word'
            set(annoStr.Stim,'Visible','on'); 
    end
    TIME_GOSIGNAL_ACTUALLYSTART = ManageTime('current', CLOCK); % actual time for GO signal 
    trials.t_go_on(itrial) = TIME_GOSIGNAL_ACTUALLYSTART; 
    
    pause(op.go_stim_dur)
    
    % remove GO cue
    switch op.stim_prdm
        case 'word_go'
            set(annoStr.Exclam,'Visible','off'); 
        case 'cue_word'
            set(annoStr.Stim,'Visible','off'); 
    end
    trials.t_go_off(itrial) =  ManageTime('current', CLOCK);


    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if strcmp(op.visual, 'fixpoint'),set(annoStr.Plus, 'color','g');drawnow;end
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if strcmp(op.visual, 'orthography'),set(annoStr.Plus, 'color','g');drawnow;end
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % if ~ok, fprintf('i am late for this trial TIME_GOSIGNAL_START\n'); end
 
    % TIME_VOICE_START = TIME_GOSIGNAL_ACTUALLYSTART + nonSpeechDelay;                   % expected voice onset time
    % 
    % 
    % endSamples = SpeechTrial * nSamples + (1-SpeechTrial)*nSamplesNULL;
    % while endIdx < endSamples
    %     % find beginning/end indices of frame
    %     begIdx = (frameCount*op.frameLength)-(op.frameLength-1) + nMissingSamples;
    %     endIdx = (frameCount*op.frameLength) + nMissingSamples;
    % 
    %     % read audio data
    %     [audioFromDevice, numOverrun] = deviceReader();     % read one frame of audio data % note: audio t=0 corresponds to first call to deviceReader, NOT to time of setup(...)
    %     numOverrun = double(numOverrun);    % convert from uint32 to type double
    %     if numOverrun > 0, recAudio(begIdx:begIdx+numOverrun-1) = 0; end      % set missing samples to 0
    %     recAudio(begIdx+numOverrun:endIdx+numOverrun) = audioFromDevice;    % save frame to audio vector
    %     nMissingSamples = nMissingSamples + numOverrun;     % keep count of cumulative missng samples between frames
    % 
    %     % plot audio data
    %     if op.show_mic_trace_figure
    %         set(micSignal, 'xdata',time, 'ydata',recAudio(1:numel(time)))
    %     end
    %     drawnow()
    % 
    %     % voice onset exclusion
    %     minVoiceOnsetTime = max(0, op.minVoiceOnsetTime-(begIdx+numOverrun)/op.sr);
    % 
    %     % detect beep onset
    %     if SpeechTrial && beepDetected == 0 && op.minVoiceOnsetTime > (begIdx+numOverrun)/op.sr
    %         % look for beep onset
    %         [beepDetected, bTime, beepOnsetState]  = detectVoiceOnset(recAudio(begIdx+numOverrun:endIdx+numOverrun), op.sr, op.rmsThreshTimeOnset, rmsBeepThresh, 0, beepOnsetState);
    %         if beepDetected
    %             beepTime = bTime + (begIdx+numOverrun)/op.sr; 
    %              if op.show_mic_trace_figure
    %                 set(micLineB,'value',beepTime,'visible','on');
    %              end
    %         end
    %     elseif SpeechTrial && voiceOnsetDetected == 0,% && frameCount > onsetWindow/frameDur
    %         if ~beepDetected; beepTime = 0; 
    %             % disp('Beep not detected. Assign beepTime = 0.'); 
    %         end
    %         trialData(itrial).beepTime = beepTime;
    % 
    %         % look for voice onset in previous onsetWindow
    %         [voiceOnsetDetected, voiceOnsetTime, voiceOnsetState]  = detectVoiceOnset(recAudio(begIdx+numOverrun:endIdx+numOverrun), op.sr, op.rmsThreshTimeOnset, rmsThresh, minVoiceOnsetTime, voiceOnsetState);
    %         % update voice onset time based on index of data passed to voice onset function
    % 
    %         if voiceOnsetDetected
    %             voiceOnsetTime = voiceOnsetTime + (begIdx+numOverrun)/op.sr - beepTime;
    %             TIME_VOICE_START = TIME_GOSIGNAL_ACTUALLYSTART + voiceOnsetTime; % note: voiceonsetTime marks the beginning of the minThreshTime window
    %             nonSpeechDelay = .5*nonSpeechDelay + .5*voiceOnsetTime;  % running-average of voiceOnsetTime values, with alpha-parameter = 0.5 (nonSpeechDelay = alpha*nonSpeechDelay + (1-alph)*voiceOnsetTime; alpha between 0 and 1; alpha high -> slow update; alpha low -> fast update)
    %             TIME_SCAN_START =  TIME_VOICE_START + trialData(itrial).timePostOnset;
    %             nSamples = min(nSamples, ceil((TIME_SCAN_START-TIME_GOSIGNAL_ACTUALLYSTART)*op.sr));
    %             endSamples = nSamples;
    %             % add voice onset to plot
    %             if op.show_mic_trace_figure
    %                 set(micLine,'value',voiceOnsetTime + beepTime,'visible','on');
    % 
    % 
    %             end
    %             drawnow update
    %         end
    % 
    %     end
    % 
    %     frameCount = frameCount+1;
    % 
    % end
    % if SpeechTrial && voiceOnsetDetected == 0 
    %     % fprintf('warning: voice was expected but not detected (rmsThresh = %f)\n',rmsThresh); 
    % end
    % release(deviceReader); % end recording
    % 
    % switch op.visual
    %     % % % % % % % % % % % case 'fixpoint'
    %     % % % % % % % % % % %     set(annoStr.Plus, 'color','w');
    %     case 'figure'
    %         imshow([], 'Parent', annoStr.Pic);
    %     % % % % % % % % case 'orthography'
    %     % % % % % % % %     set(annoStr.Plus, 'color','w');
    % end
    % 
    % 
    % 
    % 
    % 
    % %stop(t);
    % %delete(t);
    % 
    % %% save voice onset time and determine how much time left before sending trigger to scanner
    % if voiceOnsetDetected == 0 %if voice onset wasn't detected
    %     trialData(itrial).onsetDetected = 0;
    %     trialData(itrial).voiceOnsetTime = NaN;
    %     trialData(itrial).nonSpeechDelay = nonSpeechDelay;
    % else
    %     trialData(itrial).onsetDetected = 1;
    %     trialData(itrial).voiceOnsetTime = voiceOnsetTime;
    %     trialData(itrial).nonSpeechDelay = NaN;
    % end
    % 
    % 
    %     TIME_SCAN_ACTUALLYSTART=nan;
    %     %TIME_TRIG_RELEASED = nan;
    %     TIME_SCAN_END = nan;
    %     % NEXTTRIAL = TIME_SCAN_START + trialData(itrial).timePreStim;
    % 
    % 
    % trialData(itrial).timingTrial = [TIME_GOSIGNAL_ACTUALLYSTART;TIME_VOICE_START];
    % op.timingTrialNames = split('TIME_GOSIGNAL_ACTUALLYSTART;TIME_VOICE_START', ';');


    % DON'T adapt rmsThresh
%     if 1, %isfield(op,'voiceCal')&&op.voiceCal.threshType == 1
%         if SpeechTrial   % If the current trial is not a baseline trial
%             rmsFF=.90; winDur=.002; winSize=ceil(winDur*op.sr); % note: match rmsFF and rmsFrameDur values to those in detectVoiceOnset.m
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

    % %% save for each trial
    % trialData(itrial).s = recAudio(1:nSamples);
    % trialData(itrial).fs = op.sr;
    % if SpeechTrial&&voiceOnsetDetected, trialData(itrial).reference_time = voiceOnsetTime;
    % else trialData(itrial).reference_time = nonSpeechDelay;
    % end
    % trialData(itrial).percMissingSamples = (nMissingSamples/(recordLen*op.sr))*100;
    % 
    % %JT save update test 8/10/21
    % % save only data from current trial
    % tData = trialData(itrial);

    % fName_trial will be used for individual trial files (which will live in the run folder)
    fName_trial = fullfile(dirs.run,sprintf('sub-%s_ses-%d_task-%s_run-%s_trial-%d.mat',op.sub, op.ses, op.task, runstring, itrial));
    % save(fName_trial,'tData');
    trialdat = trials(itrial,:); 
    save(fName_trial,'trialdat','op'); % save timing data for this individual... do we really need these individual files? 
    save(fname_trialtable,'trials','op','op','dirs') % save the updated whole trial timing table
end

% release(headwrite);
% release(beepread);


%% end of experiment
close all

% experiment time
op.elapsed_time = toc(ET)/60;    % elapsed time of the experiment
fprintf('\nElapsed Time: %f (min)\n', op.elapsed_time)


% % number of trials with voice onset detected
% onsetCount = nan(op.numTrials,1);
% for j = 1: op.numTrials
%     onsetCount(j) = trialData(j).onsetDetected;
% end
% numOnsetDetected = sum(onsetCount);    
% 
% fprintf('Voice onset detected on %d/%d trials\n', numOnsetDetected, op.numTrials);
% 
% fprinft('Press any key to send final sync pulses and end this experimental phase')
% pause()
% 










        



