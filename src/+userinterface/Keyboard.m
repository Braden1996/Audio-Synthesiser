% A short class to manage everything after the keypress for a keyboard.
classdef Keyboard < handle
    properties (GetAccess = private)
        CurrentPlayers = []; % Audioplayers that are currently playing.
    end
    properties
        Y;
        Fs;
        HeaderAxes = [];
    end
    methods
        function obj = Keyboard(axes)
            obj.HeaderAxes = axes;
        end
        
        % Clear up and delete all players
        function delete(obj)
            delete(obj.CurrentPlayers);
            obj.CurrentPlayers = [];
        end
        
        % Delete the player at the given index.
        function deletePlayer(obj, ap)
            delete(ap);
            obj.CurrentPlayers(obj.CurrentPlayers == ap) = [];
        end
        
        % Play the meantone interval at the given ratio.
        function play(obj, numerator, denominator, varargin)
            i_p = inputParser;
            i_p.FunctionName = 'play';
            i_p.addOptional('Start', [], @isnumeric);
            i_p.addOptional('End', [], @isnumeric);
            i_p.parse(varargin{:});

            startSample = i_p.Results.Start;
            endSample = i_p.Results.End;
            
            playY = obj.Y;
    
            % Ratio is fliiped
            import thirdparty.pvoc
            ratio = numerator / denominator;
            ypvoc = pvoc(playY, ratio); 
            playY = resample(ypvoc, numerator, denominator);
            
            import userinterface.audioplayer.AudioPlayer
            tempAudioPlayer = AudioPlayer(obj.HeaderAxes);
            tempAudioPlayer.set(playY, obj.Fs);
            tempAudioPlayer.LoopStartSample = startSample;
            tempAudioPlayer.LoopEndSample = endSample;
            
            obj.CurrentPlayers = [obj.CurrentPlayers, tempAudioPlayer];

            tempAudioPlayer.PauseFcn = @(ap,~,~) obj.deletePlayer(ap);
            tempAudioPlayer.play();
        end
    end
end