function annoStr = setUpVisAnnot()
% Setting up visualization
% Helper script that sets up a couple of annotation objects that can be used for
% stimulus visualization / presentation.
%

%% get monitorSize and set up related var
monitorSize = get(0, 'Monitor');
numMon = size(monitorSize, 1);

if numMon == 2 % if two monitors, figure covers entire monitor
    figPosition = [monitorSize(2,1) monitorSize(2,2) monitorSize(2,3) monitorSize(2,4)]; 
else % if one monitor, figure only takes up half of monitor ?
    W = monitorSize(1, 3);
    H = monitorSize(1, 4);
    W2 = W/2;
    H2 = H/2;
    XPos = W2;
    YPos = 50;
    figPosition = [XPos YPos W2 H2];
end
winPos = figPosition;

%% Preparing 'Ready' Annotation Position
rdAnoD = [700 300];
rdAnoPos = getPos(rdAnoD, winPos);

% Preparing 'Cue' Annotation Position
cuAnoD = [250 150];
cuAnoPos = getPos(cuAnoD, winPos);

% Preparing 'Stim' Annotation Position
stimAnoD = [700 300]; % if stim too small/large, need to adjust
stimAnoPos = getPos(stimAnoD, winPos);

%% Actually create the stim presentation figure
% this causes the stim window to appear
VBFig = figure('NumberTitle', 'off', 'Color', [0 0 0], 'Position', winPos, 'MenuBar', 'none');
drawnow; if ~isequal(get(VBFig,'position'),winPos), set(VBFig,'Position',winPos); end % fix needed only on some dual monitor setups

% Common annotation settings
cSettings = {'Color',[1 1 1],...
    'LineStyle','none',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'FontSize',130,...
    'FontWeight','bold',...
    'FontName','Arial',...
    'FitBoxToText','off',...
    'EdgeColor','none',...
    'BackgroundColor',[0 0 0],...
    'visible','off'};

cSettingsGreen = cSettings; cSettingsGreen{2} = [0, .5, .25];
cSettingsRed = cSettings; cSettingsRed{2} = [.5 0 0];

% Ready annotation
annoStr.Ready = annotation(VBFig,'textbox', rdAnoPos,...
    'String',{'READY'},...
    cSettings{:});

% Cue annotation
annoStr.Plus = annotation(VBFig,'textbox', cuAnoPos,...
    'String',{'+'},...
    cSettings{:});

% Go annotation for auditory stimulu
annoStr.Go = annotation(VBFig, 'textbox', cuAnoPos,...
    'String', {'+'},...
    cSettingsGreen{:});

annoStr.Stop = annotation(VBFig, 'textbox', cuAnoPos,...
    'String', {'+'},...
    cSettingsRed{:});

% Stim annotation
annoStr.Stim = annotation(VBFig,'textbox', stimAnoPos,...
    'String',{'stim'},...
    cSettings{:});

end

% Function to determine annotation position
% positions must be normalized by monitor size to be usable with function
% annotation
function anoPos = getPos(anoD, winPos)
    anoW = round(anoD(1)/winPos(3), 2);
    anoH = round(anoD(2)/winPos(4), 2);
    anoX = 0.5 - anoW/2;
    anoY = 0.5 - anoH/2;
    anoPos = [anoX anoY anoW anoH];
end

%% Commands to use within the main script / trial
% Use the following to set up the visual annotations and
% manipulate stim presentation

% sets up 'annoStr' variable which is used to manipulate the
% created visual annotations
%       annoStr = setUpVisAnnot();

% How to turn specific annotation 'on' / 'off'
%       set(annoStr.Ready, 'Visible','on');  % Turn on 'Ready?'
%       set(annoStr.Ready, 'Visible','off'); % Turn off 'Ready?'

%       set(annoStr.Plus, 'Visible','on');   % Turn on fixation 'Cross'
%       set(annoStr.Plus, 'Visible','off');  % Turn off fixation 'Cross'

%       annoStr.Stim.String = 'stim1';      % change the stimulus to desired word (in this case 'stim1')

%       set(annoStr.Stim,'Visible','on');  % Turn on stimulus
%       set(annoStr.Stim,'Visible','off');  % Turn off stimulus

%       set([annoStr.Stim annoStr.visTrig],'Visible','on');  % Turn on stimulus + trigger box
%       set([annoStr.Stim annoStr.visTrig],'Visible','off'); % Turn off stimulus + trigger box

