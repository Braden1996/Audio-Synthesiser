% An object for holding the data describing an operation in the Pipeline.
classdef PipelineData < handle
    properties
        Result % Cache the last result from applying this operation.
        ApplyFcn % Function which applies this operation on some input.
        ApplyData % Arbitrary data required for the apply function.
    end
    methods
        function obj = PipelineData(varargin)
            i_p = inputParser;
            i_p.FunctionName = 'play';
            validationFcn = @(x) isa(x,'function_handle');
            i_p.addOptional('ApplyFcn', @(x,d) x, validationFcn);
            i_p.addOptional('ApplyData', {}, @iscell);
            i_p.parse(varargin{:});

            obj.ApplyFcn = i_p.Results.ApplyFcn;
            obj.ApplyData = i_p.Results.ApplyData;
        end
    end
end