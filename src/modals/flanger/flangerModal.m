function varargout = flangerModal(varargin)
% FLANGERMODAL MATLAB code for flangerModal.fig
%      FLANGERMODAL by itself, creates a new FLANGERMODAL or raises the
%      existing singleton*.
%
%      H = FLANGERMODAL returns the handle to a new FLANGERMODAL or the handle to
%      the existing singleton*.
%
%      FLANGERMODAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLANGERMODAL.M with the given input arguments.
%
%      FLANGERMODAL('Property','Value',...) creates a new FLANGERMODAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before flangerModal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to flangerModal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help flangerModal

% Last Modified by GUIDE v2.5 28-Nov-2016 20:23:52

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @flangerModal_OpeningFcn, ...
                       'gui_OutputFcn',  @flangerModal_OutputFcn, ...
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

% --- Executes just before flangerModal is made visible.
function flangerModal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to flangerModal (see VARARGIN)
    i_p = inputParser;
    i_p.FunctionName = 'flangerModal_OpeningFcn';
    i_p.addRequired('Y', @isnumeric);
    i_p.addRequired('Fs', @isnumeric);
    i_p.addOptional('MaxTimeDelay', 0.003, @isnumeric);
    i_p.addOptional('Rate', 1, @isnumeric);
    i_p.parse(varargin{:});
    
    y = i_p.Results.Y;
    fs = i_p.Results.Fs;

    setappdata(handles.figureFlanger, 'Y', y);
    setappdata(handles.figureFlanger, 'Fs', fs);
    setappdata(handles.figureFlanger, 'Saved', false);
    
    handles.sliderMaxTimeDelay.Value = i_p.Results.MaxTimeDelay;
    handles.sliderRate.Value = i_p.Results.Rate;
    axesFlanger_Update(handles);
    
    handles.axesFlanger.XTick = [];
    handles.axesFlanger.YTick = [];

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
    set(handles.figureFlanger,'WindowStyle','modal')

    % UIWAIT makes flangerModal wait for user response (see UIRESUME)
    uiwait(handles.figureFlanger);

% --- Outputs from this function are returned to the command line.
function varargout = flangerModal_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    varargout{1} = getappdata(handles.figureFlanger, 'Saved');

    varargout{2} = handles.sliderMaxTimeDelay.Value;
    varargout{3} = handles.sliderRate.Value;

    % The figure can be deleted now
    delete(handles.figureFlanger);


% --- Executes when user attempts to close figureFlanger.
function figureFlanger_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figureFlanger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if isequal(get(hObject, 'waitstatus'), 'waiting')
        % The GUI is still in UIWAIT, us UIRESUME
        uiresume(hObject);
    else
        % The GUI is no longer waiting, just close it
        delete(hObject);
    end


% --- Executes on key press over figureFlanger with no controls selected.
function figureFlanger_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figureFlanger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
    if isequal(get(hObject,'CurrentKey'),'escape')
        % User said no by hitting escape
        handles.output = 'No';

        % Update handles structure
        guidata(hObject, handles);

        uiresume(handles.figureFlanger);
    end    

    if isequal(get(hObject,'CurrentKey'),'return')
        setappdata(handles.figureFlanger, 'Saved', true);
        uiresume(handles.figureFlanger);
    end

function axesFlanger_Update(handles)
    x = getappdata(handles.figureFlanger, 'Y');
    fs = getappdata(handles.figureFlanger, 'Fs');
    
    mtd = handles.sliderMaxTimeDelay.Value;
    flangRate = handles.sliderRate.Value;
    
    import thirdparty.flanger
    newY = flanger(x,fs,mtd,flangRate);
    
    flangerPlot = getappdata(handles.figureFlanger, 'FlangerPlot');
    if isempty(flangerPlot)
        flangerPlot = plot(handles.axesFlanger, newY, 'linewidth', 2);
        setappdata(handles.figureFlanger, 'FlangerPlot', flangerPlot);
    else
        flangerPlot.YData = newY;
    end


function slider_Callback(hObject, eventdata, handles)
    axesFlanger_Update(handles);

function buttonOkay_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    setappdata(handles.figureFlanger, 'Saved', true);
    uiresume(handles.figureFlanger);

function buttonCancel_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figureFlanger);

function slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'),...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
