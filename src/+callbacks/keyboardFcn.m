% All the callbacks for our keyboard.
function found = keyboardFcn(hObject, eventdata, handles, id)
    found = true;
    switch id
        case 'buttonKeyboard'
            octaves = hObject.UserData(1);
            denominator = hObject.UserData(2);
            numerator = hObject.UserData(3);
            
            middle = 4;
            
            if octaves >= middle
                denominator = denominator * (octaves - middle + 1);
            elseif octaves > 0 && octaves <= (middle - 1)
                numerator = numerator * (middle - octaves + 1);
            end
            
            theKeyboard = getappdata(groot, 'Keyboard');
            apc = getappdata(groot, 'AudioPlayerControl');
            theKeyboard.play(denominator, numerator, 'start', ...
                apc.getLoopStartSample(), 'end', apc.getLoopEndSample());
        otherwise
            found = false;
    end