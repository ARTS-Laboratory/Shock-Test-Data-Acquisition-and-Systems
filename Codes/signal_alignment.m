%% ===================== signal alignment =====================

filename = "Run.xlsx";
Tdata = readtable(filename, "Sheet", "sheet1");

v    = Tdata.Voltage;
acc0 = Tdata.Acceleration_0;
acc1 = Tdata.Acceleration_1;

% Sampling rate + time vector
Fs = 1706;

v    = v(:);
acc0 = acc0(:);
acc1 = acc1(:);

N = numel(v);
t = (0:N-1)'/Fs;

% -------------------------------------------------------------------------
% Read the numbered impact file created by section 1
% Example: impact_only_1.csv, impact_only_2.csv, ...
% -------------------------------------------------------------------------
impactFile = "impact_only_1.csv";   % change this if needed

% Extract the number from the filename
runIndex = extractRunIndex(impactFile);

% If no number is found, use 1
if isnan(runIndex)
    runIndex = 1;
end

% Output filenames with the same index
pureImpactOnlyFile       = sprintf("pure_impact_aligned_only_%d.csv", runIndex);
pureImpactWithVoltFile   = sprintf("pure_impact_aligned_with_voltage_%d.csv", runIndex);
processedCleanFile       = sprintf("processed_clean_%d.csv", runIndex);

% -------------------------------------------------------------------------
% Plot raw voltage, no data removed
% -------------------------------------------------------------------------
fontSize  = 12;
figWidth  = 6;
figHeight = 3;
lineWidth = 1.2;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

plot(t, v, 'k', 'LineWidth', lineWidth);
grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Voltage', 'FontName', 'Times New Roman', 'FontSize', fontSize);
title('Raw Captured Voltage Without Removing Data', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Voltage', ...
       'Location', 'best', ...
       'FontName', 'Times New Roman', ...
       'FontSize', fontSize);

% -------------------------------------------------------------------------
% Plot raw accelerations, no data removed
% -------------------------------------------------------------------------
fontSize  = 12;
figWidth  = 6;
figHeight = 3;
lineWidth = 1.2;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

plot(t, acc0, 'b', 'LineWidth', lineWidth);
hold on;
plot(t, acc1, 'r', 'LineWidth', lineWidth);
hold off;

grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Acceleration', 'FontName', 'Times New Roman', 'FontSize', fontSize);
title('Raw Captured Accelerations Without Removing Data', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Acceleration\_0', ...
       'Acceleration\_1', ...
       'Location', 'best', ...
       'FontName', 'Times New Roman', ...
       'FontSize', fontSize);

% -------------------------------------------------------------------------
% DC removal
% -------------------------------------------------------------------------
v0    = v    - mean(v,    "omitnan");
acc0_0 = acc0 - mean(acc0, "omitnan");
acc1_0 = acc1 - mean(acc1, "omitnan");

% -------------------------------------------------------------------------
% Remove startup transient
% -------------------------------------------------------------------------
tTrim = 0.4;
i0 = floor(tTrim*Fs) + 1;

t2     = t(i0:end) - t(i0);
v0_2   = v0(i0:end);
acc0_2 = acc0_0(i0:end);
acc1_2 = acc1_0(i0:end);

% -------------------------------------------------------------------------
% Low-pass filter
% -------------------------------------------------------------------------
fc = 100;
order = 4;

[b,a] = butter(order, fc/(Fs/2), "low");

v_f    = filtfilt(b,a, v0_2);
acc0_f = filtfilt(b,a, acc0_2);
acc1_f = filtfilt(b,a, acc1_2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align pure impact with trimmed + filtered voltage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImpactData = readtable(impactFile);

t_imp_raw       = ImpactData{:,1};
pure_impact_raw = ImpactData{:,2};

t_imp_raw       = t_imp_raw(:);
pure_impact_raw = pure_impact_raw(:);

tEndImpact = t2(end);

t_align = t2;
v_align = v_f;

% Remove same initial duration from pure impact
idxImpactStart = t_imp_raw >= tTrim;

t_imp_trimmed       = t_imp_raw(idxImpactStart);
pure_impact_trimmed = pure_impact_raw(idxImpactStart);

% Reset time to start from zero
t_imp_trimmed = t_imp_trimmed - t_imp_trimmed(1);

% Keep only same duration as filtered voltage
idxImpactDuration = t_imp_trimmed <= tEndImpact;

t_imp_reduced       = t_imp_trimmed(idxImpactDuration);
pure_impact_reduced = pure_impact_trimmed(idxImpactDuration);

% Interpolate onto the voltage time vector
pure_impact_aligned = interp1( ...
    t_imp_reduced, ...
    pure_impact_reduced, ...
    t_align, ...
    "linear", ...
    0);

% Peak-based time alignment
impactWindow = t_align >= 3.0 & t_align <= 4.2;

t_win = t_align(impactWindow);
v_win = v_align(impactWindow);
p_win = pure_impact_aligned(impactWindow);

[~, idxVpeak] = max(v_win);
t_peak_voltage = t_win(idxVpeak);

[~, idxPpeak] = max(p_win);
t_peak_pure = t_win(idxPpeak);

timeShift = t_peak_voltage - t_peak_pure;

pure_impact_peak_aligned = interp1( ...
    t_align + timeShift, ...
    pure_impact_aligned, ...
    t_align, ...
    "linear", ...
    0);

disp("Filtered voltage final time = " + string(tEndImpact) + " s");
disp("Voltage peak time = " + string(t_peak_voltage) + " s");
disp("Pure impact peak time before alignment = " + string(t_peak_pure) + " s");
disp("Applied pure impact time shift = " + string(timeShift) + " s");

% -------------------------------------------------------------------------
% Save aligned pure impact only to CSV
% -------------------------------------------------------------------------
TpureImpactOnly = table(t_align, pure_impact_peak_aligned, ...
    'VariableNames', {'Time_s','Amplitude'});

writetable(TpureImpactOnly, pureImpactOnlyFile);
disp("Saved " + pureImpactOnlyFile);

% -------------------------------------------------------------------------
% Save aligned pure impact with voltage to CSV
% -------------------------------------------------------------------------
TimpactAligned = table(t_align, pure_impact_peak_aligned, v_align, ...
    'VariableNames', {'Time_s','PureImpact_aligned','Voltage_filt'});

writetable(TimpactAligned, pureImpactWithVoltFile);
disp("Saved " + pureImpactWithVoltFile);

% -------------------------------------------------------------------------
% Plot pure impact aligned with imposed voltage
% -------------------------------------------------------------------------
fontSize  = 12;
figWidth  = 7;
figHeight = 3.5;
lineWidth = 1.5;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

pureImpactPlot = pure_impact_peak_aligned;

if max(pureImpactPlot) ~= 0
    pureImpactPlot = pureImpactPlot / max(pureImpactPlot) * max(v_align);
end

plot(t_align, v_align, 'k', 'LineWidth', lineWidth);
hold on;
plot(t_align, pureImpactPlot, 'b', 'LineWidth', lineWidth);
yline(0, '--', 'LineWidth', 1);
hold off;

grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Voltage / Scaled Pure Impact', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize);

title('Pure Impact Aligned with Trimmed + Filtered Imposed Voltage', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

xlim([0, tEndImpact]);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Trimmed + Filtered Voltage', ...
       'Aligned Pure Impact, scaled for plot', ...
       'Zero Line', ...
       'Location', 'best', ...
       'FontName', 'Times New Roman', ...
       'FontSize', fontSize);

% -------------------------------------------------------------------------
% Plot imposed voltage
% -------------------------------------------------------------------------
fontSize  = 12;
figWidth  = 5;
figHeight = 3.5;
lineWidth = 1.5;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

plot(t_align, v_align, 'k', 'LineWidth', lineWidth);
grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Voltage', 'FontName', 'Times New Roman', 'FontSize', fontSize);
title('Imposed Voltage', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

xlim([0, tEndImpact]);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Trimmed + Filtered Voltage', ...
       'Location', 'best', ...
       'FontName', 'Times New Roman', ...
       'FontSize', fontSize);

% -------------------------------------------------------------------------
% Plot output acceleration of PCB
% -------------------------------------------------------------------------
fontSize  = 12;
figWidth  = 5;
figHeight = 3.5;
lineWidth = 1.5;

figure;
set(gcf, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);

plot(t_align, acc0_f, 'b', 'LineWidth', lineWidth);
hold on;
plot(t_align, acc1_f, 'r', 'LineWidth', lineWidth);
hold off;

grid on;
box on;

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', fontSize);
ylabel('Acceleration', 'FontName', 'Times New Roman', 'FontSize', fontSize);
title('Output Acceleration of PCB', ...
    'FontName', 'Times New Roman', 'FontSize', fontSize + 2);

xlim([0, tEndImpact]);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', fontSize, ...
    'LineWidth', 1);

legend('Trimmed + Filtered Acceleration\_0', ...
       'Trimmed + Filtered Acceleration\_1', ...
       'Location', 'best', ...
       'FontName', 'Times New Roman', ...
       'FontSize', fontSize);

% -------------------------------------------------------------------------
% Save processed data to CSV
% -------------------------------------------------------------------------
Tout = table(t_align, v_align, acc0_f, acc1_f, pure_impact_peak_aligned, ...
    'VariableNames', {'Time_s','Voltage_filt','Acc0_filt','Acc1_filt','PureImpact_aligned'});

writetable(Tout, processedCleanFile);
disp("Saved " + processedCleanFile);

%% ===== Local helper function =====
function runIndex = extractRunIndex(fileName)
    tok = regexp(fileName, '_(\d+)\.[^.]+$', 'tokens', 'once');
    if isempty(tok)
        runIndex = NaN;
    else
        runIndex = str2double(tok{1});
    end
end