% TODO:
%   - Fix effect insert between two existing effects, i.e. not a push
function varargout = synthesiser(varargin)
% SYNTHESISER MATLAB code for synthesiser.fig
%     SYNTHESISER, by itself, creates a new SYNTHESISER or raises the existing
%      singleton*.
%
%      H = SYNTHESISER returns the handle to a new SYNTHESISER or the handle to
%      the existing singleton*.
%
%      SYNTHESISER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SYNTHESISER.M with the given input arguments.
%
%      SYNTHESISER('Property','Value',...) creates a new SYNTHESISER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before synthesiser_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to synthesiser_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help synthesiser

% Last Modified by GUIDE v2.5 26-Nov-2016 20:52:52
    % Add subdirectory files to path
    folder = fileparts(which('synthesiser.m')); 
    modals = genpath(fullfile(folder, 'modals'));
    addpath(modals);

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @synthesiser_OpeningFcn, ...
                       'gui_OutputFcn',  @synthesiser_OutputFcn, ...
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


% --- Executes just before synthesiser is made visible.
function synthesiser_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to synthesiser (see VARARGIN)
    % Choose default command line output for synthesiser
    handles.output = hObject;

    % Center the figure
    movegui(hObject, 'center');

    % Give the window a title
    hObject.Name = 'Audio Synthesiser - By Braden Marshall';
    
    % Import to handle callbacks
    import lib.router
    
    
    % Define some app data
    setappdata(groot, 'AudioFormats', {
        '*.wav', 'WAVE';
        '*.ogg', 'OGG';
        '*.flac', 'FLAC';
        '*.mp3', 'MP3';
        '*.m4a;*.mp4', 'MPEG-4 AAC';
        }...
    );

    % Setup our StateSwitch, which manages groups of GUI components based
    % upon arbitrary states within the system.
    import userinterface.general.StateSwitch
    theStateSwitch = StateSwitch();
    theStateSwitch.add(handles.pushToolSave, 'audioloaded');
    theStateSwitch.add(handles.toggleToolZoomOut, 'audioloaded');
    theStateSwitch.add(handles.toggleToolZoomIn, 'audioloaded');
    theStateSwitch.add(handles.toggleToolPan, 'audioloaded');
    theStateSwitch.add(handles.toggleToolColorbar, 'audioloaded');
    theStateSwitch.add(handles.toggleToolPlayAudio, 'audioloaded');
    theStateSwitch.add(handles.toggleToolLoopAudio, 'audioloaded');
    theStateSwitch.add(handles.pushToolInverseMask, 'audioloaded');
    theStateSwitch.add(handles.pushToolColorMap, 'audioloaded');
    theStateSwitch.add(handles.pushToolMaskColor, 'audioloaded');
    theStateSwitch.add(handles.pushToolADSR, 'audioloaded');
    theStateSwitch.add(handles.pushToolWahwah, 'audioloaded');
    theStateSwitch.add(handles.pushToolFlanger, 'audioloaded');
    theStateSwitch.add(handles.panelBrush, 'audioloaded');
    theStateSwitch.add(handles.panelOperations, 'audioloaded');
    theStateSwitch.add(handles.panelMaskAlpha, 'audioloaded');
    theStateSwitch.add(handles.panelHistory, 'audioloaded');
    theStateSwitch.add(handles.panelKeyboard, 'audioloaded');

    theStateSwitch.add(handles.pushToolClearMask, 'maskempty', true);
    theStateSwitch.add(handles.pushToolStopAudio, 'audioplaying');
    
    theStateSwitch.add(handles.buttonMoveUpEffect, ...
        'historyselect1', true);
    theStateSwitch.add(handles.buttonMoveUpEffect, ...
        'historyselect2', true);
    theStateSwitch.add(handles.buttonMoveDownEffect, ...
        'historyselect1', true);
    theStateSwitch.add(handles.buttonMoveDownEffect, ...
        'historyselectlast', true);
    theStateSwitch.add(handles.buttonUndoEffect, ...
        'historyselect1', true);
    
    % Trigger initial switch state
    theStateSwitch.off('audioloaded');
    theStateSwitch.off('audioplaying');
    theStateSwitch.on('maskempty');
    setappdata(groot, 'StateSwitch', theStateSwitch);
    

    % Begin to prepare our axes by hooking them up to our userinterface
    % controllers etc...
    
    % First, we setup our audio axes.
    audioAx = handles.axesAudio;
    setappdata(groot, 'AxesAudio', audioAx);
    cla(audioAx)
    % Make an arbitrary intial plot.
    import userinterface.plotAudio
    audioPlot = plotAudio([0 1], 44100, 'AudioAxes', audioAx);
    setappdata(groot, 'AudioPlot', audioPlot);
    % Disable axes labels.
    audioAx.XTick = [];
    audioAx.YTick = [];
    
    % Next, setup our spectrogram axes
    import userinterface.Spectrogram
    specAx = handles.axesSpectrogram;
    specAx.YAxis.Exponent = 0; % Disable the horrible exponent notation
    setappdata(groot, 'AxesSpectrogram', specAx);
    theSpectrogram = Spectrogram(specAx, @applyMaskCallback);
    setappdata(groot, 'Spectrogram', theSpectrogram);
    
    % Just to save space...
    bothAxes = [audioAx, specAx];
    
    % Link the two axes, so that their coordinates are alligned.
    linkaxes(bothAxes, 'x');
    
    % Setup our fancy Audioplayer control. This allows us to select areas
    % of the audio we wish to loop etc...
    import userinterface.audioplayer.AudioPlayerControl
    theAudioPlayerControl = AudioPlayerControl(audioAx,bothAxes);
    theAudioPlayerControl.PlayFcn = @playAudioCallback;
    theAudioPlayerControl.PauseFcn = @pauseAudioCallback;
    addlistener(theAudioPlayerControl, 'LoopSet', @(hObj,eventdata) ...
        router(hObj,eventdata,handles,'LoopSelectionChange'));
    setappdata(groot, 'AudioPlayerControl', theAudioPlayerControl);
    
    % Create our keyboard.
    import userinterface.Keyboard
    theKeyboard = Keyboard(bothAxes);
    setappdata(groot, 'Keyboard', theKeyboard);
    
    % Set default audio-effect configurations.
    setappdata(groot, 'AdsrLastOvershoot', []);
    setappdata(groot, 'AdsrLastADSR', []);

    setappdata(groot, 'wahwahLastDamp', []);
    setappdata(groot, 'wahwahLastMinF', []);
    setappdata(groot, 'wahwahLastMaxF', []);
    setappdata(groot, 'wahwahLastWahF', []);

    setappdata(groot, 'flangerLastMaxTimeDelay', []);
    setappdata(groot, 'flangerLastRate', []);
    
    % Attach initial values to our GUI components.
    handles.sliderAlphaSavedMask.Value = ...
        theSpectrogram.SavedMaskColor(4)*1;
    handles.sliderAlphaDragMask.Value = ...
        theSpectrogram.DragMaskColor(4)*1;
    handles.sliderAlphaMask.Value = ...
        theSpectrogram.MaskColor(4)*1;
    handles.sliderBrushSize.Value = ...
        theSpectrogram.TheMaskBrush.Radius;
    handles.sliderBrushOpacity.Value = ...
        theSpectrogram.TheMaskBrush.Opacity;
    handles.sliderBrushBlur.Value = ...
        theSpectrogram.TheMaskBrush.BlurStrength;
    
    % Setup our effect pipeline.
    import lib.pipeline.Pipeline
    effectPipeline = Pipeline();
    addlistener(effectPipeline, 'Insert',  @(hObj, eventdata) ...
        router(hObj,eventdata,handles,'Insert'));
    addlistener(effectPipeline, 'Remove',  @(hObj, eventdata) ...
        router(hObj,eventdata,handles,'Remove'));
    addlistener(effectPipeline, 'PostApply',  @(hObj, eventdata) ...
        router(hObj,eventdata,handles,'PostApply'));
    setappdata(groot, 'EffectPipeline', effectPipeline);

    % Update handles structure
    guidata(hObject, handles);
    
    set(hObject, 'CloseRequestFcn', @synthesiser_CloseRequestFcn);
 

% UIWAIT makes synthesiser wait for user response (see UIRESUME)
% uiwait(handles.synthesiser);


% --- Outputs from this function are returned to the command line.
function varargout = synthesiser_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function synthesiser_CloseRequestFcn(hObject,callbackdata)
    delete(getappdata(groot, 'AudioPlayerControl'));
    delete(getappdata(groot, 'Keyboard'));
    delete(hObject);
    

% To avoid making this entry file absolutely massive, we route all our GUI
% callbacks away.
function route(hObject, eventdata, handles, varargin)
    persistent p
    if isempty(p)
        p = inputParser;
        p.FunctionName = 'route'; 
        p.addParameter('id', '', @ischar);
    end
    p.parse(varargin{:});
    
    id = p.Results.id;
    if isempty(id)
        id = hObject.Tag;
    end

    import lib.router

    router(hObject, eventdata, handles, id);

function applyMaskCallback(theMask)
    theStateSwitch = getappdata(groot, 'StateSwitch');
    if nnz(theMask) == 0
        theStateSwitch.on('maskempty');
    else
        theStateSwitch.off('maskempty');
    end


function playAudioCallback(apc, startSample, totalSamples)
    theStateSwitch = getappdata(groot, 'StateSwitch');
    theStateSwitch.on('audioplaying');


function pauseAudioCallback(apc, currentSample, totalSamples)
    theStateSwitch = getappdata(groot, 'StateSwitch');
    eps = 0.1*apc.Fs;
    if abs(currentSample - apc.getLoopStartSample()) <= eps
        theStateSwitch.off('audioplaying');
        figureHandles = guidata(get(groot, 'currentFigure'));
        figureHandles.toggleToolPlayAudio.State = 'off';
    end
