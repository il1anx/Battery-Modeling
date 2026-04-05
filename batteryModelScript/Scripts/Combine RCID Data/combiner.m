%% Program to combine RCID test data (Large Dataset Version)
% Author: Mehmet Kara
% Note: Exporting to .csv to bypass Excel limits and maintain performance

% folderPath is passed in from main.m - do not define here

%% Find Files
fileList = dir(fullfile(folderPath, '*.xlsx'));

if isempty(fileList)
    error('No .xlsx files found in: %s', folderPath);
end

fprintf('Found %d file(s):\n', length(fileList));
for i = 1:length(fileList)
    fprintf('  %s\n', fileList(i).name);
end

sheetName     = 'Channel4_1';
combinedData  = table();

%% Load and Combine Data
for i = 1:length(fileList)

    fullPath = fullfile(folderPath, fileList(i).name);

    if isfile(fullPath)
        tempData     = readtable(fullPath, 'Sheet', sheetName, 'Range', 'B:P', 'VariableNamingRule', 'preserve');
        combinedData = [combinedData; tempData];
        fprintf('Loaded: %s (Current Rows: %d)\n', fileList(i).name, height(combinedData));
    else
        warning('File not found: %s', fullPath);
    end

end

%% Export to .csv
% outputFileName is passed in from main.m - do not define here
writetable(combinedData, outputFileName);
fprintf('--- Data saved to %s ---\n', outputFileName);

%% Plotting
% Col 1 = Time | Col 4 = Voltage | Col 5 = Current | Col 15 = Temp
time = combinedData{:, 1};

fig = figure('Name', 'RCID Combined Plots', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

subplot(3,1,1);
plot(time, combinedData{:, 4}, 'r');
ylabel('Voltage (V)');
grid on;
title(sprintf('%s - %ddegC RCID Combined Data', cellName, currentTemp));

subplot(3,1,2);
plot(time, combinedData{:, 5}, 'b');
ylabel('Current (A)');
grid on;

subplot(3,1,3);
plot(time, combinedData{:, 15}, 'Color', [0 0.5 0]);
ylabel('Temp (°C)');
xlabel('Time (s)');
grid on;

%% Export Plot
% plotFileName is passed in from main.m - do not define here
saveas(fig, plotFileName);
fprintf('Plot exported as %s\n', plotFileName);