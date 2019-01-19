% Same as uiAudioPlayer except this allows for a control axes, that allows
% the user to manipulate the loop range and current sample VIA mouse
% interaction.
classdef AudioPlayerControl < userinterface.general.AbstractMouse ...
        & userinterface.audioplayer.AudioPlayer
    events
        LoopSet
    end
    properties (SetAccess = protected)
        % The plot which indicate the currently looped range of audio.
        LoopPlot;
        LoopPlotFaceColor = [68, 108, 179, 128] ./ 255; % Fill
        LoopPlotEdgeColor = [34, 49, 63] ./ 255; % Outline
        LoopPlotLineWidth = 1; % Outline width
    end
    methods (Access = protected)
        % When control axes is clicked down.
        function onButtonDown(obj, p)
            if ~isempty(obj.Y)
                obj.LoopStartSample = NaN;
                obj.LoopEndSample = NaN;
                obj.updateLoopSample(p);
            end
        end
        
        % When a loop selection box is being drawn within the control axes.
        function updateLoopSample(obj, p)
            s = min(max(round((p(1) * obj.Fs) + 1),1),obj.TotalSamples);
            if isnan(obj.LoopStartSample)
                obj.LoopStartSample = s;
            else
                obj.LoopEndSample = s;
            end
        end
        
        % When the control axes click has been released. We do this because
        % if the start and end loop samples are the same, i.e. just a
        % click, we disable the loop selection.
        function onButtonUp(obj, p)
            updateLoopSample(obj, p);
            if isplaying(obj.Audioplayer)
                obj.goto(obj.getLoopStartSample());
            else
                obj.stop();
            end
            obj.updateLoopPlot();

            if obj.LoopStartSample == obj.LoopEndSample
                obj.LoopStartSample = NaN;
                obj.LoopEndSample = NaN;
            end
            
            import userinterface.audioplayer.AudioPlayerControlEventData
            eventdata = AudioPlayerControlEventData( ...
                obj.LoopStartSample, obj.LoopEndSample);
            notify(obj, 'LoopSet', eventdata);
        end
        
        % Update our loop selection during mouse click-drag.
        function onButtonMotion(obj, p)
            if ~isempty(obj.Y)
                updateLoopSample(obj, p)
                obj.updateLoopPlot();
            end
        end
        
        % Update our loop selection area rectangle.
        function updateLoopPlot(obj)
            if isnan(obj.LoopStartSample) || isnan(obj.LoopEndSample) ...
                    || obj.LoopStartSample == obj.LoopEndSample
                set(obj.LoopPlot, 'visible', 'off');
            else
                ax = obj.LoopPlot.Parent;
                yLim = ax.YLim;
                y1 = yLim(1); y2 = yLim(2);
                h = y2-y1;

                x = (obj.getLoopStartSample() - 1) / obj.Fs;
                w = ((obj.getLoopEndSample() - 1) / obj.Fs) - x;

                obj.LoopPlot.Visible = 'on';
                obj.LoopPlot.Position = [x, y1, w, h];
            end
        end
    end
    methods
        function obj = AudioPlayerControl(controlAxes, headerAxes)
            obj@userinterface.general.AbstractMouse(controlAxes);
            obj@userinterface.audioplayer.AudioPlayer(headerAxes);
            
            % Just create our loop selection rectangle here.
            hold(controlAxes, 'on');
                obj.LoopPlot = rectangle(controlAxes, 'Position', [0 0 1 1]);
                obj.LoopPlot.Visible = 'off';
                obj.LoopPlot.PickableParts = 'none';
                obj.LoopPlot.LineWidth = obj.LoopPlotLineWidth;
                obj.LoopPlot.FaceColor = obj.LoopPlotFaceColor;
                obj.LoopPlot.EdgeColor = obj.LoopPlotEdgeColor;
            hold(controlAxes, 'off');
        end
    end
end