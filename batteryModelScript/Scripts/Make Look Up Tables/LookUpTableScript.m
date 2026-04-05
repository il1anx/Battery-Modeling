clc
clearvars -except cellName rootPath temps ECMFolder ECMOutputPath

%load processed data
folder = '../../Data/Data Steps/ECM Models';
files = dir(fullfile(folder, '*.mat'));

%load simulink cell model
load_system('../../batteryModel');

%load files
for i = 1:length(files)
    data(i) = load(fullfile(folder, files(i).name));
end

%sort by smallest temp first
temps = arrayfun(@(x) x.ECM_Model.Temp_Value, data);
[~, sortIdx] = sort(temps);
data = data(sortIdx);

%Look Up table 1: OCV(3 temp values, 50 soc values)
temp_vector = [];
for i = 1:length(files)
    temp_vector = [temp_vector, data(i).ECM_Model.Temp_Value];
end

%first row is first file, and so on
OCV_matrix = [];
SOC_common = linspace(0.1, 1, 50);
for i = 1:length(files)
    SOC = data(i).ECM_Model.SOC_OCV;
    OCV = data(i).ECM_Model.OCV';
    OCV_matrix(i, :) = interp1(SOC, OCV, SOC_common);
end

set_param('batteryModel/cellModel/OCV Table', 'BreakpointsForDimension1', 'temp_vector', 'BreakpointsForDimension2', 'SOC_common', 'Table', 'OCV_matrix');


%Look Up Table #2: R0 (3 temperature values, 8 c rate values, 50 interpolated soc values)
Crate_vector = (data(1).ECM_Model.C_Rate_Value + data(2).ECM_Model.C_Rate_Value + data(3).ECM_Model.C_Rate_Value) / 3;

R0_array = zeros(length(SOC_common), length(Crate_vector), length(temp_vector));
R1_array = zeros(length(SOC_common), length(Crate_vector), length(temp_vector));
C1_array = zeros(length(SOC_common), length(Crate_vector), length(temp_vector));

for i = 1:length(temp_vector)
    for j = 1:length(Crate_vector)
        SOC_points = data(i).ECM_Model.C_Rate(j).Temp.SOC;
        R0_points  = data(i).ECM_Model.C_Rate(j).Temp.R_0;
        R1_points = data(i).ECM_Model.C_Rate(j).Temp.R_1;
        C1_points = data(i).ECM_Model.C_Rate(j).Temp.C_1;
        
        R0_array(:,j,i) = interp1(SOC_points, R0_points, SOC_common);
        R1_array(:,j,i) = interp1(SOC_points, R1_points, SOC_common);
        C1_array(:,j,i) = interp1(SOC_points, C1_points, SOC_common);
    end
end

set_param('batteryModel/cellModel/R0 Table', 'BreakpointsForDimension1', 'SOC_common', ...
    'BreakpointsForDimension2', 'Crate_vector', ...
    'BreakpointsForDimension3', 'temp_vector', 'Table', 'R0_array');

set_param('batteryModel/cellModel/R1 Table', 'BreakpointsForDimension1', 'SOC_common', ...
    'BreakpointsForDimension2', 'Crate_vector', ...
    'BreakpointsForDimension3', 'temp_vector', 'Table', 'R1_array');

set_param('batteryModel/cellModel/C1 Table', 'BreakpointsForDimension1', 'SOC_common', ...
    'BreakpointsForDimension2', 'Crate_vector', ...
    'BreakpointsForDimension3', 'temp_vector', 'Table', 'C1_array');