% A pipeline with various operations.
% Internally, this uses a linked list as our storage data structure.
classdef Pipeline < handle
    properties (GetAccess = private, SetAccess = private)
        IgnoreApply = false; % Internally ignore apply
    end
    properties (GetAccess = public, SetAccess = private)
        RootNode % The head node
        TailNode % The tail node
    end
    properties (Dependent)
       NodeCount 
    end
    events
        Insert
        Remove
        PostApply
    end
    methods (Access = protected)
        % Reapply the pipeline from just after the given node.
        function apply(obj, node)
            if ~obj.IgnoreApply
                % Find the node we must actually start from (as its
                % possible the prior nodes in the pipeline haven't yet
                % been executed.
                prev = node.Prev;
                while ~isempty(prev) && isempty(node.Data.Result)
                   node = prev;
                   prev = node.Prev;
                end

                % This is the case when the root node hasn't been applied
                if isempty(node.Data.Result)
                    node.Data.Result = ...
                        node.Data.ApplyFcn({}, node.Data.ApplyData);
                end

                next = node.Next;
                while ~isempty(next)
                    nd = node.Data;
                    next.Data.Result = ...
                        next.Data.ApplyFcn(nd.Result, next.Data.ApplyData);
                    node = next;
                    next = node.Next;
                end

                import lib.pipeline.PipelineEventData
                eventdata = PipelineEventData(node,obj.getNodeDepth(node));
                notify(obj, 'PostApply', eventdata);
            end
        end
    end
    methods
        function obj = Pipeline()
            import thirdparty.dlnode
            obj.RootNode = dlnode.empty;
            obj.TailNode = dlnode.empty;
        end
        
        % Return the node that is a given depth within the linked list.
        function node = getNodeAtDepth(obj, depth)
            curDepth = 1;
            node = obj.RootNode;
            next = node;
            while ~isempty(next)
                if curDepth == depth
                    node = next;
                end
                next = next.Next;
                curDepth = curDepth + 1;
            end
        end
        
        % Return the node that is a given depth within the linked list.
        function c = getNodeDepth(obj, node)
            curDepth = 1;
            next = obj.RootNode;
            while ~isempty(next)
                if node == next
                    c = curDepth;
                end
                next = next.Next;
                curDepth = curDepth + 1;
            end
        end

        % Insert a new node into the pipeline.
        function insert(obj, atNode, d)
            import thirdparty.dlnode
            newNode = dlnode(d);
            
            if isempty(obj.RootNode)
                obj.RootNode = newNode;
            else
                newNode.insertAfter(atNode);
            end
            
            if isempty(obj.TailNode) || obj.TailNode == atNode
                obj.TailNode = newNode;
            end
            
            if newNode == obj.RootNode
                obj.apply(newNode);
            else
                obj.apply(newNode.Prev);
            end
            
            import lib.pipeline.PipelineEventData
            nodeDepth = obj.getNodeDepth(newNode);
            eventdata = PipelineEventData(newNode, nodeDepth);
            notify(obj, 'Insert', eventdata);
        end
        
        % Insert the given data into a new node.
        function remove(obj, node)
            import lib.pipeline.PipelineEventData
            eventdata = PipelineEventData(node, obj.getNodeDepth(node));
            
            if node == obj.RootNode
                import thirdparty.dlnode
                notify(obj, 'Remove', eventdata);
            	obj.RootNode = dlnode.empty;
                if node == obj.TailNode
                    obj.TailNode = dlnode.empty;
                end
            else
                applyNode = node.Prev();
            	node.removeNode();
                if node == obj.TailNode
                    obj.TailNode = applyNode;
                end
                
                notify(obj, 'Remove', eventdata);
                obj.apply(applyNode);
            end
        end
        
        % Move the given node up in the pipeline.
        function moveUp(obj, node)
            prev = node.Prev;

            if node == obj.RootNode || prev == obj.RootNode
                error('Root node cannot move position!');
            else
                prev.removeNode();
                prev.insertAfter(node)
                
                if node == obj.TailNode
                    obj.TailNode = prev;
                end
                
                obj.apply(node.Prev);
            end
        end
            
        % Move the given node down in the pipeline.
        function moveDown(obj, node)
            if node == obj.TailNode
                error('Node cannot move any further down!');
            else
                obj.moveUp(node.Next);
            end
        end
        
        % Clear everything - back to initial state.
        function clear(obj)
            obj.IgnoreApply = true;
            prev = obj.TailNode;
            while ~isempty(prev)
                obj.remove(prev);
                prev = obj.TailNode;
            end
            obj.IgnoreApply = false;
            
            import thirdparty.dlnode
            obj.RootNode = dlnode.empty;
            obj.TailNode = dlnode.empty;
        end
        
        % Return the total amount of nodes in the pipeline.
        function c = get.NodeCount(obj)
            c = 0;
            if ~isempty(obj.RootNode)
                next = obj.RootNode;
                while ~isempty(next)
                    node = next;
                    next = node.Next;
                    c = c + 1;
                end
            end
        end
    end
end