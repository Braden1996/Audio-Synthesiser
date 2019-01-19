% Ronan O'Malley
% October 5th 2005
% Modified by Braden Marshall (27/11/2016)
% Chorus.m
% M Script that creates a single delay  with the delay time ocilating from either 0-3 ms or 0-15 ms at 0.1 - 5 Hz
% this is not synthesisable unless buffering is used
% Possibility for extension:
%   - need to perfect allowable ranges
%   - do calculations with sampling frequency to convert delay in samples into miliseconds (need some 44.1kHz samples)
% Argument: max_time_delay
% Delay in seconds
% Argument: rate
% rate of flange in Hz
function y = flanger(x, Fs, max_time_delay, rate)
    index = 1:length(x);

    % sin reference to create oscillating delay
    sin_ref = (sin(2*pi*index*(rate/Fs)))'; % sin(2pi*fa/fs);

    % Convert delay in ms to max delay in samples
    max_samp_delay=round(max_time_delay*Fs);

    % Create empty out vector
    y = zeros(length(x),1);       

    % To avoid referencing of negative samples
    y(1:max_samp_delay)=x(1:max_samp_delay);

    % Suggested coefficient from page 71 DAFX
    amp=0.7; 

    % For each sample
    for i = (max_samp_delay+1):length(x)
        % Abs of current sin val (0-1)
        cur_sin = abs(sin_ref(i));
        
        % Generate delay from 1-max_samp_delay and ensure whole number
        cur_delay=ceil(cur_sin*max_samp_delay);
        
        % Add delayed sample
        y(i) = (amp*x(i)) + amp*(x(i-cur_delay));
    end