#include "whisper.h"

#include <cstring>
#include <fstream>
#include <string>
#include <vector>
#include <cstdint>

// Global whisper context
static struct whisper_context* g_ctx = nullptr;

// Read a WAV file and return PCM float samples (mono 16kHz)
static bool read_wav(const char* path, std::vector<float>& pcmf32) {
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) return false;

    // Read WAV header
    char riff[4];
    file.read(riff, 4);
    if (std::strncmp(riff, "RIFF", 4) != 0) return false;

    uint32_t chunk_size;
    file.read(reinterpret_cast<char*>(&chunk_size), 4);

    char wave[4];
    file.read(wave, 4);
    if (std::strncmp(wave, "WAVE", 4) != 0) return false;

    uint16_t audio_format = 0;
    uint16_t num_channels = 0;
    uint32_t sample_rate = 0;
    uint16_t bits_per_sample = 0;

    // Find fmt and data chunks
    while (file.good()) {
        char chunk_id[4];
        uint32_t sub_chunk_size;
        file.read(chunk_id, 4);
        file.read(reinterpret_cast<char*>(&sub_chunk_size), 4);

        if (std::strncmp(chunk_id, "fmt ", 4) == 0) {
            file.read(reinterpret_cast<char*>(&audio_format), 2);
            file.read(reinterpret_cast<char*>(&num_channels), 2);
            file.read(reinterpret_cast<char*>(&sample_rate), 2);
            // Skip byte rate and block align (6 bytes)
            file.seekg(6, std::ios::cur);
            file.read(reinterpret_cast<char*>(&bits_per_sample), 2);
            // Skip any extra fmt bytes
            if (sub_chunk_size > 16) {
                file.seekg(sub_chunk_size - 16, std::ios::cur);
            }
        } else if (std::strncmp(chunk_id, "data", 4) == 0) {
            // Read raw PCM data
            size_t n_samples = sub_chunk_size / (bits_per_sample / 8) / num_channels;
            pcmf32.resize(n_samples);

            if (bits_per_sample == 16) {
                std::vector<int16_t> pcm16(n_samples * num_channels);
                file.read(reinterpret_cast<char*>(pcm16.data()), sub_chunk_size);
                // Convert to float and mix to mono if needed
                for (size_t i = 0; i < n_samples; i++) {
                    if (num_channels == 1) {
                        pcmf32[i] = static_cast<float>(pcm16[i]) / 32768.0f;
                    } else {
                        // Mix channels to mono
                        float sum = 0.0f;
                        for (int c = 0; c < num_channels; c++) {
                            sum += static_cast<float>(pcm16[i * num_channels + c]);
                        }
                        pcmf32[i] = sum / (32768.0f * num_channels);
                    }
                }
            } else if (bits_per_sample == 32) {
                std::vector<float> pcm32(n_samples * num_channels);
                file.read(reinterpret_cast<char*>(pcm32.data()), sub_chunk_size);
                for (size_t i = 0; i < n_samples; i++) {
                    if (num_channels == 1) {
                        pcmf32[i] = pcm32[i];
                    } else {
                        float sum = 0.0f;
                        for (int c = 0; c < num_channels; c++) {
                            sum += pcm32[i * num_channels + c];
                        }
                        pcmf32[i] = sum / num_channels;
                    }
                }
            } else {
                return false;
            }

            // Resample to 16kHz if needed
            if (sample_rate != 16000 && sample_rate > 0) {
                std::vector<float> resampled;
                double ratio = 16000.0 / sample_rate;
                size_t new_size = static_cast<size_t>(n_samples * ratio);
                resampled.resize(new_size);
                for (size_t i = 0; i < new_size; i++) {
                    double src_idx = i / ratio;
                    size_t idx = static_cast<size_t>(src_idx);
                    if (idx >= n_samples - 1) idx = n_samples - 2;
                    double frac = src_idx - idx;
                    resampled[i] = static_cast<float>(
                        pcmf32[idx] * (1.0 - frac) + pcmf32[idx + 1] * frac
                    );
                }
                pcmf32 = std::move(resampled);
            }

            return true;
        } else {
            // Skip unknown chunk
            file.seekg(sub_chunk_size, std::ios::cur);
        }
    }

    return false;
}

static char* alloc_string(const std::string& s) {
    char* result = new char[s.length() + 1];
    std::strcpy(result, s.c_str());
    return result;
}

extern "C" {

// Initialize whisper with model path
char* init_whisper(const char* model_path) {
    if (g_ctx) {
        whisper_free(g_ctx);
        g_ctx = nullptr;
    }

    g_ctx = whisper_init_from_file_with_params(model_path, whisper_context_default_params());
    if (!g_ctx) {
        return alloc_string("ERROR: Failed to load model");
    }
    return alloc_string("OK");
}

// Transcribe audio file
char* transcribe(const char* audio_path, const char* model_path) {
    // Initialize model if needed
    if (!g_ctx) {
        g_ctx = whisper_init_from_file_with_params(model_path, whisper_context_default_params());
        if (!g_ctx) {
            return alloc_string("ERROR: Failed to load model");
        }
    }

    // Read WAV audio
    std::vector<float> pcmf32;
    if (!read_wav(audio_path, pcmf32)) {
        return alloc_string("ERROR: Failed to read audio file");
    }

    if (pcmf32.empty()) {
        return alloc_string("ERROR: Audio file is empty");
    }

    // Configure whisper parameters
    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.n_threads = 4;
    params.language = "en";
    params.translate = false;
    params.print_progress = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    params.single_segment = false;

    // Run transcription
    int ret = whisper_full(g_ctx, params, pcmf32.data(), static_cast<int>(pcmf32.size()));
    if (ret != 0) {
        return alloc_string("ERROR: Transcription failed");
    }

    // Collect results from all segments
    std::string text;
    int n_segments = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_segments; i++) {
        const char* seg_text = whisper_full_get_segment_text(g_ctx, i);
        if (seg_text) {
            text += seg_text;
        }
    }

    if (text.empty()) {
        return alloc_string("(no speech detected)");
    }

    return alloc_string(text);
}

// Free allocated string
void free_string(char* ptr) {
    delete[] ptr;
}

// Cleanup whisper context
void cleanup_whisper() {
    if (g_ctx) {
        whisper_free(g_ctx);
        g_ctx = nullptr;
    }
}

} // extern "C"
