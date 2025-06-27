function varargout = AlgorithmSelect(varargin)
% ALGORITHMSELECT MATLAB code for AlgorithmSelect.fig
%      ALGORITHMSELECT, by itself, creates a new ALGORITHMSELECT or raises the existing
%      singleton*.
%
%      H = ALGORITHMSELECT returns the handle to a new ALGORITHMSELECT or the handle to
%      the existing singleton*.
%
%      ALGORITHMSELECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALGORITHMSELECT.M with the given input arguments.
%
%      ALGORITHMSELECT('Property','Value',...) creates a new ALGORITHMSELECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AlgorithmSelect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AlgorithmSelect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AlgorithmSelect

% Last Modified by GUIDE v2.5 10-Jan-2020 12:41:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlgorithmSelect_OpeningFcn, ...
                   'gui_OutputFcn',  @AlgorithmSelect_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
                              
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before AlgorithmSelect is made visible.
function AlgorithmSelect_OpeningFcn(hObject, eventdata, handles)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AlgorithmSelect (see VARARGIN)

% Choose default command line output for AlgorithmSelect
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AlgorithmSelect wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = AlgorithmSelect_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
%Select Algorithm
global algoSelect
if (get(handles.radiobutton1,'Value'))==1
    fprintf('Algorithm selected: pp_none\n')
    algoSelect = 'pp_none';
end

if (get(handles.radiobutton2,'Value'))==1
    fprintf('Algorithm selected: pp_peaks\n')
    algoSelect = 'pp_peaks';
end

if (get(handles.radiobutton3,'Value'))==1
    fprintf('Algorithm selected: pp_valleys\n')
    algoSelect = 'pp_valleys';
end

close(gcf)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
%select pp_none
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
%select p_peaks
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
%select pp_valleys
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
%pp_none No Shift
wavFile = dir('*pp_none-noshift.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
%pp_none Shift Up
wavFile = dir('*pp_none-shiftup.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
%pp_none Shift Down
wavFile = dir('*pp_none-shiftdown.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton11.

% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
%pp_peaks No Shift
wavFile = dir('*pp_peaks-noshift.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
%pp_peaks Shift Up
wavFile = dir('*pp_peaks-shiftup.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function pushbutton11_Callback(hObject, eventdata, handles)
%pp_peaks Shift Down
wavFile = dir('*pp_peaks-shiftdown.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
%pp_valleys no shift
wavFile = dir('*pp_valleys-noshift.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
%pp_valleys shift up
wavFile = dir('*pp_valleys-shiftup.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
%pp_valleys shift down
wavFile = dir('*pp_valleys-shiftdown.wav');
[wavData wavFs] = audioread(wavFile.name);
sound(wavData(:,1), wavFs)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
