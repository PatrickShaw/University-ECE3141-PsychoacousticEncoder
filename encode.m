path = 'snippet.flac';
close_frequency_range = 15;
% The further apart an amplitude spike is from other frequencies, the less 
% likely it is to drown out said frequency. This variable specifies how 
% much 'softer' said frequency's amplitude has to be to be considered 
% masked by the other frequency by this equation:
% Drowned out = softness * distance_weight_factor ^ delta(distance in frequency) >
% softer_factor_threshold.
distance_weighting_factor = 0.7;
% Anything that is <softer_factor_threshold> times softer than any
% frequencies that are <close_frequency_range> Hz in range of a given
% frequency will have its amplitude set to 0 in the FFT.
softer_factor_threshold = 2.5;
% In milliseconds
window_time_width = 4; 
[o_y, o_fs] = audioread(path);
plot(fftshift(fft(o_y(:, 1))));
audio_info = audioinfo(path);
disp(audio_info);

% Number of elements per window
window_sample_width = round(audio_info.SampleRate * (window_time_width / 1000)); 
audio_sample_len = size(o_y, 1);
w = 1;
channel_len = size(o_y, 2);
total_components_removed = 0;
total_windows = 0;
while w <= audio_sample_len
    % Grab the fast fourier transform so that we can determine what 
    % frequencies are being overpowered by other frequencies in the sample
    end_window_index = min(w + (window_sample_width - 1), audio_sample_len);
    for c = 1:channel_len
        fft_y = fft(o_y(w:end_window_index, c));
        fft_y_1_len = size(fft_y, 1);
        % Abs the FFT so we can look at soley the amplitude of the frequencies.
        % The FFT, otherwise, would be covered in complex numbers.
        fft_y_abs = abs(fft_y);
        f = close_frequency_range;
        while f <= fft_y_1_len - close_frequency_range
            amplitude = fft_y_abs(f);
            if amplitude <= 0
                continue
            end 
            other_f = max(1, f - close_frequency_range);
            other_f_end_index = min(f + close_frequency_range, fft_y_1_len);
            max_softer_factor = 0;
            while other_f <= other_f_end_index
                frequency_distance = abs(other_f - f);
                other_amplitude = fft_y_abs(other_f);
                softness = other_amplitude/amplitude;
                relative_softness = softness * (distance_weighting_factor ^ frequency_distance);
                max_softer_factor = max(relative_softness, max_softer_factor);
                other_f = other_f + 1;
            end
            % disp(max_softer_factor);
            if max_softer_factor >= softer_factor_threshold
                fft_y(f) = 0;
                total_components_removed = total_components_removed + 1;
            end
            f = f + 1;
        end
        % disp(fft_y);
        n_y = ifft(fft_y, 'symmetric');
        for i = 1:fft_y_1_len            
            o_y(w + (i - 1), c) = n_y(i);
        end
        % Add 1 window per channel
        total_windows = total_windows + 1;
    end
    w = w + floor(window_sample_width / 2);
end
average_components_removed_per_window = total_components_removed / total_windows;
plot(abs(fftshift(fft(o_y(:,1)))));
sound(o_y, o_fs);
audiowrite('snippet-output.flac', o_y, o_fs, 'BitsPerSample', audio_info.BitsPerSample);