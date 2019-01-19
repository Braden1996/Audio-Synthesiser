classdef PipelineEventData < event.EventData
    properties
        Node
        NodeDepth
    end
    methods
        function obj = PipelineEventData(node, nodeDepth)
            obj.Node = node;
            obj.NodeDepth = nodeDepth;
        end
    end
 end