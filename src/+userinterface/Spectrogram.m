% A controller that attaches to an axes, enabling the functionality to
% display a given spectrogram and a mask which sits ontop of the image.
classdef Spectrogram < handle
    properties (SetAccess = private)
        Cbar; % Colorbar for our axes.
        TheMaskBrush; % Handles mouse events to build up our mask.

        % The mask which the next operation is to be applied on.
        MaskImage;

        % The mask for the current brush stroke, i.e. to be added to
        % 'mask'.
        DragMaskImage;
        
        % The previously drawn mask.
        SavedMaskImage;

        Stft; % Short-Time Fourier Transform.
        StftFs; % Corresponding sample-rate.
        LastIstft;
    end
    properties (SetAccess = private, SetObservable, AbortSet)
        Axes; % Attached axes.

        Mask = [];
        DragMask = [];
    end
    properties
        % A callback for when the value of 'mask' has changed.
        MaskChangeFcn;

        % STFT parameters.
        StftF = 512;
        StftW = 512;
        StftH = 512/4;
        
        % An alternative mask to display
        SavedMask = [];
    end
    properties (SetObservable, AbortSet)
        % Display colors for our various masks.
        MaskColor = [1,0,0,0.8];
        DragMaskColor = [1,0,1,0.4];
        SavedMaskColor = [0,0,1,0.8];
    end
    properties (Dependent)
        Istft
    end
    methods (Static)
        % Handle events from our listeners.
        function handlePropEvents(src, evnt)
            obj = evnt.AffectedObject;
            switch src.Name 
                case 'Axes'
                    cla(obj.Axes);
                    obj.setupAxes(obj.Axes);
                    % Create a maskBrush instance for the atached axes.
                    import userinterface.maskbrush.MaskBrush
                    obj.TheMaskBrush = MaskBrush(NaN, obj.Axes,...
                        @obj.addMask, @obj.addDragMask);
                case 'Mask'
                    if isa(obj.MaskChangeFcn, 'function_handle')
                        obj.MaskChangeFcn(obj.Mask);
                    end
            end
        end
        
        % Setup some default properties for our attached axes.
        function setupAxes(axes)
            axis(axes, 'xy');
            grid(axes, 'on');
            grid(axes, 'minor');
            xlabel(axes, 'Time / sec');
            ylabel(axes, 'Frequency / Hz')
            %title(axes, 'Audio Spectrogram');
            set(get(axes, 'YAxis'), 'Exponent', 0);
        end
    
        % A mask is simply a two dimensional matrix. As we display a mask
        % using an image, we need a red, green and blue component. This
        % function takes a mask and a color and returns data for an image.
        function maskRgb = getMaskRgb(aMask, aColor)
            maskRgb = cat(3, aMask, aMask, aMask);
            maskRgb(:,:,1) = maskRgb(:,:,1) .* aColor(1);
            maskRgb(:,:,2) = maskRgb(:,:,2) .* aColor(2);
            maskRgb(:,:,3) = maskRgb(:,:,3) .* aColor(3);
        end
        
        % When we change the color of a mask, we must update the 'CData' of
        % our mask's image and also the 'AlphaData' (which hides unselected
        % areas of the mask).
        function refreshMaskColor(mask, maskColor, maskImage)
            maskImage.CData = userinterface.Spectrogram...
                .getMaskRgb(mask, maskColor);
            maskImage.AlphaData = bsxfun(@times, mask, maskColor(4));
        end
    end
    methods (Access = protected)
        % Convenient way to refresh 'savedMask'.
        function refreshSavedMask(obj)
            obj.refreshMaskColor(obj.SavedMask, obj.SavedMaskColor, obj.SavedMaskImage);
        end

        % Convenient way to refresh 'mask'.
        function refreshMask(obj)
            obj.refreshMaskColor(obj.Mask, obj.MaskColor, obj.MaskImage);
        end

        % Convenient way to refresh 'dragMask'.
        function refreshDragMask(obj)
            obj.refreshMaskColor(obj.DragMask, obj.DragMaskColor, obj.DragMaskImage);
        end
    end
    methods (Access = public)
        function obj = Spectrogram(ax, maskChangeCallback)
            % Create property listeners
            addlistener(obj,'Axes','PostSet',@obj.handlePropEvents);
            addlistener(obj,'Mask','PostSet',@obj.handlePropEvents);
            
            obj.Axes = ax;
            obj.MaskChangeFcn = maskChangeCallback;
        end
        
        % Enable the colorbar for our axes.
        function enableColorbar(obj)
            if isempty(obj.Cbar)
                obj.Cbar = colorbar(obj.Axes, 'east');
                obj.Cbar.Label.String = 'Power/frequency (dB/Hz)';
            end
        end
        
        % Disable the colorbar for our axes.
        function disableColorbar(obj)
            if ~isempty(obj.Cbar)
                delete(obj.Cbar);
                obj.Cbar = [];
            end
        end
        
        % Set the alpha level for all our masks simultaneously.
        function setMaskAlpha(obj, alpha)
            obj.MaskColor = [obj.MaskColor(1:3), alpha/100];
            obj.SavedMaskColor = [obj.SavedMaskColor(1:3), alpha/100];
            obj.DragMaskColor = [obj.DragMaskColor(1:3), alpha/200];
            obj.refreshMask();
            obj.refreshSavedMask();
            obj.refreshDragMask();
        end
        
        % Calculate the STFT for the given 'value' signal.
        function theStft = calcStft(obj, value, fs)
            import thirdparty.stft
            theStft = stft(value, obj.StftF, obj.StftW, obj.StftH, fs);
        end
        
        % Set the current STFT that we're working with. Also, update all
        % our drawn images.
        function setStft(obj, value, fs)
            if ~isempty(obj.Stft) && ~isequal(size(obj.Stft), size(value))
                delete(obj.TheMaskBrush.Image);
                delete(obj.SavedMaskImage);
                delete(obj.MaskImage);
                delete(obj.DragMaskImage);

                obj.TheMaskBrush.Image = [];
                obj.SavedMaskImage = [];
                obj.MaskImage = [];
                obj.DragMaskImage = [];
            end

            obj.Stft = value;
            obj.StftFs = fs;

            % Calculate our image data.
            tt = 0:(size(obj.Stft,2)-1) * obj.StftH/obj.StftFs;
            ff = 0:(size(obj.Stft,1)-1) * obj.StftFs/obj.StftF;
            cc = 20*log10(abs(obj.Stft));
            im = obj.TheMaskBrush.Image;

            % Check if we have already drawn an initial image. If so, just
            % update the data.
            if isa(im, 'matlab.graphics.primitive.Image')
                set(im, 'XData', tt, 'YData', ff, 'CData', cc);
            else
                im = imagesc(obj.Axes, tt, ff, cc);
                obj.TheMaskBrush.Image = im;

                % Initiliase our masks.
                obj.SavedMask = zeros(size(im));
                obj.Mask = zeros(size(im));
                obj.DragMask = zeros(size(im));
                
                hold(obj.Axes, 'on');
                    obj.SavedMaskImage = image(obj.Axes, tt, ff, []);
                    obj.MaskImage = image(obj.Axes, tt, ff, []);
                    obj.DragMaskImage = image(obj.Axes, tt, ff, []);

                    maskImages = [obj.SavedMaskImage,obj.MaskImage,...
                        obj.DragMaskImage];
                    for mImage = maskImages
                        mImage.PickableParts = 'none';
                    end
                hold(obj.Axes, 'off');
                
                obj.setupAxes(obj.Axes);
            end

            % Update all our masks.
            obj.SavedMaskImage.XData = tt; obj.SavedMaskImage.YData = ff;
            obj.MaskImage.XData = tt; obj.MaskImage.YData = ff;
            obj.DragMaskImage.XData = tt; obj.DragMaskImage.YData = ff;
        end
        
        % Add the given mask to our object's 'mask'.
        function addMask(obj, maskAddition)
            obj.DragMask = []; % Clear drag mask.
            obj.Mask = obj.Mask + maskAddition;
        end
        
        % Subtract the given mask from our object's 'mask'.
        function subtractMask(obj, maskSubtraction)
            obj.addMask(-maskSubtraction);
        end
        
        % Clear the mask so that nothing is selected.
        function clearMask(obj)
            obj.subtractMask(obj.Mask);
        end
        
        % Invert the mask, i.e. select only the previously unselected
        % areas.
        function inverseMask(obj)
            newMask = 1 - obj.Mask;
            obj.clearMask();
            obj.addMask(newMask);
        end
        
        % Add the given mask to our object's 'dragMask'.
        function addDragMask(obj, maskAddition)
            obj.DragMask = maskAddition;
        end
    end
    methods
        % Refresh the data associated with 'savedMask'.
        function set.SavedMask(obj, value) 
            obj.SavedMask = max(min(value, 1), 0);
            obj.refreshSavedMask();
        end
        function set.SavedMaskColor(obj, value)
            if length(value) ~= 4
                value(4) = obj.SavedMaskColor(4);
            end
            obj.SavedMaskColor = value;
            obj.refreshSavedMask();
        end

        % Refresh the data associated with 'mask'.
        function set.Mask(obj, value) 
            obj.Mask = max(min(value, 1), 0);
            obj.refreshMask();
        end
        function set.MaskColor(obj, value)
            if length(value) ~= 4
                value(4) = obj.MaskColor(4);
            end
            obj.MaskColor = value;
            obj.refreshMask();
        end

        % Refresh the data associated with 'dragMask'.
        function set.DragMask(obj, value) 
            obj.DragMask = max(min(value, 1), 0);
            obj.refreshDragMask();
        end
        function set.DragMaskColor(obj, value)
            if length(value) ~= 4
                value(4) = obj.DragMaskColor(4);
            end
            obj.DragMaskColor = value;
            obj.refreshDragMask();
        end
    end
end