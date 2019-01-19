% Ties together an audioplayer with an axes, i.e. plot a line which
% indicates the audioplayer's CurrentSample.
classdef AudioPlayer < handle
    properties (Dependent)
        CurrentSample;
        TotalSamples;
        Duration;

        LoopY;
        LoopDuration;
    end
    properties (GetAccess = protected, SetAccess = protected)
       ForceStop = false;
       IgnoreGoto = false;
    end
    properties (SetAccess = protected)
        Audioplayer; % Matlab's 'audioplayer' object
        
        HeaderAxes = []; % Axes where we wish to display a playhead.
        HeaderPlots = []; % Playhead's line object.
        
        Y;
        Fs;
        FrameT = 1/32;  % Framerate
    end
    properties
        PlayFcn;
        PauseFcn;
        
        LoopAudio = false;
        
        % Repeatedly play a given range of audio.
        LoopStartSample = NaN;
        LoopEndSample = NaN;
    end
    methods (Access = protected)
        % Called by our Audioplayer whilst playing. Called every 'frameT'
        % second.
        function TimerFcn(obj, ~, ~)
            sample = obj.CurrentSample;

            % If we've played more than we need to, stop playback.
            % Don't worry, our StopFcn takes care of looping.
            if sample > obj.getLoopEndSample()
                stop(obj.Audioplayer);
            else
                obj.updateHeaderPlots();
            end
        end
        
        % Called by our Audioplayer when playback stops.
        % We use this to detect when the Audioplayer has actually finished
        % playing the sound, so we can optionally loop.
        function StopFcn(obj, ~, ~)
            if obj.IgnoreGoto
                obj.IgnoreGoto = false;
            else
                sample = obj.getLoopStartSample();

                if obj.LoopAudio
                    % The case when Audioplayer's playback has reached the
                    % end of our signal.
                    if sample == obj.CurrentSample 
                        obj.goto(sample);
                    end

                    if obj.ForceStop
                        obj.ForceStop = false;
                    else
                        obj.play();
                    end
                else
                    obj.stop();
                end
            end
        end
        
        % Update the position for each playhead.
        function updateHeaderPlots(obj)
            lineClass = 'matlab.graphics.chart.primitive.Line';
            for aHeaderPlot = obj.HeaderPlots
                if isvalid(aHeaderPlot) && isa(aHeaderPlot, lineClass)
                    currentT = obj.CurrentSample / obj.Fs;
                    aHeaderPlot.XData = [currentT currentT];
                    ax = get(aHeaderPlot, 'parent');
                    aHeaderPlot.YData = ax.YLim;
                end
            end
        end
    end
    methods (Static)
        % Create a new playhead for the given axes.
        function headerPlot = createHeaderPlot(ax)
            hold(ax, 'on');
                headerPlot = plot(ax, [0 1], [0 1], 'Color', '0 0 0');
                headerPlot.PickableParts = 'none';
                % Don't display our headerPlot in the legend
                headerPlot.Annotation.LegendInformation.IconDisplayStyle = 'off';
            hold(ax, 'off');
        end 
    end
    methods
        function obj = AudioPlayer(headerAxes)
            obj.HeaderAxes = headerAxes;
        end
        
        % Clear up after we've been deleted :(
        function delete(obj)
            if ~isempty(obj.Audioplayer) && isplaying(obj.Audioplayer)
                obj.stop();
            end

            for aHeaderPlot = obj.HeaderPlots
                delete(aHeaderPlot);
            end
            obj.HeaderPlots = [];
        end
        
        % Set the current audio.
        function set(obj, y, fs)
            lastSample = NaN;
            wasPlaying = false;
            
            % Delete former playheads
            for ax = obj.HeaderPlots
                delete(ax);
            end
            obj.HeaderPlots = [];

            % Get previous sample if exists
            if ~isempty(obj.Audioplayer)
               lastSample = obj.CurrentSample;
            
                if isplaying(obj.Audioplayer)
                    obj.pause();
                    wasPlaying = true;
                end
            end

            obj.Y = y;
            obj.Fs = fs;

            % Create and setup Audioplayer
            obj.Audioplayer = audioplayer(y, fs);
            obj.Audioplayer.TimerFcn = {@(x, y) obj.TimerFcn(x, y)};
            obj.Audioplayer.StopFcn = {@(x, y) obj.StopFcn(x, y)};
            obj.Audioplayer.TimerPeriod = obj.FrameT;
    
            % Create new playheads
            for ax = obj.HeaderAxes
                newHeaderPlot = obj.createHeaderPlot(ax);
                obj.HeaderPlots = [obj.HeaderPlots, newHeaderPlot];
            end
            
            % Loop if necessary, or just move current sample.
            if ~isnan(lastSample)
                if wasPlaying
                    obj.play(lastSample); 
                elseif lastSample == 1
                    obj.stop();
                else
                    obj.goto(lastSample);
                end
            end
            
            obj.updateHeaderPlots();
        end
        
        % Play our audioplayer at the sample indicated by thevarargin's
        % 'startSample', resuming from last pause, the start sample of the
        % loop or sample 1 (in that order).
        function play(obj, varargin)
            i_p = inputParser;
            i_p.FunctionName = 'play';
            i_p.addOptional('StartSample', [], @isnumeric);
            i_p.parse(varargin{:});
            
            if ~isempty(obj.Audioplayer)
                startSample = i_p.Results.StartSample;
                
                if isempty(startSample)
                    startSample = max(obj.CurrentSample,...
                        obj.getLoopStartSample());
                end
                
                startSample = round(startSample);
                if startSample >= obj.TotalSamples || startSample < 1
                   startSample = 1; 
                end
                
                play(obj.Audioplayer, startSample);

                obj.updateHeaderPlots();

                if isa(obj.PlayFcn, 'function_handle')
                    obj.PlayFcn(obj, startSample, obj.TotalSamples);
                end
            end
        end
        
        % Pause our audio-player.
        function pause(obj)
            if ~isempty(obj.Audioplayer)
                if isplaying(obj.Audioplayer)
                    obj.IgnoreGoto = true;
                end

                pause(obj.Audioplayer);
                obj.updateHeaderPlots();
                if isa(obj.PauseFcn, 'function_handle')
                    obj.PauseFcn(obj, obj.CurrentSample, obj.TotalSamples);
                end
            end
        end
        
        % Stop the audio, going back to the loop start sample, if it
        % exists, otherwise simply sample 1.
        function stop(obj)
            if ~isempty(obj.Audioplayer)
                if isplaying(obj.Audioplayer)
                    obj.ForceStop = true;
                end
                stop(obj.Audioplayer);
                
                startSample = obj.getLoopStartSample();
                if startSample ~= 1
                    obj.goto(startSample);
                end
                
                obj.updateHeaderPlots();
                if isa(obj.PauseFcn, 'function_handle')
                    obj.PauseFcn(obj, obj.CurrentSample, obj.TotalSamples);
                end
            end
        end
        
        % Goto a particular sample in our audio. Maintaining the current
        % playing state.
        function goto(obj, sample)
            if ~isempty(obj.Audioplayer)
                wasPlaying = false;
                if isplaying(obj.Audioplayer)
                    obj.IgnoreGoto = true;
                    pause(obj.Audioplayer);
                    wasPlaying = true;
                end
                
                % Check if out of range
                sample = max(min(sample, obj.getLoopStartSample()), 1);

                % Sadly a few samples are processed between this play
                % and the upcoming pause :(
                obj.play('StartSample', sample);

                if ~wasPlaying
                    obj.IgnoreGoto = true;
                    pause(obj.Audioplayer);
                end
            end
        end
        
        % Return the start sample of our loop range.
        function sample = getLoopStartSample(obj)
            if isnan(obj.LoopStartSample)
                sample = 1;
            else
                sample = min(obj.LoopStartSample, obj.LoopEndSample);
            end
        end
        
        % Return the end sample of our loop range.
        function sample = getLoopEndSample(obj)
            if isnan(obj.LoopStartSample)
                sample = obj.TotalSamples;
            else
                sample = max(obj.LoopStartSample, obj.LoopEndSample);
            end
        end
        
        % Return the audio within the current loop selection.
        function loopY = get.LoopY(obj)
            loopY = obj.Y(obj.getLoopStartSample():obj.getLoopEndSample());
        end
        
        % Return the duration of the current loop selection.
        function dur = get.LoopDuration(obj)
            [m,~] = size(obj.LoopY);
            dur = m / obj.Fs;
        end
        
        % Return the duration of the loaded audio.
        function dur = get.Duration(obj)
            [m,~] = size(obj.Y);
            dur = m / obj.Fs;
        end
        
        function sample = get.CurrentSample(obj)
            sample = obj.Audioplayer.CurrentSample;
        end
        
        function sample = get.TotalSamples(obj)
            sample = obj.Audioplayer.TotalSamples;
        end
    end
end