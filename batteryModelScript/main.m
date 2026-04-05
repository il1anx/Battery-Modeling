%% Master Script - Battery Modeling Pipeline
clc; clear all;

%% User Inputs
cellName = input('Enter cell name (e.g. Samsung30Q): ', 's');
temp1    = input('Enter Temperature 1 (e.g. 25): ');
temp2    = input('Enter Temperature 2 (e.g. 40): ');
temp3    = input('Enter Temperature 3 (e.g. 60): ');

temps = [temp1, temp2, temp3];

runCombiner   = input('Run combiner? (y/n): ', 's');
runProcessor  = input('Run data processor? (y/n): ', 's');

%% Step 1 - Combiner
if strcmpi(runCombiner, 'y')

    for i = 1:3

        fprintf('\n--- Running Combiner for %s at %d degC ---\n', cellName, temps(i));

        rootPath    = pwd;
        currentTemp = temps(i);

        folderPath     = fullfile(rootPath, 'Data', 'Put unprocessed data here', ['Temp' num2str(i)]);
        outputFileName = fullfile(rootPath, 'Data', 'Data Steps', 'Combined csv files', ...
                         sprintf('%s_%ddegC_combined.csv', cellName, temps(i)));
        plotFileName   = fullfile(rootPath, 'Data', 'Data Steps', 'Combined csv files', ...
                         sprintf('%s_%ddegC_combined_plot.png', cellName, temps(i)));

        % Create output folder if it doesn't exist
        outputFolder = fullfile(rootPath, 'Data', 'Data Steps', 'Combined csv files');
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
            fprintf('Created output folder: %s\n', outputFolder);
        end

        cd('Scripts/Combine RCID Data')
        run('combiner.m')
        cd('../..')

        fprintf('--- Combiner Complete for %d degC ---\n', currentTemp);

    end

    fprintf('\n=== All 3 temperatures combined successfully ===\n\n');

else
    fprintf('\n--- Combiner skipped ---\n\n');
end

%% Step 2 - Process RCID Data (runs 3 times, user selects file each time)
if strcmpi(runProcessor, 'y')

    % Create ECM Models output folder if it doesn't exist
    rootPath  = pwd;
    ECMFolder = fullfile(rootPath, 'Data', 'Data Steps', 'ECM Models');
    if ~exist(ECMFolder, 'dir')
        mkdir(ECMFolder);
        fprintf('Created ECM Models folder: %s\n', ECMFolder);
    end

    for i = 1:3

        fprintf('\n--- Running Processor for %s at %d degC ---\n', cellName, temps(i));

        currentTemp   = temps(i);
        ECMOutputPath = ECMFolder;

        set(0, 'DefaultFigureVisible', 'off');  % Suppress figures

        cd('Scripts/Process RCID Data')
        run('RCID_Single_Temp_Model_v3_mod.m')
        cd('../..')

        set(0, 'DefaultFigureVisible', 'on');   % Restore figures
        close all;                               % Close any created figures

        fprintf('--- Processor Complete for %d degC ---\n', currentTemp);

    end

    fprintf('\n=== All 3 temperatures processed successfully ===\n\n');

else
    fprintf('\n--- Processor skipped ---\n\n');
end

%% Step 3 - Make Look Up Tables (runs once)
fprintf('\n--- Running Look Up Table Script ---\n');

cd('Scripts/Make Look Up Tables')
run('LookUpTableScript.m')
cd('../..')

fprintf('--- Look Up Tables Complete ---\n\n');

%% Step 4 - Open Simulink Model
fprintf('\n--- Opening Simulink Model ---\n');

rootPath = pwd;
open('batteryModel.slx')
save_system('batteryModel', fullfile(rootPath, sprintf('%s_batteryModel', cellName)));

fprintf('\n=== Pipeline Complete ===\n');