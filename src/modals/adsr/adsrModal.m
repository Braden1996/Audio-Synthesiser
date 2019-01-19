function varargout = adsrModal(varargin)
% ADSR MATLAB code for adsrModal.fig
%      ADSR by itself, creates a new ADSR or raises the
%      existing singleton*.
%
%      H = ADSR returns the handle to a new ADSR or the handle to
%      the existing singleton*.
%
%      ADSR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADSR.M with the given input arguments.
%
%      ADSR('Property','Value',...) creates a new ADSR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before adsr_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to adsr_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help adsr

% Last Modified by GUIDE v2.5 26-Nov-2016 23:12:09
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @adsrModal_OpeningFcn, ...
                       'gui_OutputFcn',  @adsrModal_OutputFcn, ...
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

function adsrModal_OpeningFcn(hObject, eventdata, handles, varargin)
    i_p = inputParser;
    i_p.FunctionName = 'adsrModal_OpeningFcn';
    i_p.addRequired('Length', @isnumeric);
    i_p.addOptional('Overshoot', 1, @isnumeric);
    isadsr = @(x) length(x) == 4 && sum(x < 0) == 0;
    i_p.addOptional('Adsr', [0.0 0.0 1.0 0.0], isadsr);
    i_p.parse(varargin{:});

    setappdata(handles.figureADSR, 'Length', i_p.Results.Length);
    setappdata(handles.figureADSR, 'Saved', false);
    
    handles.sliderOvershoot.Value = i_p.Results.Overshoot;
    
    adsr = i_p.Results.Adsr;
    handles.sliderAttack.Value = adsr(1);
    handles.sliderDecay.Value = adsr(2);
    handles.sliderSustain.Value = adsr(3);
    handles.sliderRelease.Value = adsr(4);
    
    axesADSR_Update(handles);
    
    handles.axes.XTick = [];
    handles.axes.YTick = [];

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
    set(handles.figureADSR,'WindowStyle','modal')

    % UIWAIT makes adsr wait for user response (see UIRESUME)
    uiwait(handles.figureADSR);

function varargout = adsrModal_OutputFcn(hObject, eventdata, handles)
    varargout{1} = getappdata(handles.figureADSR, 'Saved');

    varargout{2} = handles.sliderOvershoot.Value;

    a = handles.sliderAttack.Value;
    d = handles.sliderDecay.Value;
    s = handles.sliderSustain.Value;
    r = handles.sliderRelease.Value;
    varargout{3} = [a,d,s,r];
    varargout{4} = getappdata(handles.figureADSR, 'Envelope').';

    % The figure can be deleted now
    delete(handles.figureADSR);

    
function figureADSR_CloseRequestFcn(hObject, eventdata, handles)
    if isequal(get(hObject, 'waitstatus'), 'waiting')
        % The GUI is still in UIWAIT, us UIRESUME
        uiresume(hObject);
    else
        % The GUI is no longer waiting, just close it
        delete(hObject);
    end


function figureADSR_KeyPressFcn(hObject, eventdata, handles)
    % Check for "enter" or "escape"
    if isequal(get(hObject,'CurrentKey'),'escape')
        % User said no by hitting escape
        handles.output = 'No';

        % Update handles structure
        guidata(hObject, handles);

        uiresume(handles.figureADSR);
    end    

    if isequal(get(hObject,'CurrentKey'),'return')
        setappdata(handles.figureADSR, 'Saved', true);
        uiresume(handles.figureADSR);
    end
    
    
% Update our ADSR plot
function axesADSR_Update(handles)
    len = getappdata(handles.figureADSR, 'Length');
    
    a = handles.sliderAttack.Value;
    d = handles.sliderDecay.Value;
    s = handles.sliderSustain.Value;
    r = handles.sliderRelease.Value;
    
    % Normalise
    adsrNorm = a + d + s + r;
    a = a / adsrNorm;
    d = d / adsrNorm;
    s = s / adsrNorm;
    r = r / adsrNorm;
    
    overshoot = handles.sliderOvershoot.Value;
    
    import lib.getAdsrEnvelope
    envelope = getAdsrEnvelope(a,d,s,r,len,overshoot);
    
    setappdata(handles.figureADSR, 'Envelope', envelope);
    
    adsrPlot = getappdata(handles.figureADSR, 'AdsrPlot');
    if isempty(adsrPlot)
        adsrPlot = plot(handles.axes, envelope, 'linewidth', 2);
        setappdata(handles.figureADSR, 'AdsrPlot', adsrPlot);
    else
        adsrPlot.YData = envelope;
    end


function slider_Callback(hObject, eventdata, handles)
    axesADSR_Update(handles);

function slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'),...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    

function buttonOkay_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    setappdata(handles.figureADSR, 'Saved', true);
    uiresume(handles.figureADSR);

function cancelButton_Callback(hObject, eventdata, handles)
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figureADSR);
