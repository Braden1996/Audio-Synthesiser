% Quick little function to plot, or update, our audio.
% Either varargin 'audioAxes' or 'audioPlot' must be given!
function audioPlot = plotAudio(y, fs, varargin)
    i_p = inputParser;
    i_p.FunctionName = 'plotAudio';
    validationFcn = @(x) isa(x, 'matlab.graphics.axis.Axes') && isvalid(x);
    i_p.addOptional('audioAxes', [], validationFcn);
    validationFcn2 = @(x) isa(x, 'matlab.graphics.chart.primitive.Line') && isvalid(x);
    i_p.addOptional('audioPlot', [], validationFcn2);
    i_p.parse(varargin{:});

    audioAxes = i_p.Results.audioAxes;
    audioPlot = i_p.Results.audioPlot;
    if isempty(audioPlot)
        t = (1:length(y)) ./ fs;
        audioPlot = plot(audioAxes, t, y, 'Color', 'r');
        audioPlot.PickableParts = 'none';
        audioPlot.Visible = 'off';
    else
        audioPlot.XData = (1:length(y)) ./ fs;
        audioPlot.YData = y;
        audioPlot.Visible = 'on';
    end