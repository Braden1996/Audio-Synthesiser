% All the callbacks for our toolbar.
function found = toolbarFcn(hObject, eventdata, handles, id)
    found = true;

    switch id
        case 'pushToolOpen'
            pushToolOpen_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolSave'
            pushToolSave_ClickedCallback(hObject, eventdata, handles);
        case 'toggleToolColorbar_On'
            toggleToolColorbar_OnCallback(hObject, eventdata, handles);
        case 'toggleToolColorbar_Off'
            toggleToolColorbar_OffCallback(hObject, eventdata, handles);
        case 'toggleToolPlayAudio_On'
            toggleToolPlayAudio_OnCallback(hObject, eventdata, handles);
        case 'toggleToolPlayAudio_Off'
            toggleToolPlayAudio_OffCallback(hObject, eventdata, handles);
        case 'pushToolStopAudio'
            pushToolStopAudio_ClickedCallback(hObject, eventdata, handles);
        case 'toggleToolLoopAudio_On'
            toggleToolLoopAudio_OnCallback(hObject, eventdata, handles);
        case 'toggleToolLoopAudio_Off'
            toggleToolLoopAudio_OffCallback(hObject, eventdata, handles);
        case 'pushToolClearMask'
            pushToolClearMask_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolInverseMask'
            pushToolInverseMask_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolColorMap'
            pushToolColorMap_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolMaskColor'
            pushToolMaskColor_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolADSR'
            pushToolADSR_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolWahwah'
            pushToolWahwah_ClickedCallback(hObject, eventdata, handles);
        case 'pushToolFlanger'
            pushToolFlanger_ClickedCallback(hObject, eventdata, handles);
        otherwise
            found = false;
    end


function pushToolOpen_ClickedCallback(hObject, eventdata, handles)
    audio_formats = getappdata(groot, 'AudioFormats');
    [FileName, PathName] = uigetfile(audio_formats, 'Select Audio File');
    
    if ~isequal(FileName, 0)

        % Read in the audio at the specified path
        FilePath = fullfile(PathName, FileName);
        [fileSound, fs] = audioread(FilePath);
        
        [~,n] = size(fileSound);
        y = sum(fileSound, 2) / n; % Force Mono
        
        % Clear our effects pipeline and then insert a 'root' effect.
        import lib.pipeline.PipelineData
        effectPipeline = getappdata(groot, 'EffectPipeline');
        effectPipeline.clear();
        
        rootData = PipelineData(@(x,d) d(2:3), {'Audio Loaded',y,fs});
        
        atDepth = handles.listboxHistory.Value;
        afterNode = effectPipeline.getNodeAtDepth(atDepth);
        effectPipeline.insert(afterNode,rootData);
        
        setappdata(groot, 'EffectPipeline', effectPipeline);
        
        % Enable the extra toolbar functionality.
        theStateSwitch = getappdata(groot, 'StateSwitch');
        theStateSwitch.on('audioloaded');
        
        % Refresh listboxHistory state.
        % (Due to limitations with StateSwitch)
        import lib.router
        router(hObject, eventdata, handles, 'listboxHistory');
    end

function pushToolSave_ClickedCallback(hObject, eventdata, handles)
    audio_formats = getappdata(groot, 'AudioFormats');
    [FileName, PathName, FilterIndex] = uiputfile(audio_formats,...
        'Save Audio As');
    if ~isequal(FileName, 0)
        % Handle empty extensions.
        [~,~,ext] = fileparts(FileName);
        if isempty(ext)
            filter_ext = audio_formats(FilterIndex);
            [~,~,filter_ext] = fileparts(filter_ext);
            FileName = strcat(FileName, filter_ext);
        end

        FilePath = fullfile(PathName, FileName);
        
        y = getappdata(groot, 'AudioY');
        fs = getappdata(groot, 'AudioFS');
        audiowrite(FilePath, y, fs);
    end


function toggleToolColorbar_OnCallback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    theSpectrogram.enableColorbar();

function toggleToolColorbar_OffCallback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    theSpectrogram.disableColorbar();


function toggleToolPlayAudio_OnCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.play();

function toggleToolPlayAudio_OffCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.pause();


function pushToolStopAudio_ClickedCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.stop();


function toggleToolLoopAudio_OnCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.LoopAudio = true;

function toggleToolLoopAudio_OffCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.LoopAudio = false;


function pushToolClearMask_ClickedCallback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    theSpectrogram.clearMask();
    

function pushToolInverseMask_ClickedCallback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    theSpectrogram.inverseMask();


function pushToolColorMap_ClickedCallback(hObject, eventdata, handles)
    imcolormaptool(handles.synthesiser);
    

function pushToolMaskColor_ClickedCallback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    c = theSpectrogram.MaskColor(1:3);
    c = uisetcolor(c, 'Select Mask Display Color');
    theSpectrogram.MaskColor = c;

    
function pushToolADSR_ClickedCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    y = theAudioPlayerControl.Y;
    len = length(y);
    
    overshoot = getappdata(groot, 'adsrLastOvershoot');
    adsrData = getappdata(groot, 'adsrLastADSR');
    
    if isempty(overshoot) || isempty(adsrData)
        [saved, overshoot, adsrData, ~] = adsrModal(len);
    else
        [saved, overshoot, adsrData, ~] = adsrModal(len,...
            'overshoot', overshoot, 'adsr', adsrData);
    end
    
    setappdata(groot, 'adsrLastOvershoot', overshoot);
    setappdata(groot, 'adsrLastADSR', adsrData);
    
    % If modal is confirmed, insert into effects pipeline.
    if saved
        startSample = theAudioPlayerControl.getLoopStartSample();
        endSample = theAudioPlayerControl.getLoopEndSample();
    
        import lib.pipeline.PipelineData
        effectPipeline = getappdata(groot, 'EffectPipeline');
        applyData = {'ADSR',adsrData,overshoot,startSample, endSample};
        effectData = PipelineData(@applyAdsr,applyData);
        
        atDepth = handles.listboxHistory.Value;
        afterNode = effectPipeline.getNodeAtDepth(atDepth);
        effectPipeline.insert(afterNode,effectData);
    end
    
function outResultData = applyAdsr(inResultData, effectData)
    adsrData = effectData{2};
    overshoot = effectData{3};
    startSample = effectData{4};
    endSample = effectData{5};

    outResultData = inResultData;
    
    y = outResultData{1};
    
    ySelection = y(startSample:endSample);
    
    import lib.getAdsrEnvelope
    adsrEnvelope = getAdsrEnvelope(adsrData(1),adsrData(2),adsrData(3),...
        adsrData(4),length(ySelection),overshoot);
    ySelection = ySelection .* (adsrEnvelope.');

    y(startSample:endSample) = ySelection;
    
    outResultData{1} = y;
    
function pushToolWahwah_ClickedCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    y = theAudioPlayerControl.Y;
    fs = theAudioPlayerControl.Fs;
    
    startSample = theAudioPlayerControl.getLoopStartSample();
    endSample = theAudioPlayerControl.getLoopEndSample();
    y = y(startSample:endSample);
    
    damp = getappdata(groot, 'wahwahLastDamp');
    minF = getappdata(groot, 'wahwahLastMinF');
    maxF = getappdata(groot, 'wahwahLastMaxF');
    fw = getappdata(groot, 'wahwahLastWahF');
    
    if isempty(damp) || isempty(minF) || isempty(maxF) || isempty(fw)
        [saved, damp, minF, maxF, fw] = wahwahModal(y, fs);
    else
        [saved, damp, minF, maxF, fw] = wahwahModal(y, fs,...
            'Damp', damp, 'MinF', minF, 'MaxF', maxF, 'WahF', fw);
    end
    
    setappdata(groot, 'wahwahLastDamp', damp);
    setappdata(groot, 'wahwahLastMinF', minF);
    setappdata(groot, 'wahwahLastMaxF', maxF);
    setappdata(groot, 'wahwahLastWahF', fw);
    
    % If modal is confirmed, insert into effects pipeline.
    if saved
        import lib.pipeline.PipelineData
        effectPipeline = getappdata(groot, 'EffectPipeline');
        applyData = {'Wah-Wah',damp,minF,maxF,fw,startSample,endSample};
        effectData = PipelineData(@applyWahwah,applyData);
        
        atDepth = handles.listboxHistory.Value;
        afterNode = effectPipeline.getNodeAtDepth(atDepth);
        effectPipeline.insert(afterNode,effectData);
    end
    
function outResultData = applyWahwah(inResultData, effectData)
    damp = effectData{2};
    minF = effectData{3};
    maxF = effectData{4};
    fw = effectData{5};
    startSample = effectData{6};
    endSample = effectData{7};

    outResultData = inResultData;
    
    y = outResultData{1};
    fs = outResultData{2};
    
    ySelection = y(startSample:endSample);
    
    import thirdparty.wahwah
    ySelection = wahwah(ySelection, fs, damp, minF, maxF, fw);

    y(startSample:endSample) = ySelection;
    
    outResultData{1} = y;
    
function pushToolFlanger_ClickedCallback(hObject, eventdata, handles)
    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    y = theAudioPlayerControl.Y;
    fs = theAudioPlayerControl.Fs;
    
    startSample = theAudioPlayerControl.getLoopStartSample();
    endSample = theAudioPlayerControl.getLoopEndSample();
    y = y(startSample:endSample);
    
    mtd = getappdata(groot, 'flangerLastMaxTimeDelay');
    flangRate = getappdata(groot, 'flangerLastRate');
    
    if isempty(mtd) || isempty(flangRate)
        [saved, mtd, flangRate] = flangerModal(y, fs);
    else
        [saved, mtd, flangRate] = flangerModal(y, fs,...
            'MaxTimeDelay', mtd, 'Rate', flangRate);
    end
    
    setappdata(groot, 'flangerLastMaxTimeDelay', mtd);
    setappdata(groot, 'flangerLastRate', flangRate);
    
    % If modal is confirmed, insert into effects pipeline.
    if saved
        import lib.pipeline.PipelineData
        effectPipeline = getappdata(groot, 'EffectPipeline');
        applyData = {'Flanger',mtd,flangRate,startSample,endSample};
        effectData = PipelineData(@applyFlanger,applyData);
        
        atDepth = handles.listboxHistory.Value;
        afterNode = effectPipeline.getNodeAtDepth(atDepth);
        effectPipeline.insert(afterNode,effectData);
    end
    
function outResultData = applyFlanger(inResultData, effectData)
    mtd = effectData{2};
    flangRate = effectData{3};
    startSample = effectData{4};
    endSample = effectData{5};

    outResultData = inResultData;
    
    y = outResultData{1};
    fs = outResultData{2};
    
    ySelection = y(startSample:endSample);
    
    import thirdparty.flanger
    ySelection = flanger(ySelection, fs, mtd, flangRate);

    y(startSample:endSample) = ySelection;
    
    outResultData{1} = y;