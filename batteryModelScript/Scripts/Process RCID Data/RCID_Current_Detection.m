%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filename: RCID_Current_Detection.m                                     %
% Author:   Daniel Seals                                                 %
% Updated:  December 20, 2019                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function identifies the current pulses of an RCID test that are
% relevant for ECM analysis

% This function returns indicies needed for the data analysis code to run,
% and it also returns the Start/Stop of the capacity test, if present

function [Pulse_Start_Index,Pulse_Stop_Index,Initial_Pulse_Index,Final_Pulse_Index,...
    Cap_Start,Cap_End] = RCID_Current_Detection(Time,I,deltat,Smallest_Pulse)

Current_Detection_Sens = 0.02; % Volts

% Flag = 0 means that the current is zero and loop is looking for non-zero
% current. Flag = 1 means that there is current flow and loop is
% looking for when the current drops to (nearly) 0
Flag = 0;

for i = 2:length(I)-5
    if abs(I(i)) > Current_Detection_Sens && abs(I(i+1)) > Current_Detection_Sens && Flag == 0        % Look for Start of Pulse
        Index_Array(i) = i-1;
        Flag = 1;
    elseif abs(I(i)) < Current_Detection_Sens && abs(I(i+1)) < Current_Detection_Sens && Flag == 1    % Look for End of Pulse ( I = 0 )
        Index_Array(i) = i-1;
        Flag = 0;
    elseif abs(I(i)) > Current_Detection_Sens && abs(I(i-1)) > Current_Detection_Sens && sign(I(i)) ~= sign(I(i-1)) && i > 1
        % Look for when current switches directly from charging to
        % discharging (Normal for HPPC tests)
        Index_Array(i) = i-1;
        % Flag remains the same because there is still current flow
    end
end
Current_Change_Index = nonzeros(Index_Array);

% Forward-looking difference of Current index
for i = 1:length(Current_Change_Index) - 1
    Time_between_current_change(i) = Time(Current_Change_Index(i+1)) - Time(Current_Change_Index(i));
end


% Checks to make sure current change was preceeded by ~ 10 seconds of
% non-switching current
for i = 2:length(Current_Change_Index)
    if Time_between_current_change(i-1) > 0.2 ...  % Check that pulse lasts longer than 9.5 seconds (Can Be Adjusted!!)
            && abs(I(Current_Change_Index(i)+1) - I(Current_Change_Index(i))) > Current_Detection_Sens
        % Pulse has been found
        Pulse_Array(i) = i;
    end
end
Pulse_Index_All = Current_Change_Index(nonzeros(Pulse_Array));


% Forward-looking difference of Pulse Index
for i = 1:length(Pulse_Index_All) - 1
    Time_between_pulse_all(i) = Time(Pulse_Index_All(i+1)) - Time(Pulse_Index_All(i));
end

for i = 2:length(Pulse_Index_All) - 5
    % If preceded by 30+ min of Non-switching current & current is non-zero
    % & the index is at least 12 current changes away from the end of
    % the index & the next 8+ times between current changes are less than
    % 30 minutes, then an inital pulse in a pulse set has been found
    if Time_between_pulse_all(i-1) > 720 ...
            && abs(I(Pulse_Index_All(i)+1)) > Current_Detection_Sens ...
            && max(Time_between_pulse_all(i:i+4)) < 2000
        % Initial pulse in a set of pulses has been found
        Initial_Pulse_Array(i) = i;
    end
end
Initial_Pulse_Index = Pulse_Index_All(nonzeros(Initial_Pulse_Array));


for i = 1:length(Pulse_Index_All)-1
    % If the next current change has non-zero current for at least 3
    % minutes and that current is discharging (Negative I value) and the
    % time preceeding the curent change is less than 10 minutes, an SOC
    % discharge following a set of pulses has been detected
    if abs(I(Pulse_Index_All(i)+10)) > Current_Detection_Sens && Time_between_pulse_all(i) > 500 ...
            && I(Pulse_Index_All(i)+10) < 0
        if i > 1
            if Time_between_pulse_all(i-1) <= 1600
                Final_Pulse_Array(i) = i;
            end
        else % Remove the preceeding-time check for the first index
            %             Final_Pulse_Array(i) = i;
        end
    end
end
if  I(Pulse_Index_All(end)+10)<0 && abs(I(Pulse_Index_All(end)+10))>Current_Detection_Sens ...
        && 0<(Pulse_Index_All(end)-Initial_Pulse_Index(end))<70000
    Final_Pulse_Array(i) = length(Pulse_Index_All);
end
Final_Pulse_Index = Pulse_Index_All(nonzeros(Final_Pulse_Array));

Pulse_Index = [];
for i = 1:length(Initial_Pulse_Index)
    x = find(Pulse_Index_All >= Initial_Pulse_Index(i));
    y = find(Pulse_Index_All(x) < Final_Pulse_Index(i));
    Pulse_Index = cat(1,Pulse_Index,Pulse_Index_All(x(y)));
end


for i = 2:length(Pulse_Index)
    if I(Pulse_Index(i-1)) > Current_Detection_Sens ...
            && I(Pulse_Index(i)) > Current_Detection_Sens
        Pulse_Index(i) = [];
    end
end


%% Start/Stop of a Pulse
% Identifies which current steps are the beginning of pulses
Pulse_Start_Index = find(abs(I(Pulse_Index)) < Current_Detection_Sens);
Pulse_Start_Index = Pulse_Index(Pulse_Start_Index);

% Assume the other current steps are the end of the current pulse
Pulse_Stop_Index = find(abs(I(Pulse_Index)) > Current_Detection_Sens);
Pulse_Stop_Index = Pulse_Index(Pulse_Stop_Index);


%% Find Capacity Test
% Assume charging current will be greater than 0.1 Amps, current
% value will be negative, and will last longer than 15 minutes (900
% seconds)
for i = 1:length(Current_Change_Index)-1
    if (I(Current_Change_Index(i)+5) < -0.1  ...
            && (Time(Current_Change_Index(i+1)) - Time(Current_Change_Index(i))) > 1000)
        Cap_Start = Current_Change_Index(i);
        Cap_End = Current_Change_Index(i+1);
        
        % Stop after condition is met the first time
        break
    else
        Cap_Start = [];
        Cap_End = [];
    end
end

% if Cap_Start >= Pulse_Start_Index(1)
% Identified capacity test occurs AFTER first identified current pulse
% of tests, meaning capacity test was mis-identified and did not occur
%     Cap_Start = [];
%     Cap_End = [];
% end


%% Remove pulses that don't last 30 seconds.
Short_Pulse_Index = [];
for i = 1:length(Pulse_Start_Index)
    if Time(Pulse_Stop_Index) - Time(Pulse_Start_Index) < 29.5
        Short_Pulse_Index(i) = i;
    end
end

Pulse_Start_Index(nonzeros(Short_Pulse_Index)) = [];
Pulse_Stop_Index(nonzeros(Short_Pulse_Index)) = [];


%% Remove pulses that are not constant-current from the index
% If the Current value drops below 98% the initial value before the end
% of the pulse, remove the pulse from indices
Fault_Index = [];
for i = 1:length(Pulse_Start_Index)
    if abs(I(Pulse_Stop_Index(i))) < abs(0.98 * I(Pulse_Start_Index(i)+5))
        Fault_Index(i) = i;
    end
end

Pulse_Start_Index(nonzeros(Fault_Index)) = [];
Pulse_Stop_Index(nonzeros(Fault_Index)) = [];

