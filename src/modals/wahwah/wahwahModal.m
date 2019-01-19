function varargout = wahwahModal(varargin)
% WAHWAHMODAL MATLAB code for wahwahModal.fig
%      WAHWAHMODAL by itself, creates a new WAHWAHMODAL or raises the
%      existing singleton*.
%
%      H = WAHWAHMODAL returns the handle to a new WAHWAHMODAL or the handle to
%      the existing singleton*.
%
%      WAHWAHMODAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAHWAHMODAL.M with the given input arguments.
%
%      WAHWAHMODAL('Property','Value',...) creates a new WAHWAHMODAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before wahwahModal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to wahwahModal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help wahwahModal

% Last Modified by GUIDE v2.5 27-Nov-2016 18:25:38

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @wahwahModal_OpeningFcn, ...
                       'gui_OutputFcn',  @wahwahModal_OutputFcn, ...
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

% --- Executes just before wahwahModal is made visible.
function wahwahModal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to wahwahModal (see VARARGIN)
    i_p = inputParser;
    i_p.FunctionName = 'wahwahModal_OpeningFcn';
    i_p.addRequired('Y', @isnumeric);
    i_p.addRequired('Fs', @isnumeric);
    i_p.addOptional('Damp', 0.05, @isnumeric);
    i_p.addOptional('MinF', 500, @isnumeric);
    i_p.addOptional('MaxF', 3000, @isnumeric);
    i_p.addOptional('WahF', 2000, @isnumeric);
    i_p.parse(varargin{:});
    
    y = i_p.Results.Y;
    fs = i_p.Results.Fs;

    setappdata(handles.figureWahwah, 'Y', y);
    setappdata(handles.figureWahwah, 'Fs', fs);
    setappdata(handles.figureWahwah, 'Saved', false);
    
    % Get highest frequency
    yf = fft(y);
    highestIdx = find(real(yf(1:floor(length(y)/2))),1,'last');
    highestFreq = floor(((highestIdx-1) / (length(y) / fs))/2);
    setappdata(handles.figureWahwah, 'HighestFreq', highestFreq);

    handles.sliderFreqMin.Max = highestFreq - 1;
    handles.sliderFreqSize.Max = highestFreq;
    
    handles.sliderDampFactor.Value = i_p.Results.Damp;
    handles.sliderFreqMin.Value = min(i_p.Results.MinF, highestFreq-1);
    handles.sliderFreqSize.Value = min(i_p.Results.MaxF, highestFreq);
    handles.sliderFreqWah.Value = i_p.Results.WahF;
    axesWahwah_Update(handles);
    
    handles.axesWahwah.XTick = [];
    handles.axesWahwah.YTick = [];

    % Update handles structure
    guidata(hObject, handles);

    % Determine the position of the dialog - centered on the callback figure
    % if available, else, centered on the screen
    FigPos=get(0,'DefaultFigurePosition');
    OldUnits = get(hObject, 'Units');
    set(hObject, 'Units', 'pixels');
    OldPos = get(hObject,'Position');
    FigWidth = OldPos(3);
    FigHeight = OldPos(4);
    if isempty(gcbf)
        ScreenUnits=get(0,'Units');
        set(0,'Units','pixels');
        ScreenSize=get(0,'ScreenSize');
        set(0,'Units',ScreenUnits);

        FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
        FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
    else
        GCBFOldUnits = get(gcbf,'Units');
        set(gcbf,'Units','pixels');
        GCBFPos = get(gcbf,'Position');
        set(gcbf,'Units',GCBFOldUnits);
        FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                       (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
    end
    FigPos(3:4)=[FigWidth FigHeight];
    set(hObject, 'Position', FigPos);
    set(hObject, 'Units', OldUnits);

    % Make the GUI modal
    set(handles.figureWahwah,'WindowStyle','modal')

    % UIWAIT makes wahwahModal wait for user response (see UIRESUME)
    uiwait(handles.figureWahwah);

% --- Outputs from this function are returned to the command line.
function varargout = wahwahModal_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    varargout{1} = getappdata(handles.figureWahwah, 'Saved');
    
    maxFreq = getappdata(handles.figureWahwah, 'HighestFreq');

    varargout{2} = handles.sliderDampFactor.Value;
    varargout{3} = min(handles.sliderFreqMin.Value, maxFreq-1);
    sizef = varargout{3} + handles.sliderFreqSize.Value;
    varargout{4} = min(sizef, maxFreq);

    varargout{5} = handles.sliderFreqWah.Value;

    % The figure can be deleted now
    delete(handles.figureWahwah);


% --- Executes when user attempts to close figureWahwah.
function figureWahwah_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figureWahwah (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes on key press over figureWahwah with no controls selected.
function figureWahwah_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figureWahwah (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
    if isequal(get(hObject,'CurrentKey'),'escape')
        % User said no by hitting escape
        handles.output = 'No';

        % Update handles structure
        guidata(hObject, handles);

        uiresume(handles.figureWahwah);
    end    

    if isequal(get(hObject,'CurrentKey'),'return')
        setappdata(handles.figureWahwah, 'Saved', true);
        uiresume(handles.figureWahwah);
    end

function axesWahwah_Update(handles)
    x = getappdata(handles.figureWahwah, 'Y');
    fs = getappdata(handles.figureWahwah, 'Fs');
    damp = handles.sliderDampFactor.Value;
    
    maxFreq = getappdata(handles.figureWahwah, 'HighestFreq');
    minf = min(handles.sliderFreqMin.Value, maxFreq-1);
    sizef = minf + handles.sliderFreqSize.Value;
    maxf = min(sizef, maxFreq);

    fw = handles.sliderFreqWah.Value;
    
    import thirdparty.wahwah
    newY = wahwah(x,fs,damp,minf,maxf,fw);
    
    wahwahPlot = getappdata(handles.figureWahwah, 'WahwahPlot');
    if isempty(wahwahPlot)
        wahwahPlot = plot(handles.axesWahwah, newY, 'linewidth', 2);
        setappdata(handles.figureWahwah, 'WahwahPlot', wahwahPlot);
    else
        wahwahPlot.YData = newY;
    end


function slider_Callback(hObject, eventdata, handles)
    axesWahwah_Update(handles);

function buttonOkay_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    setappdata(handles.figureWahwah, 'Saved', true);
    uiresume(handles.figureWahwah);

function buttonCancel_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figureWahwah);

function slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'),...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
