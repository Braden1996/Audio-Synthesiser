% Functionality to group GUI components by some tag and perform operations.
classdef StateSwitch < handle
    properties (SetAccess = private)
        ComponentMap;
        InverseComponentMap;
        StateMap;
    end
    properties
        OnCallback = 'Enable';
        OffCallback = 'Enable';
        DefaultState = 'off'
    end
    methods (Access = private)
        function callbackEnable(~, components, tag, isOn, isInverse)
            if isOn
                oldState = 'off'; newState = 'on';
            else
                oldState = 'on'; newState = 'off';
            end
            
            maskFcn = @(x) isa(x, 'matlab.ui.container.Panel');
            mask = arrayfun(maskFcn, components);
            panels = components(mask);
            panelChildren = findall(panels, '-property', 'enable');

            allPanels = union(findall(panels, 'Type', 'uipanel'),...
                findall(panels, 'Type', 'uibuttongroup'));
            if isOn
                set(allPanels, 'foregroundcolor', [0, 0, 0]);
            else
                set(allPanels, 'foregroundcolor', [0.655, 0.655, 0.655]);
            end

            allComponents = union(components, panelChildren);

            maskFcn = @(x) isprop(x, 'enable') &&...
                strcmpi(get(x, 'enable'), oldState);
            mask = arrayfun(maskFcn, allComponents);
            enabled = allComponents(mask);
            
            if ~isempty(enabled)
                set(enabled, 'enable', newState);
            end
        end
    end
    methods
        function obj = StateSwitch()
            % MATLAB was acting strange when these were declared within
            % properties.
            obj.ComponentMap = containers.Map();
            obj.InverseComponentMap = containers.Map();
            obj.StateMap = containers.Map();
        end

        % Add a component to the given tag.
        function add(obj, component, tag, varargin)
            i_p = inputParser;
            i_p.FunctionName = 'StateSwitch';
            i_p.addRequired('Component', @ishandle);
            i_p.addRequired('Tag', @ischar);
            i_p.addOptional('Inverse', false, @islogical);
            i_p.parse(component, tag, varargin{:});
            
            inverse = i_p.Results.Inverse;

            if ~obj.ComponentMap.isKey(tag)
                obj.ComponentMap(tag) = [];
                obj.InverseComponentMap(tag) = [];
                obj.StateMap(tag) = obj.DefaultState;
            end
            
            if inverse
                obj.InverseComponentMap(tag) = [obj.InverseComponentMap(tag), component];
            else
                obj.ComponentMap(tag) = [obj.ComponentMap(tag), component];
            end
        end
        
        % Switch on the components of the given tag.
        function on(obj, tag)
            if obj.ComponentMap.isKey(tag)
                obj.StateMap(tag) = true;
                if strcmpi(obj.OnCallback, 'Enable')
                    components = obj.ComponentMap(tag);
                    inverseComponents = obj.InverseComponentMap(tag);
                    obj.callbackEnable(components,tag,true,false);
                    obj.callbackEnable(inverseComponents,tag,false,true);
                elseif isa(obj.OnCallback, 'function_handle')
                    components = obj.ComponentMap(tag);
                    inverseComponents = obj.InverseComponentMap(tag);
                    obj.OnCallback(components,tag,true,false);
                    obj.OnCallback(inverseComponents,tag,false,true);
                end
            end
        end
        
        % Switch off the components of the given tag.
        function off(obj, tag)
            if obj.ComponentMap.isKey(tag)
                obj.StateMap(tag) = false;
                if strcmpi(obj.OffCallback, 'Enable')
                    components = obj.ComponentMap(tag);
                    inverseComponents = obj.InverseComponentMap(tag);
                    obj.callbackEnable(components, tag, false, false);
                    obj.callbackEnable(inverseComponents, tag, true, true);
                elseif isa(obj.OffCallback, 'function_handle')
                    components = obj.ComponentMap(tag);
                    inverseComponents = obj.InverseComponentMap(tag);
                    obj.OffCallback(components, tag, false, false);
                    obj.OffCallback(inverseComponents, tag, true, true);
                end
            end
        end
        
        % Return the state for the given tag
        function state = getState(obj, tag)
            state = NaN;
            if obj.StateMap.isKey(tag)
                state = obj.StateMap(tag);
            end
        end
    end
end