#include "stimhs.h"
#include "stim/circuit/circuit.h"
#include <vector>
#include <string>
#include <stdexcept>

namespace stimhs {
    void write_err_buf(char* err_buf, size_t err_buf_len, const char* msg);
    char* dup_string(const std::string& s);
    stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len);
}

extern "C" {

stimhs_circuit_t stimhs_circuit_new(void) {
    return reinterpret_cast<stimhs_circuit_t>(new stim::Circuit());
}

void stimhs_circuit_free(stimhs_circuit_t c) {
    delete reinterpret_cast<stim::Circuit*>(c);
}

stimhs_result_t stimhs_circuit_clear(stimhs_circuit_t c, char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        circ->clear();
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

static stimhs_result_t append_gate(stimhs_circuit_t c, const char* gate_name,
                                   const uint32_t* targets, size_t n,
                                   const std::vector<double>& args,
                                   char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        std::vector<uint32_t> targs(targets, targets + n);
        circ->safe_append_u(gate_name, targs, args);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_circuit_append_h(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len) {
    return append_gate(c, "H", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_cnot(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                           char* err_buf, size_t err_buf_len) {
    return append_gate(c, "CNOT", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_m(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len) {
    return append_gate(c, "M", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_mx(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                         char* err_buf, size_t err_buf_len) {
    return append_gate(c, "MX", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_detector(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len) {
    return append_gate(c, "DETECTOR", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_observable_include(stimhs_circuit_t c, uint32_t observable_index,
                                                         const uint32_t* targets, size_t n,
                                                         char* err_buf, size_t err_buf_len) {
    std::vector<double> args = { static_cast<double>(observable_index) };
    std::vector<uint32_t> targs(targets, targets + n);
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        circ->safe_append_u("OBSERVABLE_INCLUDE", targs, args);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

static stimhs_result_t append_gate_prob(stimhs_circuit_t c, const char* gate_name, double prob,
                                        const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        std::vector<uint32_t> targs(targets, targets + n);
        circ->safe_append_ua(gate_name, targs, prob);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_circuit_append_depolarize1(stimhs_circuit_t c, double prob,
                                                   const uint32_t* targets, size_t n,
                                                   char* err_buf, size_t err_buf_len) {
    return append_gate_prob(c, "DEPOLARIZE1", prob, targets, n, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_depolarize2(stimhs_circuit_t c, double prob,
                                                   const uint32_t* targets, size_t n,
                                                   char* err_buf, size_t err_buf_len) {
    return append_gate_prob(c, "DEPOLARIZE2", prob, targets, n, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_x_error(stimhs_circuit_t c, double prob,
                                               const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len) {
    return append_gate_prob(c, "X_ERROR", prob, targets, n, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_z_error(stimhs_circuit_t c, double prob,
                                               const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len) {
    return append_gate_prob(c, "Z_ERROR", prob, targets, n, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_mr(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                         char* err_buf, size_t err_buf_len) {
    return append_gate(c, "MR", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_append_r(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len) {
    return append_gate(c, "R", targets, n, {}, err_buf, err_buf_len);
}

stimhs_result_t stimhs_circuit_to_string(stimhs_circuit_t c, char** out_str,
                                         char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        std::string s = circ->str();
        *out_str = stimhs::dup_string(s);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_circuit_from_string(const char* str, stimhs_circuit_t* out_c,
                                           char* err_buf, size_t err_buf_len) {
    try {
        *out_c = reinterpret_cast<stimhs_circuit_t>(new stim::Circuit(str));
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

} // extern "C"
