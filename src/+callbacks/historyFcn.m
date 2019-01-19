% All the callbacks for our history (pipeline)
function found = historyFcn(hObject, eventdata, handles, id)
    found = true;

    if isa(hObject, 'lib.pipeline.Pipeline')
        switch id
            case 'Insert'
                PipelineInsert_Callback(hObject, eventdata, handles);
            case 'Remove'
                PipelineRemove_Callback(hObject, eventdata, handles);
            case 'PostApply'
                % Nothing to do...
            otherwise
                found = false;
        end
    else
        switch id
            case 'listboxHistory'
                listboxHistory_UpdateState(handles.listboxHistory);
            case 'buttonMoveUpEffect'
                effectPipeline = getappdata(groot, 'EffectPipeline');
                selectedNo = handles.listboxHistory.Value;
                effectNode = effectPipeline.getNodeAtDepth(selectedNo);
                effectPipeline.moveUp(effectNode);
                
                selected = handles.listboxHistory.Value;
                handles.listboxHistory.Value = selected - 1;
                
                nameSwap = handles.listboxHistory.String{selected};
                handles.listboxHistory.String{selected} =...
                    handles.listboxHistory.String{selected - 1};
                handles.listboxHistory.String{selected - 1} = nameSwap;
            
                listboxHistory_UpdateState(handles.listboxHistory);
            case 'buttonMoveDownEffect'
                effectPipeline = getappdata(groot, 'EffectPipeline');
                selectedNo = handles.listboxHistory.Value;
                effectNode = effectPipeline.getNodeAtDepth(selectedNo);
                effectPipeline.moveDown(effectNode);
                
                selected = handles.listboxHistory.Value;
                handles.listboxHistory.Value = selected + 1;
                
                nameSwap = handles.listboxHistory.String{selected};
                handles.listboxHistory.String{selected} =...
                    handles.listboxHistory.String{selected + 1};
                handles.listboxHistory.String{selected + 1} = nameSwap;
                
                listboxHistory_UpdateState(handles.listboxHistory);
            case 'buttonUndoEffect'
                effectPipeline = getappdata(groot, 'EffectPipeline');
                selectedNo = handles.listboxHistory.Value;
                effectNode = effectPipeline.getNodeAtDepth(selectedNo);
                effectPipeline.remove(effectNode);
            otherwise
                found = false;
        end
    end
    
    
function PipelineInsert_Callback(hObject, eventdata, handles)
    effectData = eventdata.Node.Data;
    d = eventdata.NodeDepth;
    
    % All effects first element in applyData is a name!
    name = effectData.ApplyData{1};
    
    % Add new listbox entry.
    historyListbox = handles.listboxHistory;
    if isempty(historyListbox.String)
        historyListbox.String = name;
    elseif ~iscell(historyListbox.String)
        historyListbox.String = {historyListbox.String};
        historyListbox.String{d} = name;
    else
        if length(historyListbox.String) >= d
            before = historyListbox.String(1:d-1);
            after = historyListbox.String(d:end);
            historyListbox.String = [before(:); name; after(:)];
        else
            historyListbox.String{d} = name;
        end
    end

    historyListbox.Value = d;
    
    listboxHistory_UpdateState(handles.listboxHistory);


function PipelineRemove_Callback(hObject, eventdata, handles)
    historyListbox = handles.listboxHistory;
    
    if iscell(historyListbox.String)
        historyListbox.String(eventdata.NodeDepth) = [];
        
        listboxHistory_UpdateState(handles.listboxHistory);
    else
        historyListbox.String = {};
    end
    historyListbox.Value = eventdata.NodeDepth-1;
    listboxHistory_UpdateState(handles.listboxHistory);
  

function updateAudio(y, fs)
    theSpectrogram = getappdata(groot, 'Spectrogram');
    stft = theSpectrogram.calcStft(y, fs);
    theSpectrogram.setStft(stft, fs);

    import userinterface.plotAudio
    audioPlot = getappdata(groot, 'AudioPlot');
    plotAudio(y, fs, 'audioPlot', audioPlot);

    theAudioPlayerControl = getappdata(groot, 'AudioPlayerControl');
    theAudioPlayerControl.set(y, fs);

    theKeyboard = getappdata(groot, 'Keyboard');
    theKeyboard.Y = y;
    theKeyboard.Fs = fs;


function listboxHistory_UpdateState(listboxHistory)
    selectedNo = listboxHistory.Value;
    theStateSwitch = getappdata(groot, 'StateSwitch');
    if selectedNo == 1
        theStateSwitch.on('historyselect1');
    else
        theStateSwitch.off('historyselect1');
        if selectedNo == 2
            theStateSwitch.on('historyselect2');
        else
            theStateSwitch.off('historyselect2');
        end
            
        % Will always be a cell, as selectedNo ~= 1
        last = length(listboxHistory.String);
        if selectedNo == last
            theStateSwitch.on('historyselectlast');
        else
            theStateSwitch.off('historyselectlast');
        end
    end
    
    effectPipeline = getappdata(groot, 'EffectPipeline');
    
    node = effectPipeline.getNodeAtDepth(selectedNo);
    if ~isempty(node)
        effectData = node.Data.ApplyData;
        name = effectData{1}; % Equal to this listboxHistory String

        theSpectrogram = getappdata(groot, 'Spectrogram');
        switch name
            case 'Spectrogram Mask'
                theSpectrogram.StftF = effectData{3};
                theSpectrogram.StftW = effectData{4};
                theSpectrogram.StftH = effectData{5};
                theSpectrogram.SavedMask = effectData{2};
            case 'Add Spectral Energy'
                theSpectrogram.StftF = effectData{3};
                theSpectrogram.StftW = effectData{4};
                theSpectrogram.StftH = effectData{5};
                theSpectrogram.SavedMask = effectData{2};
            case 'Subtract Spectral Energy'
                theSpectrogram.StftF = effectData{3};
                theSpectrogram.StftW = effectData{4};
                theSpectrogram.StftH = effectData{5};
                theSpectrogram.SavedMask = effectData{2};
            case 'ADSR'
                setappdata(groot,'adsrLastADSR',effectData{2});
                setappdata(groot,'adsrLastOvershoot',effectData{3});
                theSpectrogram.SavedMask = [];
            case 'Wah-Wah'
                setappdata(groot,'wahwahLastDamp',effectData{2});
                setappdata(groot,'wahwahLastMinF',effectData{3});
                setappdata(groot,'wahwahLastMaxF',effectData{4});
                setappdata(groot,'wahwahLastWahF',effectData{5});
                theSpectrogram.SavedMask = [];
            case 'Flanger'
                setappdata(groot,'flangerLastMaxTimeDelay',effectData{2});
                setappdata(groot,'flangerLastRate',effectData{3});
                theSpectrogram.SavedMask = [];
            otherwise
                theSpectrogram.SavedMask = [];
        end
        
        y = node.Data.Result{1};
        fs = node.Data.Result{2};
        updateAudio(y, fs);
    end
    