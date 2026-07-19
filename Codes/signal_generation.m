%% ===================== SIGNAL GENERATION =====================
clear; clc; close all;

% Fixed sampling frequency
fs = 1652;

% Ask user for inputs
f0 = askNumber('Enter sinusoid frequency f0 (Hz) [5]: ', 5);
T  = askNumber('Enter total duration T (s) [8]: ', 8);
A  = askNumber('Enter sinusoid amplitude A [0.1]: ', 0.1);
t_mid = askNumber('Enter impact time t_mid (s) [T/2]: ', T/2);
A_shock = askNumber('Enter impact amplitude A_shock [2]: ', 2);

% Optional fixed impact width
sigma = 0.05;

% Time vector
t = 0:1/fs:T;

% Base sinusoid
x_base = A * sin(2*pi*f0*t);

% Gaussian impact
impact = A_shock * exp(-((t - t_mid).^2) / (2*sigma^2));

% Combined signal
x_comb = x_base + impact;

% Create numbered output files
runIndex = nextRunIndex("base_sinusoid", "csv");

baseCsv     = sprintf("base_sinusoid_%d.csv", runIndex);
impactCsv   = sprintf("impact_only_%d.csv", runIndex);
combinedCsv = sprintf("sinusoid_with_impact_%d.csv", runIndex);
combinedLmv = sprintf("sinusoid_with_impact_%d.lmv", runIndex);  % or .lvm if needed

% Save CSV files
base_table = table(t(:), x_base(:), ...
    'VariableNames', {'Time_s', 'Amplitude'});

impact_table = table(t(:), impact(:), ...
    'VariableNames', {'Time_s', 'Amplitude'});

combined_table = table(t(:), x_comb(:), ...
    'VariableNames', {'Time_s', 'Amplitude'});

writetable(base_table, baseCsv);
writetable(impact_table, impactCsv);
writetable(combined_table, combinedCsv);

% Save LabVIEW-style comma-separated file
% This writes the combined signal values in one comma-separated row
writeCommaSeparatedVector(combinedLmv, x_comb);

disp("Saved:");
disp(baseCsv);
disp(impactCsv);
disp(combinedCsv);
disp(combinedLmv);

% Plot excitation force
fontSize  = 12;
figWidth  = 5;
figHeight = 2.5;
lineWidth = 1.5;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

plot(t, x_comb, 'b', 'LineWidth', lineWidth);
grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Amplitude', 'FontName', 'Times New Roman', 'FontSize', fontSize);
title('Excitation Force', 'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Combined (sin + impact)', 'Location', 'best', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize);

%% ===== Local helper functions =====

function value = askNumber(prompt, defaultValue)
    s = input(prompt, 's');
    if isempty(strtrim(s))
        value = defaultValue;
    else
        value = str2double(s);
        if isnan(value)
            error("Invalid numeric input.");
        end
    end
end

function runIndex = nextRunIndex(prefix, ext)
    pattern = sprintf('%s_*.%s', prefix, ext);
    files = dir(pattern);

    idx = [];
    for k = 1:numel(files)
        name = files(k).name;
        expr = sprintf('^%s_(\\d+)\\.%s$', regexptranslate('escape', prefix), regexptranslate('escape', ext));
        tok = regexp(name, expr, 'tokens', 'once');
        if ~isempty(tok)
            idx(end+1) = str2double(tok{1}); %#ok<AGROW>
        end
    end

    if isempty(idx)
        runIndex = 1;
    else
        runIndex = max(idx) + 1;
    end
end

function writeCommaSeparatedVector(filename, data)
    fid = fopen(filename, 'w');
    if fid < 0
        error("Could not open file for writing: %s", filename);
    end

    cleanup = onCleanup(@() fclose(fid));

    data = data(:).';  % row vector
    if isempty(data)
        return;
    end

    fprintf(fid, '%.15g', data(1));
    for k = 2:numel(data)
        fprintf(fid, ',%.15g', data(k));
    end
end