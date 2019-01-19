% All the callbacks for our toolbar.
function found = listenersFcn(hObject, eventdata, handles, id)
    found = true;
    if isa(hObject, 'userinterface.audioplayer.AudioPlayerControl')
        switch id
            case 'LoopSelectionChange'
                LoopSelectionChange_Callback(hObject, eventdata, handles);
            otherwise
                found = false;
        end
    else  
        found = false;
    end
    
function LoopSelectionChange_Callback(hObject, eventdata, handles)
    setappdata(groot, 'adsrLastOvershoot', []);
    setappdata(groot, 'adsrLastADSR', []);