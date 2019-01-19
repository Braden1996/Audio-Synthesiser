% Attach mouse events to given hObject that build a mask based upon
% the coordinates of said mouse.
classdef (Abstract) AbstractMouse < handle
    properties (Access = protected)
        WindowButtonDownID;
        WindowButtonMotionID;
        WindowButtonUpID;
    end
    properties
        Object; % A hObject
        Fig;
    end
    methods (Access = protected)
        function objectP = PointInObject(obj, figP)
            axp = obj.Object.Position;
            
            if strcmpi(obj.Object.Units, 'normalized')
                axp(1) = axp(1) * obj.Fig.Position(3);
                axp(2) = axp(2) * obj.Fig.Position(4);
                axp(3) = axp(3) * obj.Fig.Position(3);
                axp(4) = axp(4) * obj.Fig.Position(4);
            end

            tf1 = axp(1) <= figP(1) && figP(1) <= axp(1) + axp(3);
            tf2 = axp(2) <= figP(2) && figP(2) <= axp(2) + axp(4);

            if tf1 && tf2
                axesPoint = get(obj.Object, 'CurrentPoint');
                objectP = [axesPoint(1), axesPoint(1,2)];
            else
                objectP = [NaN, NaN];
            end
        end

        function WindowButtonDownFcn(obj, ~, ~, ~)
            p = obj.PointInObject(get(obj.Fig,'CurrentPoint'));

            if ~isnan(p)
                obj.onButtonDown(p);
                obj.WindowButtonMotionID = iptaddcallback(obj.Fig,...
                    'WindowButtonMotionFcn', @obj.WindowButtonMotionFcn);
                obj.WindowButtonUpID = iptaddcallback(obj.Fig,...
                    'WindowButtonUpFcn', @obj.WindowButtonUpFcn);
            end
        end

        function WindowButtonMotionFcn(obj, ~, ~, ~)
            p = obj.PointInObject(get(obj.Fig, 'CurrentPoint'));
            if ~isnan(p)
                obj.onButtonMotion(p);
            end
        end

        function WindowButtonUpFcn(obj, ~, ~, ~)
            iptremovecallback(obj.Fig, 'WindowButtonMotionFcn',...
                obj.WindowButtonMotionID);
            iptremovecallback(obj.Fig, 'WindowButtonUpFcn',...
                obj.WindowButtonUpID);
            p = obj.PointInObject(get(obj.Fig, 'CurrentPoint'));
            if ~isnan(p)
                obj.onButtonUp(p);
            end
        end
    end
    methods (Access = protected, Abstract)
        onButtonDown(obj, point)
        onButtonMotion(obj, point)
        onButtonUp(obj, point)
    end
    methods (Static)
        function fig = getParentFigure(fig)
            while ~isempty(fig) && ~strcmp('figure', get(fig,'type'))
                fig = get(fig,'parent');
            end
        end
    end
    methods
        function obj = AbstractMouse(hObject)
            obj.Object = hObject;
            obj.Fig = obj.getParentFigure(hObject);
            
            obj.WindowButtonDownID = iptaddcallback(obj.Fig,...
                'WindowButtonDownFcn', @obj.WindowButtonDownFcn);
        end
         
    end
end