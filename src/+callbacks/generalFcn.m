% Some general purpose callbacks.
function found = generalFcn(hObject, eventdata, handles, id)
    found = true;
    switch id
        case 'sliderCreate'
            slider_CreateFcn(hObject, eventdata, handles);
        otherwise
            found = false;
    end


function slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'),...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    
    
function listbox_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'),...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end