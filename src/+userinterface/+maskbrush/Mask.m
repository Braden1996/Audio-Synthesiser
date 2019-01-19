classdef Mask < handle
    properties (SetAccess = private)
        Data;
    end
    methods ( Access = private )
        % Insert maskComponent correctly into topLeft.
        function [x,y,maskComponent] = getOriginForComponent(obj,...
                maskComponent, topLeft)
            topLeft = floor(topLeft);
            [mcM, mcN] = size(maskComponent);
            x = topLeft(1):topLeft(1)+mcM-1;
            y = topLeft(2):topLeft(2)+mcN-1;
            
            % Force maskComponent to stay within bounds
            if x(1) <= 0
                maskComponent = maskComponent(abs(x(1))+2:end,:);
                x = x(abs(x(1))+2:end);
            end

            if y(1) <= 0
                maskComponent = maskComponent(:, abs(y(1))+2:end);
                y = y(abs(y(1))+2:end);
            end
            
            [dataM, dataN] = size(obj.Data);
            if x(end) > dataM
                maskComponent = maskComponent(1:end-abs(x(end) - dataM),:);
                x = x(1:end-abs(x(end) - dataM));
            end
            
            if y(end) > dataN
                maskComponent = maskComponent(:,1:end-abs(y(end) - dataN));
                y = y(1:end-abs(y(end) - dataN));
            end
        end
    end
    methods
        function obj = Mask(m,n)
            obj.reset(m, n);
        end
        
        % Reset the mask to a mxn grid of zeros.
        function reset(obj, m,n)
            obj.Data = zeros(m, n);
        end

        % Add a new component to the mask. topLeft indicates where,
        % within obj.data, the maskComponent should start.
        function add(obj, maskComponent, topLeft)
            [x,y,maskComponent] = ...
                obj.getOriginForComponent(maskComponent,topLeft);
            currentComponent = obj.Data(x,y);
            obj.Data(x,y) = max(min(currentComponent+maskComponent,1),0);
        end
        
        % Subtract a component from the mask. topLeft indicates where,
        % within obj.data, the maskComponent should start.
        function subtract(obj, maskComponent, topLeft)
            obj.add(-maskComponent, topLeft);
        end
        
        % Reset the current mask back to all zeros.
        function clear(obj)
           obj.Data = zeros(size(obj.Data)); 
        end
        
        % Return logical true if the mask is empty (all zeros).
        function empty = isEmpty(obj)
            empty = nnz(obj.Data) == 0;
        end
        
        % Return the mask matrix.
        function outMask = getData(obj)
            outMask = obj.Data;
        end
    end
end