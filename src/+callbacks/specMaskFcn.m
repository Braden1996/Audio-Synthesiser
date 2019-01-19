% All the callbacks for our toolbar.
function found = specMaskFcn(hObject, eventdata, handles, id)
    found = true;

    switch id
        case 'sliderAlphaSavedMask'
            theSpectrogram = getappdata(groot, 'Spectrogram');
            theSpectrogram.SavedMaskColor(4) = hObject.Value;
        case 'sliderAlphaDragMask'
            theSpectrogram = getappdata(groot, 'Spectrogram');
            theSpectrogram.DragMaskColor(4) = hObject.Value;
        case 'sliderAlphaMask'
            theSpectrogram = getappdata(groot, 'Spectrogram');
            theSpectrogram.MaskColor(4) = hObject.Value;
        case 'buttonApplySpectrogram'
            buttonApplySpectrogram_Callback(hObject, eventdata, handles);
        case 'buttonAddSpectralEnergy'
            buttonAddSpectralEnergy_Callback(hObject, eventdata, handles);
        case 'buttonSubtractSpectralEnergy'
            buttonSubtractSpectralEnergy_Callback(hObject, eventdata, handles);
        otherwise
            found = false;
    end

function buttonApplySpectrogram_Callback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    
    f = theSpectrogram.StftF;
    w = theSpectrogram.StftW;
    h = theSpectrogram.StftH;
    
    import lib.pipeline.PipelineData
    effectPipeline = getappdata(groot, 'EffectPipeline');
    applyData = {'Spectrogram Mask',theSpectrogram.Mask,f,w,h};
    effectData = PipelineData(@applySpectrogramMask,applyData);
    
    atDepth = handles.listboxHistory.Value;
    afterNode = effectPipeline.getNodeAtDepth(atDepth);
    effectPipeline.insert(afterNode,effectData);
    

function outResultData = applySpectrogramMask(inResultData, effectData)
    mask = effectData{2};
    stftF = effectData{3};
    stftW = effectData{4};
    stftH = effectData{5};

    outResultData = inResultData;
    
    y = outResultData{1};
    fs = outResultData{2};
    
    import thirdparty.stft
    import thirdparty.istft
    theStft = stft(y, stftF, stftW, stftH, fs);
    newStft = theStft .* mask;
    y = istft(newStft, stftF, stftW, stftH);
    
    outResultData{1} = y.'; % istft makes us need to transpose :(


function buttonAddSpectralEnergy_Callback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    
    f = theSpectrogram.StftF;
    w = theSpectrogram.StftW;
    h = theSpectrogram.StftH;
    
    import lib.pipeline.PipelineData
    effectPipeline = getappdata(groot, 'EffectPipeline');
    applyData = {'Add Spectral Energy',theSpectrogram.Mask,f,w,h};
    effectData = PipelineData(@applyAddSpectralEnergy,applyData);
    
    atDepth = handles.listboxHistory.Value;
    afterNode = effectPipeline.getNodeAtDepth(atDepth);
    effectPipeline.insert(afterNode,effectData);
    
% Increase the energy within the areas selected by 'mask'.
function outResultData = applyAddSpectralEnergy(inResultData, effectData)
    mask = effectData{2};
    stftF = effectData{3};
    stftW = effectData{4};
    stftH = effectData{5};

    outResultData = inResultData;
    
    y = outResultData{1};
    fs = outResultData{2};
    
    import thirdparty.stft
    import thirdparty.istft
    theStft = stft(y, stftF, stftW, stftH, fs);
    
    a = 0.5;
    b = 1;
    randomMask = mask .* ((b-a) .* rand(size(mask)) + a);
    scalingFactor = 10 * (stftF/stftH);
    addMask = randomMask .* (scalingFactor*(1 + 1i));
    newStft = theStft + addMask;

    y = istft(newStft, stftF, stftW, stftH);
    
    outResultData{1} = y.';


function buttonSubtractSpectralEnergy_Callback(hObject, eventdata, handles)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    
    f = theSpectrogram.StftF;
    w = theSpectrogram.StftW;
    h = theSpectrogram.StftH;
    
    import lib.pipeline.PipelineData
    effectPipeline = getappdata(groot, 'EffectPipeline');
    applyData = {'Subtract Spectral Energy',theSpectrogram.Mask,f,w,h};
    effectData = PipelineData(@applySubtractSpectralEnergy,applyData);
    
    atDepth = handles.listboxHistory.Value;
    afterNode = effectPipeline.getNodeAtDepth(atDepth);
    effectPipeline.insert(afterNode,effectData);


% Increase the energy within the areas selected by 'mask'.
function outResultData = applySubtractSpectralEnergy(inResultData,...
    effectData)

    mask = effectData{2};
    stftF = effectData{3};
    stftW = effectData{4};
    stftH = effectData{5};

    outResultData = inResultData;
    
    y = outResultData{1};
    fs = outResultData{2};
    
    import thirdparty.stft
    import thirdparty.istft
    theStft = stft(y, stftF, stftW, stftH, fs);
    
    a = 0.5;
    b = 1;
    randomMask = mask .* ((b-a) .* rand(size(mask)) + a);
    scalingFactor = 10 * (stftF/stftH);
    subtractMask = randomMask .* (scalingFactor*(1 + 1i));
    newStft = theStft - subtractMask;

    y = istft(newStft, stftF, stftW, stftH);
    
    outResultData{1} = y.';
