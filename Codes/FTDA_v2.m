% fast_tda demo — MODIFIED VERSION
% Original Authors: Charlton Rolle and Jason D. Bakos
% Modifications:
%   - Added subplot 5 (Image 2a style) and subplot 6 (Image 2b style)
%   - Added Figure 2 (standalone, no overlay)
%   - Added Figure 3 (standalone, with grey overlay signal)
%   - Spectrogram: backward-search onset detection for precise alignment
%   - fig3 subplot (a): NO dashed lines
%   - fig3 subplot (b): dashed lines for all change points of 'a'
%                       HandleVisibility='off' so they don't pollute legend

clear all;
close all;

% ---------------------------------------------------------------
% 1. Read data
% ---------------------------------------------------------------
data   = readtable('processed_clean.csv');
time   = data.Time_s;
output = data.Acc1_filt;
fprintf('Data loaded: %d rows\n', length(time));


% data2   = readtable('data.csv');
% time2   = data2.Time_s;
% signal2 = data2.pure_impact;

time2=data.Time_s;
signal2=data.PureImpact_aligned;

dt = time(2) - time(1);
Fs = 1 / dt;
N  = length(output);

% ---------------------------------------------------------------
% 2. FFT spectrum
% ---------------------------------------------------------------
Y           = fft(output);
Y_magnitude = abs(Y / N);
if mod(N, 2) == 0
    f           = (0 : N/2) * (Fs / N);
    Y_magnitude = Y_magnitude(1 : N/2+1);
    Y_magnitude(2:end-1) = 2 * Y_magnitude(2:end-1);
else
    f           = (0 : (N-1)/2) * (Fs / N);
    Y_magnitude = Y_magnitude(1 : (N+1)/2);
    Y_magnitude(2:end) = 2 * Y_magnitude(2:end);
end
figure;
plot(f, Y_magnitude);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Single-Sided Amplitude Spectrum of Output Signal');
grid on;

% ---------------------------------------------------------------
% 3. Peak frequency detection
% ---------------------------------------------------------------
max_mag = max(Y_magnitude);
[~, peak_props] = findpeaks(Y_magnitude, ...
    'MinPeakHeight',     0.05 * max_mag, ...
    'MinPeakProminence', 0.10 * max_mag, ...
    'MinPeakDistance',   5);
peak_freqs = f(peak_props);
Fmin = min(peak_freqs);
Fmax = max(peak_freqs);
fprintf('F_max = %0.2f Hz,  F_min = %0.2f Hz\n', Fmax, Fmin);
hold off;

% ---------------------------------------------------------------
% 4. Detect impact onset using backward search from signal peak
%
%    METHOD:
%    Step 1 — find the index of the absolute signal peak (impact peak)
%    Step 2 — compute baseline stats from t=0.5s to 30% of signal
%    Step 3 — walk BACKWARD from the peak until signal falls
%             below 2-sigma threshold → that crossing is the true onset
%
%    This avoids the lag of forward rolling-window methods and gives
%    the precise moment the signal first starts rising toward the peak.
% ---------------------------------------------------------------
% Step 1: peak of impact
[~, peak_idx] = max(abs(output));

% Step 2: stable baseline (skip first 0.5s startup, use up to 30%)
bl_start_idx = find(time >= 0.5, 1, 'first');
bl_end_idx   = round(0.30 * length(output));
bl_end_idx   = max(bl_end_idx, bl_start_idx + 10);
baseline_sig = output(bl_start_idx : bl_end_idx);
bl_mean_sig  = mean(baseline_sig);
bl_std_sig   = std(baseline_sig);

% Step 3: walk backward from peak — onset = last time below 2-sigma
onset_thresh = bl_mean_sig + 2 * bl_std_sig;
search_back  = max(bl_start_idx, peak_idx - round(2.0 * Fs));
impact_idx   = peak_idx;   % default fallback

for k = peak_idx : -1 : search_back
    if abs(output(k) - bl_mean_sig) < 2 * bl_std_sig
        impact_idx = k + 1;   % first sample that crossed threshold going forward
        break;
    end
end
t_impact = time(impact_idx);
fprintf('Impact onset detected: t = %.3f s\n', t_impact);

% ---------------------------------------------------------------
% 5. Spectrogram — white dashed line at onset time
% ---------------------------------------------------------------
spec_window = hamming(1024);
noverlap    = 1;
nfft        = 16384;
fig_spec    = figure;
spectrogram(output, spec_window, noverlap, nfft, Fs, 'yaxis');
title('Spectrogram of Output Signal');
colorbar; colormap(parula);
ylim([0, Fs/2/1000]);
caxis([-80, 50]);

hold on;
ax_spec = gca;
xl_spec = xline(ax_spec, t_impact, '--', ...
    'LineWidth',  2.0, ...
    'Color',      [1 1 1], ...
    'Label',      sprintf('impact\nt = %.2f s', t_impact), ...
    'LabelColor', [1 1 1], ...
    'FontSize',   9, ...
    'FontWeight', 'bold');
xl_spec.HandleVisibility = 'off';
hold off;

% ---------------------------------------------------------------
% 6. TDA parameters
% ---------------------------------------------------------------
time_delay            = 0.25 / Fmax;
time_delay_in_samples = round(time_delay / dt);
window_duration       = 1 / Fmin;
num_points_per_window = round(window_duration / dt);
num_windows           = length(time);
step_size             = 50;

% ---------------------------------------------------------------
% 7. Video setup
% ---------------------------------------------------------------
if exist('myVideo.mp4', 'file'), delete('myVideo.mp4'); end
video            = VideoWriter('myVideo.mp4', 'MPEG-4');
video.FrameRate  = 10;
video_opened     = false;
first_frame_size = [];

% ---------------------------------------------------------------
% 8. Signal ranges
% ---------------------------------------------------------------
min_accel = min(output, [], 'all');
max_accel = max(output, [], 'all');

% ---------------------------------------------------------------
% 9. Color palette: a=blue, b=red, c=yellow, d=purple, e=green
% ---------------------------------------------------------------
param_colors = [0.00  0.45  0.74;
                0.85  0.33  0.10;
                0.93  0.69  0.13;
                0.49  0.18  0.56;
                0.47  0.67  0.19];

% ---------------------------------------------------------------
% 10. Create figure 1 — 6 subplots (video figure)
% ---------------------------------------------------------------
fig = figure('Visible', 'off', 'Renderer', 'opengl', ...
             'Position', [100, 100, 1200, 1500]);

ax1 = subplot(6, 1, 1);
plot(ax1, time, output, 'r-', 'LineWidth', 2);
hold(ax1, 'on'); grid(ax1, 'on');
xlabel(ax1, 'time'); ylabel(ax1, 'acceleration');
title(ax1, 'time series data and TDA window');
xlim(ax1, [min(time), max(time)]);

ax2 = subplot(6, 1, 2);
title(ax2, 'ellipse fit of Takens embedding in window');

ax3 = subplot(6, 1, 3);
line_handles_conic = gobjects(5, 1);
for j = 1:5
    line_handles_conic(j) = plot(ax3, NaN, NaN, 'LineWidth', 1);
    hold(ax3, 'on');
end
legend(ax3, {'a','b','c','d','e'});
xlabel(ax3, 'time');
title(ax3, 'conic ellipse parameters');
xlim(ax3, [min(time), max(time)]);

ax4 = subplot(6, 1, 4);
line_handles_parametric = gobjects(5, 1);
yyaxis(ax4, 'left');
for j = 1:4
    line_handles_parametric(j) = plot(ax4, NaN, NaN, 'LineWidth', 1);
    hold(ax4, 'on');
end
ylabel(ax4, 'position and size');
yyaxis(ax4, 'right');
line_handles_parametric(5) = plot(ax4, NaN, NaN, 'LineWidth', 1);
ylabel(ax4, 'angle (rad)');
hold(ax4, 'on');
legend(ax4, {'center\_x','center\_y','semi-major','semi-minor','angle'});
xlabel(ax4, 'time');
title(ax4, 'parametric ellipse parameters');
xlim(ax4, [min(time), max(time)]);

ax5 = subplot(6, 1, 5);
line_handles_ax5 = gobjects(5, 1);
for j = 1:5
    line_handles_ax5(j) = plot(ax5, NaN, NaN, ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
    hold(ax5, 'on');
end
grid(ax5, 'on');
ylabel(ax5, 'ellipse parameters');
xlabel(ax5, 'time (s)');
title(ax5, 'ellipse parameters (a)');
xlim(ax5, [min(time), max(time)]);
legend(ax5, {'a','b','c','d','e'}, 'Location', 'northeast');

ax6 = subplot(6, 1, 6);
line_handles_ax6 = gobjects(5, 1);
for j = 1:5
    line_handles_ax6(j) = plot(ax6, NaN, NaN, ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
    hold(ax6, 'on');
end
grid(ax6, 'on');
ylabel(ax6, 'normalised value');
xlabel(ax6, 'time (s)');
title(ax6, 'normalised ellipse parameters — rolling window (b)');

offset_sep   = 1.5;
roll_win_sec = 1.0;
ytick_vals   = (0:4) * offset_sep;
ytick_labels = {'e','d','c','b','a'};
set(ax6, 'YTick', ytick_vals, 'YTickLabel', ytick_labels);
ylim(ax6, [-offset_sep, 5*offset_sep]);

% ---------------------------------------------------------------
% 11. Pre-loop allocations
% ---------------------------------------------------------------
ellipse_params            = zeros(6, num_windows);
ellipse_params_parametric = zeros(5, num_windows);
rect_handle               = [];

start_of_window              = -num_points_per_window + 1;
lag_prior_to_start_of_window = start_of_window - time_delay_in_samples;
zero_padding_lag             = zeros(-lag_prior_to_start_of_window, 1);
output_pad                   = [zero_padding_lag; output];

% ---------------------------------------------------------------
% 12. MAIN LOOP
% ---------------------------------------------------------------
for i = 1:step_size:num_windows

    P = [output_pad(i : i+num_points_per_window-1-time_delay_in_samples), ...
         output_pad(i+time_delay_in_samples : i+num_points_per_window-1)];

    ellipse_params(:, i) = fit_ellipse_hls_golden(P(:,1), P(:,2));

    if ~isempty(rect_handle), delete(rect_handle); end
    x_left = i * dt - window_duration;
    x_rect = [x_left, x_left+window_duration, x_left+window_duration, x_left];
    y_rect = [min_accel, min_accel, max_accel, max_accel];
    rect_handle = patch(ax1, x_rect, y_rect, [0.5 0.7 1], ...
        'FaceAlpha', 0.3, 'EdgeColor', 'b', 'LineWidth', 1);

    if ~any(isnan(ellipse_params(:, i)))

        cla(ax2);
        plot_ellipse(P, ellipse_params(:, i), ax2);
        title(ax2, 'ellipse fit of Takens embedding in window');

        indices  = 1:step_size:i;
        t_values = indices * dt;

        for j = 1:5
            set(line_handles_conic(j), ...
                'XData', t_values, 'YData', ellipse_params(j, indices));
        end
        xlim(ax3, [min(time), max(time)]); ylim(ax3, 'auto');

        [ellipse_params_parametric(1,i), ...
         ellipse_params_parametric(2,i), ...
         ellipse_params_parametric(3,i), ...
         ellipse_params_parametric(4,i), ...
         ellipse_params_parametric(5,i)] = conic_to_parametric(ellipse_params(:,i));

        yyaxis(ax4, 'left');
        for j = 1:4
            y_data    = ellipse_params_parametric(j, indices);
            valid_idx = ~isnan(y_data);
            if any(valid_idx)
                set(line_handles_parametric(j), ...
                    'XData', t_values(valid_idx), 'YData', y_data(valid_idx));
            end
        end
        ylim(ax4, 'auto');
        yyaxis(ax4, 'right');
        y_data    = ellipse_params_parametric(5, indices);
        valid_idx = ~isnan(y_data);
        if any(valid_idx)
            set(line_handles_parametric(5), ...
                'XData', t_values(valid_idx), 'YData', y_data(valid_idx));
        end
        ylim(ax4, 'auto');
        xlim(ax4, [min(time), max(time)]);

        for j = 1:5
            set(line_handles_ax5(j), ...
                'XData', t_values, 'YData', ellipse_params(j, indices));
        end
        xlim(ax5, [min(time), max(time)]); ylim(ax5, 'auto');

        current_t    = i * dt;
        t_roll_start = max(min(time), current_t - roll_win_sec);
        t_roll_end   = current_t;
        roll_mask    = (t_values >= t_roll_start) & (t_values <= t_roll_end);

        if sum(roll_mask) > 2
            t_roll = t_values(roll_mask);
            for j = 1:5
                all_vals  = ellipse_params(j, indices);
                roll_vals = all_vals(roll_mask);
                mu_j      = mean(all_vals, 'omitnan');
                sig_j     =  std(all_vals, 'omitnan');
                if sig_j < 1e-10, sig_j = 1; end
                norm_vals = (roll_vals - mu_j) / sig_j;
                offset_j  = (5 - j) * offset_sep;
                set(line_handles_ax6(j), 'XData', t_roll, 'YData', norm_vals + offset_j);
            end
            xlim(ax6, [t_roll_start, t_roll_end]);
            set(ax6, 'YTick', ytick_vals, 'YTickLabel', ytick_labels);
            ylim(ax6, [-offset_sep, 5*offset_sep]);
        end
    end

    drawnow;
    frame = getframe(fig);
    if ~video_opened
        first_frame_size = size(frame.cdata);
        open(video);
        video_opened = true;
    end
    if ~isequal(size(frame.cdata), first_frame_size)
        frame.cdata = imresize(frame.cdata, first_frame_size(1:2));
    end
    writeVideo(video, frame);
end

close(video);

% ---------------------------------------------------------------
% POST-LOOP: shared data for fig2 and fig3
% ---------------------------------------------------------------
all_indices  = 1:step_size:num_windows;
t_all        = all_indices * dt;
valid_mask   = ~any(isnan(ellipse_params(:, all_indices)), 1);
t_valid      = t_all(valid_mask);
idx_valid    = all_indices(valid_mask);

param_colors = [0.00  0.45  0.74;
                0.85  0.33  0.10;
                0.93  0.69  0.13;
                0.49  0.18  0.56;
                0.47  0.67  0.19];

grey_color    = [0.55  0.55  0.55];
param_names   = {'a','b','c','d','e'};
offset_sep_mm = 1.15;

% ---------------------------------------------------------------
% Detect ALL change points of parameter 'a' (j=1, blue)
%
% Baseline: t = 0.5 to 3.0 s  (stable region before any impact)
%           avoids startup artifact at ~0.18s
%
% Change point: first sample of each new group where
%   |param_a - bl_mean| > 3 * bl_std
%   groups separated by at least 0.3 seconds
% ---------------------------------------------------------------
param_a     = ellipse_params(1, idx_valid);
stable_mask = (t_valid >= 0.5) & (t_valid <= 3.0);
if sum(stable_mask) < 5
    stable_mask = true(size(t_valid));
end
bl_mean_a = mean(param_a(stable_mask), 'omitnan');
bl_std_a  =  std(param_a(stable_mask), 'omitnan');
fprintf('Param a  baseline:  mean=%.4f  std=%.4f\n', bl_mean_a, bl_std_a);

change_mask  = abs(param_a - bl_mean_a) > 3 * bl_std_a;
rising_edges = find([false, diff(change_mask) > 0]);

min_gap_sec   = 0.3;
t_changes_a   = [];
last_accepted = -inf;
for k = 1:length(rising_edges)
    t_cand = t_valid(rising_edges(k));
    if t_cand - last_accepted >= min_gap_sec
        t_changes_a(end+1) = t_cand; %#ok<AGROW>
        last_accepted       = t_cand;
    end
end

if isempty(t_changes_a)
    fprintf('No change points found — using impact time.\n');
    t_changes_a = t_impact;
else
    fprintf('Parameter a change points (%d total):\n', length(t_changes_a));
    fprintf('  t = %.3f s\n', t_changes_a);
end

% ---------------------------------------------------------------
% FIGURE 2 — standalone, NO overlay, NO dashed lines
% ---------------------------------------------------------------
fig2 = figure('Name', 'Ellipse Parameters — Full Range', ...
              'Position', [200, 100, 800, 700]);

ax_a2 = subplot(2, 1, 1);
hold(ax_a2, 'on'); grid(ax_a2, 'on'); box(ax_a2, 'on');
for j = 1:5
    plot(ax_a2, t_valid, ellipse_params(j, idx_valid), ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
end
ylabel(ax_a2, 'ellipse parameters');
xlabel(ax_a2, 'time (s)');
xlim(ax_a2, [min(time), max(time)]); ylim(ax_a2, 'auto');
legend(ax_a2, fliplr(param_names), 'Location', 'northeast');
title(ax_a2, '(a)');
hold(ax_a2, 'off');

ax_b2 = subplot(2, 1, 2);
hold(ax_b2, 'on'); grid(ax_b2, 'on'); box(ax_b2, 'on');
for j = 1:5
    all_vals  = ellipse_params(j, idx_valid);
    rng_j     = max(all_vals) - min(all_vals);
    if rng_j < 1e-12, rng_j = 1; end
    norm_vals = (all_vals - min(all_vals)) / rng_j;
    offset_j  = (5 - j) * offset_sep_mm;
    plot(ax_b2, t_valid, norm_vals + offset_j, ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
end
ytick_mm   = (0:4) * offset_sep_mm + 0.5;
ytick_l_mm = {'e','d','c','b','a'};
set(ax_b2, 'YTick', ytick_mm, 'YTickLabel', ytick_l_mm);
ylim(ax_b2, [-0.2, 5.8]);
xlim(ax_b2, [min(time), max(time)]);
ylabel(ax_b2, 'normalised value');
xlabel(ax_b2, 'time (s)');
title(ax_b2, '(b)');
hold(ax_b2, 'off');

saveas(fig2, 'ellipse_params_full_range.png');
fprintf('Saved: ellipse_params_full_range.png\n');

% ---------------------------------------------------------------
% FIGURE 3 — WITH grey overlay
%   subplot (a): raw parameters + grey overlay — NO dashed lines
%   subplot (b): normalised parameters + grey overlay
%                + dashed lines for ALL change points of 'a'
%                  HandleVisibility='off' → excluded from legend
% ---------------------------------------------------------------
fig3 = figure('Name', 'Ellipse Parameters + Grey Overlay', ...
              'Position', [250, 150, 800, 700]);

% -------------------------------------------------------
% fig3 subplot (a) — NO dashed lines
% -------------------------------------------------------
ax_a3 = subplot(2, 1, 1);
hold(ax_a3, 'on'); grid(ax_a3, 'on'); box(ax_a3, 'on');

line_handles_a3 = gobjects(5,1);
for j = 1:5
    line_handles_a3(j) = plot(ax_a3, t_valid, ellipse_params(j, idx_valid), ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
end

% Right axis — grey overlay
yyaxis(ax_a3, 'right');
h_grey_a3 = plot(ax_a3, time2, signal2, '-', ...
    'Color', grey_color, 'LineWidth', 1.0);
ylabel(ax_a3, 'output signal');
ax_a3.YAxis(2).Color = grey_color;
ylim(ax_a3, 'auto');

% Back to left axis — labels and legend only (no xlines here)
yyaxis(ax_a3, 'left');
ylabel(ax_a3, 'ellipse parameters');
xlabel(ax_a3, 'time (s)');
xlim(ax_a3, [min(time), max(time)]);
ylim(ax_a3, 'auto');
title(ax_a3, '(a)');
legend(ax_a3, [flip(line_handles_a3); h_grey_a3], ...
    [fliplr(param_names), {'output (grey)'}], 'Location', 'northeast');
hold(ax_a3, 'off');

% -------------------------------------------------------
% fig3 subplot (b) — WITH dashed lines, no legend entries
% -------------------------------------------------------
ax_b3 = subplot(2, 1, 2);
hold(ax_b3, 'on'); grid(ax_b3, 'on'); box(ax_b3, 'on');

% Left axis — min-max normalised + stacked offset
for j = 1:5
    all_vals  = ellipse_params(j, idx_valid);
    rng_j     = max(all_vals) - min(all_vals);
    if rng_j < 1e-12, rng_j = 1; end
    norm_vals = (all_vals - min(all_vals)) / rng_j;
    offset_j  = (5 - j) * offset_sep_mm;
    plot(ax_b3, t_valid, norm_vals + offset_j, ...
        'LineWidth', 1.5, 'Color', param_colors(j,:));
end

ytick_mm   = (0:4) * offset_sep_mm + 0.5;
ytick_l_mm = {'e','d','c','b','a'};
set(ax_b3, 'YTick', ytick_mm, 'YTickLabel', ytick_l_mm);
ylim(ax_b3, [-0.2, 5.8]);

% Right axis — grey signal raw
yyaxis(ax_b3, 'right');
plot(ax_b3, time2, signal2, '-', ...
    'Color', grey_color, 'LineWidth', 1.0);
ylabel(ax_b3, 'output signal');
ax_b3.YAxis(2).Color = grey_color;
ylim(ax_b3, 'auto');

% Restore left axis labels
yyaxis(ax_b3, 'left');
set(ax_b3, 'YTick', ytick_mm, 'YTickLabel', ytick_l_mm);
ylim(ax_b3, [-0.2, 5.8]);
ylabel(ax_b3, 'normalised value');
xlabel(ax_b3, 'time (s)');
xlim(ax_b3, [min(time), max(time)]);
title(ax_b3, '(b)');

% Add one dashed line per change point
% HandleVisibility='off' → line objects excluded from legend
for k = 1:length(t_changes_a)
    xl = xline(ax_b3, t_changes_a(k), '--k', ...
        'LineWidth',  1.5, ...
        'Label',      sprintf('t=%.2fs', t_changes_a(k)), ...
        'LabelVerticalAlignment', 'bottom', ...
        'FontSize',   7, ...
        'FontWeight', 'bold');
    xl.HandleVisibility = 'off';   % ← excluded from legend
end

hold(ax_b3, 'off');

saveas(fig3, 'ellipse_params_with_overlay.png');
fprintf('Saved: ellipse_params_with_overlay.png\n');

% ===============================================================
% LOCAL FUNCTIONS
% ===============================================================

function ellipse_params = fit_ellipse(P)
    D = [P(:,1).^2, P(:,1).*P(:,2), P(:,2).^2, ...
         P(:,1), P(:,2), ones(size(P,1),1)];
    S = D' * D;
    C = zeros(6,6);
    C(1,3) = 2; C(2,2) = -1; C(3,1) = 2;
    [eigvecs, eigvals] = eig(S, C);
    eigvals    = diag(eigvals);
    finite_idx = isfinite(eigvals);
    pos_idx    = eigvals > 0;
    idx        = find(pos_idx & finite_idx);
    if length(idx) ~= 1
        warning('No unique positive finite eigenvalue; using first valid.');
        idx = find(finite_idx, 1);
        if isempty(idx)
            ellipse_params = zeros(6,1); return;
        end
    end
    v  = eigvecs(:, idx(1));
    mu = 1 / sqrt(v' * C * v);
    ellipse_params = mu * v;
    a = ellipse_params(1); b = ellipse_params(2); c = ellipse_params(3);
    if abs(4*a*c - b^2 - 1) > 1e-5 || (b^2 - 4*a*c) >= 0
        warning('Fit may not be a valid ellipse.');
    end
end

function a = fit_ellipse_hls_golden(x, y)
    if length(x) < 5, error('At least 5 points required'); end
    D   = [x.^2, x.*y, y.^2, x, y, ones(size(x))];
    S   = D' * D;
    Spp = S(1:3, 1:3);
    Spq = S(1:3, 4:6);
    Sqq = S(4:6, 4:6);
    REG_EPSILON = 1e-6;
    a_qq = Sqq(1,1) + REG_EPSILON;
    b    = Sqq(1,2);
    c    = Sqq(1,3);
    e    = Sqq(2,2) + REG_EPSILON;
    f    = Sqq(2,3);
    g    = Sqq(3,3) + REG_EPSILON;
    det     = a_qq*(e*g - f*f) - b*(b*g - f*c) + c*(b*f - e*c);
    inv_det = 1.0 / det;
    inv_qq      = zeros(3);
    inv_qq(1,1) =  (e*g - f*f) * inv_det;
    inv_qq(1,2) = -(b*g - c*f) * inv_det;
    inv_qq(1,3) =  (b*f - c*e) * inv_det;
    inv_qq(2,1) =  inv_qq(1,2);
    inv_qq(2,2) =  (a_qq*g - c*c) * inv_det;
    inv_qq(2,3) = -(a_qq*f - c*b) * inv_det;
    inv_qq(3,1) =  inv_qq(1,3);
    inv_qq(3,2) =  inv_qq(2,3);
    inv_qq(3,3) =  (a_qq*e - b*b) * inv_det;
    temp      = Spq * inv_qq;
    S_reduced = Spp - temp * Spq';
    invD = [ 0.0  0.5  0.0;
             0.5  0.0  0.0;
             0.0  0.0 -1.0 ];
    A          = invD * S_reduced;
    [V, D_eig] = eig(A);
    lambdas    = diag(D_eig);
    [~, idx]   = min(abs(lambdas));
    ap         = V(:, idx);
    aq         = -inv_qq * (Spq' * ap);
    a          = [ap; aq];
    C          = zeros(6,6);
    C(1,3)     = 2;  C(3,1) = 2;  C(2,2) = -1;
    scale      = sqrt(abs(a' * C * a));
    if scale > 1e-12, a = a / scale; end
end

function [] = plot_ellipse(P, ellipse_params, ax)
    axes(ax);
    mins = min(P); maxs = max(P);
    pad  = 1e-6;
    if maxs(1) <= mins(1), maxs(1) = mins(1) + pad; end
    if maxs(2) <= mins(2), maxs(2) = mins(2) + pad; end
    scatter(P(:,1), P(:,2), '.');
    hold on;
    xlim([mins(1) maxs(1)]); ylim([mins(2) maxs(2)]);
    if ~any(isinf(ellipse_params))
        a = ellipse_params(1); b = ellipse_params(2);
        c = ellipse_params(3); d = ellipse_params(4);
        e = ellipse_params(5); f = ellipse_params(6);
        ellipse_fn = @(x,y) a*x.^2 + b*x.*y + c*y.^2 + d*x + e*y + f;
        fimplicit(ellipse_fn, ...
            [mins(1) maxs(1) mins(2) maxs(2)], 'LineWidth', 2);
    end
    hold off;
end

function [center_x, center_y, semi_major, semi_minor, angle] = ...
        conic_to_parametric(params)
    a = params(1); b = params(2); c = params(3);
    d = params(4); e = params(5); f = params(6);
    delta = b^2 - 4*a*c;
    if delta >= 0 || abs(a) < 1e-10 || abs(c) < 1e-10
        center_x = NaN; center_y = NaN;
        semi_major = NaN; semi_minor = NaN; angle = NaN;
        return;
    end
    denom    = b^2 - 4*a*c;
    center_x = (2*c*d - b*e) / denom;
    center_y = (2*a*e - b*d) / denom;
    if abs(b) < 1e-10
        angle = 0;
    elseif abs(a - c) < 1e-10
        angle = pi/4;
    else
        angle = 0.5 * atan(b / (a - c));
    end
    a_prime    = a*center_x^2 + b*center_x*center_y + c*center_y^2 ...
               + d*center_x   + e*center_y + f;
    lambda1    = (a + c + sqrt((a-c)^2 + b^2)) / 2;
    lambda2    = (a + c - sqrt((a-c)^2 + b^2)) / 2;
    semi_major = sqrt(-a_prime / lambda1);
    semi_minor = sqrt(-a_prime / lambda2);
    if semi_minor > semi_major || semi_major < 1e-5 || semi_minor < 1e-5
        temp       = semi_major;
        semi_major = semi_minor;
        semi_minor = temp;
        angle      = angle + pi/2;
    end
    if semi_major > 1e5 || semi_minor > 1e5
        semi_major = NaN; semi_minor = NaN;
    end
end

function [vec, val] = myjacobian(S, C)
    if nargin < 2, C = eye(size(S, 1)); end
    n   = size(S, 1);
    tol = 1e-10;
    V   = eye(n);
    for iter = 1:10000
        for p = 1:n-1
            for q = p+1:n
                if abs(S(p,q)) < tol, continue; end
                app = S(p,p); apq = S(p,q); aqq = S(q,q);
                bpp = C(p,p); bpq = C(p,q); bqq = C(q,q);
                A1   = app*bpq - apq*bpp;
                B1   = app*bqq - aqq*bpp;
                C1   = apq*bqq - aqq*bpq;
                disc = B1^2 - 4*A1*C1;
                if disc < 0, continue; end
                if abs(A1) < tol
                    if abs(B1) < tol, continue; end
                    theta2 = -C1 / B1;
                else
                    sqrt_disc    = sqrt(disc);
                    theta2_plus  = (-B1 + sqrt_disc) / (2*A1);
                    theta2_minus = (-B1 - sqrt_disc) / (2*A1);
                    if abs(theta2_plus) < abs(theta2_minus)
                        theta2 = theta2_plus;
                    else
                        theta2 = theta2_minus;
                    end
                end
                denom = apq*theta2 + aqq;
                if abs(denom) < tol, continue; end
                theta1 = -(app*theta2 + apq) / denom;
                if isnan(theta1) || isnan(theta2), continue; end
                S_temp = zeros(n,n);
                for ii=1:n; for jj=1:n; for kk=1:n
                    if     ii==p && kk==p, j_val=1;
                    elseif ii==p && kk==q, j_val=theta1;
                    elseif ii==q && kk==p, j_val=theta2;
                    elseif ii==q && kk==q, j_val=1;
                    elseif ii==kk,         j_val=1;
                    else,                  j_val=0; end
                    S_temp(ii,jj) = S_temp(ii,jj) + S(kk,jj)*j_val;
                end; end; end
                S_temp2 = zeros(n,n);
                for ii=1:n; for jj=1:n; for kk=1:n
                    if     kk==p && jj==p, j_val=1;
                    elseif kk==p && jj==q, j_val=theta2;
                    elseif kk==q && jj==p, j_val=theta1;
                    elseif kk==q && jj==q, j_val=1;
                    elseif kk==jj,         j_val=1;
                    else,                  j_val=0; end
                    S_temp2(ii,jj) = S_temp2(ii,jj) + S_temp(ii,kk)*j_val;
                end; end; end
                S = S_temp2;
                C_temp = zeros(n,n);
                for ii=1:n; for jj=1:n; for kk=1:n
                    if     ii==p && kk==p, j_val=1;
                    elseif ii==p && kk==q, j_val=theta1;
                    elseif ii==q && kk==p, j_val=theta2;
                    elseif ii==q && kk==q, j_val=1;
                    elseif ii==kk,         j_val=1;
                    else,                  j_val=0; end
                    C_temp(ii,jj) = C_temp(ii,jj) + C(kk,jj)*j_val;
                end; end; end
                C_temp2 = zeros(n,n);
                for ii=1:n; for jj=1:n; for kk=1:n
                    if     kk==p && jj==p, j_val=1;
                    elseif kk==p && jj==q, j_val=theta2;
                    elseif kk==q && jj==p, j_val=theta1;
                    elseif kk==q && jj==q, j_val=1;
                    elseif kk==jj,         j_val=1;
                    else,                  j_val=0; end
                    C_temp2(ii,jj) = C_temp2(ii,jj) + C_temp(ii,kk)*j_val;
                end; end; end
                C = C_temp2;
                vp = V(:,p); vq = V(:,q);
                V(:,p) = vp*1      + vq*theta1;
                V(:,q) = vp*theta2 + vq*1;
            end
        end
        off_S = norm(S - diag(diag(S)), 'fro');
        off_C = norm(C - diag(diag(C)), 'fro');
        if off_S < tol && off_C < tol, break; end
    end
    vals = diag(S) ./ diag(C);
    for i = 1:n
        normv = norm(V(:,i));
        if normv > tol, V(:,i) = V(:,i) / normv; end
    end
    [val, idx] = sort(vals);
    vec = V(:, idx);
end