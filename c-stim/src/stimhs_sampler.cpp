#include "stimhs.h"
#include "stim/circuit/circuit.h"
#include "stim/simulators/frame_simulator_util.h"
#include "stim/simulators/tableau_simulator.h"
#include <random>
#include <cstring>

namespace stimhs {
    void write_err_buf(char* err_buf, size_t err_buf_len, const char* msg);
    char* dup_string(const std::string& s);
    stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len);
}

constexpr size_t W = stim::MAX_BITWORD_WIDTH;

struct DetSampler {
    stim::Circuit circuit;
    std::mt19937_64 rng;
};

struct MeasSampler {
    stim::Circuit circuit;
    stim::simd_bits<W> ref_sample;
    std::mt19937_64 rng;
};

extern "C" {

stimhs_result_t stimhs_circuit_compile_detector_sampler(stimhs_circuit_t c, stimhs_det_sampler_t* out,
                                                        char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        auto* sampler = new DetSampler{*circ, std::mt19937_64{}};
        *out = reinterpret_cast<stimhs_det_sampler_t>(sampler);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

void stimhs_det_sampler_free(stimhs_det_sampler_t s) {
    delete reinterpret_cast<DetSampler*>(s);
}

stimhs_result_t stimhs_det_sampler_sample(stimhs_det_sampler_t s, size_t num_shots,
                                          uint8_t** out_buffer, size_t* out_num_bytes,
                                          size_t* out_num_detectors, size_t* out_num_observables,
                                          char* err_buf, size_t err_buf_len) {
    try {
        auto* sampler = reinterpret_cast<DetSampler*>(s);
        auto result = stim::sample_batch_detection_events<W>(sampler->circuit, num_shots, sampler->rng);
        const auto& det_table = result.first;
        const auto& obs_table = result.second;

        auto stats = sampler->circuit.compute_stats();
        size_t num_dets = stats.num_detectors;
        size_t num_obs = stats.num_observables;

        // For simplicity, return detection events as one byte per bit.
        // Observable data is not returned in this initial version.
        size_t total_bits = num_dets * num_shots;
        size_t total_bytes = total_bits;
        uint8_t* buf = new uint8_t[total_bytes];

        for (size_t shot = 0; shot < num_shots; ++shot) {
            for (size_t det = 0; det < num_dets; ++det) {
                bool bit = det_table[det][shot];
                buf[shot * num_dets + det] = bit ? 1 : 0;
            }
        }

        *out_buffer = buf;
        *out_num_bytes = total_bytes;
        *out_num_detectors = num_dets;
        *out_num_observables = num_obs;
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_circuit_compile_measurement_sampler(stimhs_circuit_t c, stimhs_meas_sampler_t* out,
                                                           char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        stim::simd_bits<W> ref_sample = stim::TableauSimulator<W>::reference_sample_circuit(*circ);
        auto* sampler = new MeasSampler{*circ, std::move(ref_sample), std::mt19937_64{}};
        *out = reinterpret_cast<stimhs_meas_sampler_t>(sampler);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

void stimhs_meas_sampler_free(stimhs_meas_sampler_t s) {
    delete reinterpret_cast<MeasSampler*>(s);
}

stimhs_result_t stimhs_meas_sampler_sample(stimhs_meas_sampler_t s, size_t num_shots,
                                           uint8_t** out_buffer, size_t* out_num_bytes,
                                           size_t* out_num_measurements,
                                           char* err_buf, size_t err_buf_len) {
    try {
        auto* sampler = reinterpret_cast<MeasSampler*>(s);
        auto table = stim::sample_batch_measurements<W>(
            sampler->circuit, sampler->ref_sample, num_shots, sampler->rng, false);

        size_t num_meas = sampler->circuit.count_measurements();
        size_t total_bits = num_meas * num_shots;
        size_t total_bytes = total_bits;
        uint8_t* buf = new uint8_t[total_bytes];

        for (size_t shot = 0; shot < num_shots; ++shot) {
            for (size_t meas = 0; meas < num_meas; ++meas) {
                bool bit = table[meas][shot];
                buf[shot * num_meas + meas] = bit ? 1 : 0;
            }
        }

        *out_buffer = buf;
        *out_num_bytes = total_bytes;
        *out_num_measurements = num_meas;
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

} // extern "C"
