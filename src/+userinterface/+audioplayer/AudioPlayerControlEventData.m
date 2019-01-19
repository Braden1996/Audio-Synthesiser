classdef AudioPlayerControlEventData < event.EventData
    properties
        StartSample
        EndSample
    end
    methods
        function obj = AudioPlayerControlEventData(StartSample, EndSample)
            obj.StartSample = StartSample;
            obj.EndSample = EndSample;
        end
    end
 end