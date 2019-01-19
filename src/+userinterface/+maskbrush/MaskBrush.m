% Attach mouse events to given hObject that build a mask based upon
% the coordinates of said mouse.
classdef MaskBrush < userinterface.general.AbstractMouse
    properties (SetAccess = private)
        BrushMask;
        DragMask;
    end
    properties
        Image;
        Callback;
        DragCallback;
        Radius = 64;
        Shape = 'circle';  % Other Options: 'square';
        Opacity = 100;
        BlurStrength = 0; % Sigma
    end
    methods (Access = private)
        function rebuildBrushMask(obj)
            ncols = 2*obj.Radius;
            nrows = ncols;

            % Should I scale these shape to account for the aspect ratio
            % of the plot?
            %nRatio = ncols / nrows;
            %d = daspect(obj.hObject);
            %scaledRadius = obj.radius;
            if strcmpi(obj.Shape, 'circle')
                px = floor(ncols / 2);
                py = floor(nrows / 2);
                A = ((1:ncols) - px).^2;
                B = (transpose(1:nrows) - py).^2;
                obj.BrushMask = bsxfun(@plus, A, B) <= obj.Radius^2;
            elseif strcmpi(obj.Shape, 'square')
                obj.BrushMask = ones(nrows,ncols);
            else
                obj.BrushMask = [];
            end
            
            if ~isempty(obj.BrushMask)
                %aspectRatio = obj.hObject.DataAspectRatio(1);
                w = obj.Radius;%*aspectRatio;
                h = obj.Radius;
                obj.BrushMask = imresize(obj.BrushMask, [w h], 'nearest');
            end
        end
    end
    methods (Access = protected)
        function WindowButtonUpFcn(obj, ~, ~, ~)
            WindowButtonUpFcn@userinterface.general.AbstractMouse(obj);
            if isa(obj.Callback, 'function_handle')
                theMask = obj.DragMask.getData();
                if obj.BlurStrength > 0
                    theMask = imgaussfilt(theMask, obj.BlurStrength);
                end
                maskComponent = theMask .* (obj.Opacity/100);
                obj.Callback(maskComponent);
            end
            obj.DragMask.clear();
        end
        
        function WindowButtonDownFcn(obj, ~, ~, ~)
            if isa(obj.Image, 'matlab.graphics.primitive.Image')
                if isempty(obj.BrushMask)
                    obj.rebuildBrushMask();
                end
                WindowButtonDownFcn@...
                    userinterface.general.AbstractMouse(obj);
            end
        end
        
        function onButtonDown(obj, p)
            obj.onButtonMotion(p);
        end
        
        function onButtonMotion(obj, p)
            [nrows,ncols] = size(get(obj.Image,'CData'));
            [mrows, mcols] = size(obj.DragMask.getData());
            if nrows ~= mrows || ncols ~= mcols
                obj.DragMask.reset(nrows,ncols);
            end
            
            [brushW,brushH] = size(obj.BrushMask);

            % Convert from axis coords to pixel values for CData.
            xdata = get(obj.Image,'XData');
            ydata = get(obj.Image,'YData');
            py = round(axes2pix(ncols,xdata,p(1))) - brushH/2;
            px = round(axes2pix(nrows,ydata,p(2))) - brushW/2;

            obj.DragMask.add(obj.BrushMask, [px,py]);
            
            if isa(obj.DragCallback, 'function_handle')
                obj.DragCallback(obj.DragMask.getData());
            end
        end
        
        function onButtonUp(~, ~); end
    end
    methods
        function obj = MaskBrush(im, axes, callback, dragCallback)
            obj@userinterface.general.AbstractMouse(axes);
            obj.Image = im;
            obj.Callback = callback;
            obj.DragCallback = dragCallback;
            
            import userinterface.maskbrush.Mask
            obj.DragMask = Mask(32,32);
        end
        
        function set.Radius(obj, value) 
            obj.Radius = floor(value);
            obj.rebuildBrushMask();
        end
        
        function set.Shape(obj, value) 
            obj.Shape = value;
            obj.rebuildBrushMask();
        end
    end
end