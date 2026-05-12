#include "stimhs.h"
#include "stim/circuit/circuit.h"
#include "stim/gen/gen_surface_code.h"
#include <string>

namespace stimhs {
    char* dup_string(const std::string& s);
    stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len);
}

extern "C" {

stimhs_result_t stimhs_generate_surface_code_circuit_text(
    uint64_t rounds, uint32_t distance, const char* task,
    double after_clifford_depolarization,
    double before_round_data_depolarization,
    double before_measure_flip_probability,
    double after_reset_flip_probability,
    char** out_str, char* err_buf, size_t err_buf_len) {
    try {
        stim::CircuitGenParameters params(rounds, distance, std::string(task));
        params.after_clifford_depolarization = after_clifford_depolarization;
        params.before_round_data_depolarization = before_round_data_depolarization;
        params.before_measure_flip_probability = before_measure_flip_probability;
        params.after_reset_flip_probability = after_reset_flip_probability;
        params.validate_params();
        stim::GeneratedCircuit gen = stim::generate_surface_code_circuit(params);
        *out_str = stimhs::dup_string(gen.circuit.str());
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_generate_surface_code_circuit(
    uint64_t rounds, uint32_t distance, const char* task,
    double after_clifford_depolarization,
    double before_round_data_depolarization,
    double before_measure_flip_probability,
    double after_reset_flip_probability,
    stimhs_circuit_t* out_c, char* err_buf, size_t err_buf_len) {
    try {
        stim::CircuitGenParameters params(rounds, distance, std::string(task));
        params.after_clifford_depolarization = after_clifford_depolarization;
        params.before_round_data_depolarization = before_round_data_depolarization;
        params.before_measure_flip_probability = before_measure_flip_probability;
        params.after_reset_flip_probability = after_reset_flip_probability;
        params.validate_params();
        stim::GeneratedCircuit gen = stim::generate_surface_code_circuit(params);
        *out_c = reinterpret_cast<stimhs_circuit_t>(new stim::Circuit(gen.circuit));
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

} // extern "C"
