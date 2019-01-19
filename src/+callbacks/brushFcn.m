% All the callbacks for our brush
function found = brushFcn(hObject, eventdata, handles, id)
    found = true;

    theSpectrogram = getappdata(groot, 'Spectrogram');

    switch id
        case 'sliderBrushSize'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Radius = get(hObject, 'Value');
        case 'sliderBrushOpacity'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Opacity = get(hObject, 'Value');
        case 'sliderBrushBlur'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.BlurStrength = get(hObject, 'Value');
        case 'radioBrushModeCreate'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Callback = @theSpectrogram.addMask;
        case 'radioBrushModeErase'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Callback = @theSpectrogram.subtractMask;
        case 'radioBrushShapeCircle'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Shape = 'circle';
        case 'radioBrushShapeSquare'
            theMaskBrush = theSpectrogram.TheMaskBrush;
            theMaskBrush.Shape = 'square';
        otherwise
            found = false;
    end
