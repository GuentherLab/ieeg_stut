function annoStr = setUpVisAnnot_HW(op)
% Setting up visualization
% Helper script that sets up a couple of annotation objects that can be used for
% stimulus visualization / presentation.
%

HW_testing = false;

if nargin<1||isempty(op.background_color), op.background_color = [0 0 0]; end
txt = 1 - op.background_color;

%% get monitorSize and set up related var
monitorSize = get(0, 'Monitor');
numMon = size(monitorSize, 1);

if numMon == 2
    figPosition = [monitorSize(2,1) monitorSize(2,2) monitorSize(2,3) monitorSize(2,4)];
else
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
% instructAnoD = [900 300];
instructAnoD = [600 300];

instructAnoPos = getPos(instructAnoD, winPos);

% Preparing 'Cue' Annotation Position
cuAnoD = [250 150];
cuAnoPos = getPos(cuAnoD, winPos);

% Preparing 'Stim' Annotation Position
% % % % stimAnoD = [700 300]; % if stim too small/large, need to adjust
% % % % stimAnoPos = getPos(stimAnoD, winPos);
stimAnoPos = [0 0 1 1]; % full screen


%% Actually create the stim presentation figure
% this causes the stim window to appear
VBFig = figure('NumberTitle', 'off', 'Color', op.background_color, 'Position', winPos, 'MenuBar', 'none');
drawnow; 
if ~HW_testing
    if ~isequal(get(VBFig,'position'),winPos), set(VBFig,'Position',winPos); end % fix needed only on some dual monitor setups
end

% Common annotation settings
cSettings = {'Color',txt,...
    'LineStyle','none',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'FontSize',130,...
    'FontWeight','bold',...
    'FontName','Arial',...
    'FitBoxToText','off',...
    'EdgeColor','none',...
    'BackgroundColor',op.background_color,...
    'visible','off'};

% Ready annotation
annoStr.Instruction = annotation(VBFig,'textbox', instructAnoPos,...
    'String',{'READY'},...
    cSettings{:});

% Cue annotation
annoStr.Plus = annotation(VBFig,'textbox', cuAnoPos,...
    'String',{'+'},...
    cSettings{:});

% Stim annotation
annoStr.Stim = annotation(VBFig,'textbox', stimAnoPos,...
    'String',{'stim'},...
    cSettings{:});

% Exclamation point annotation [Irani 2023 protocol]
annoStr.Exclam = annotation(VBFig,'textbox', stimAnoPos,...
    'String',{'!!!'},...
    cSettings{:});

% annoStr.Pic = axes(VBFig, 'pos',[1/2-winPos(4)/(4*winPos(3)), 0.25, winPos(4)/(2*winPos(3)), 0.5]); % left bottom width height... position values for DBSMultisyllabic stim
% annoStr.Pic = axes(VBFig, 'pos',2*[1/2-winPos(4)/(4*winPos(3)), 0.25, winPos(4)/(2*winPos(3)), 0.5]); % left bottom width height... position values for DBSMultisyllabic stim
annoStr.Pic = axes(VBFig, 'pos', [0 0 1 1]); 

axes(annoStr.Pic)
imshow([])
drawnow


end

% Function to determine annotation position
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

