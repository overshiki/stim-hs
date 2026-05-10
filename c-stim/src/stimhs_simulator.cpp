#include "stimhs.h"
#include "stim/simulators/tableau_simulator.h"
#include "stim/circuit/circuit.h"
#include <random>

namespace stimhs {
    void write_err_buf(char* err_buf, size_t err_buf_len, const char* msg);
    char* dup_string(const std::string& s);
    stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len);
}

using TableauSim = stim::TableauSimulator<stim::MAX_BITWORD_WIDTH>;
using Tableau = stim::Tableau<stim::MAX_BITWORD_WIDTH>;

extern "C" {

stimhs_tableau_sim_t stimhs_tableau_sim_new(size_t num_qubits, char* err_buf, size_t err_buf_len) {
    try {
        auto* sim = new TableauSim(std::mt19937_64{}, num_qubits);
        return reinterpret_cast<stimhs_tableau_sim_t>(sim);
    } catch (...) {
        stimhs::catch_exceptions(err_buf, err_buf_len);
        return nullptr;
    }
}

void stimhs_tableau_sim_free(stimhs_tableau_sim_t s) {
    delete reinterpret_cast<TableauSim*>(s);
}

static void do_single_target_gate(TableauSim* sim, const char* gate_name, uint32_t target) {
    stim::Circuit tmp;
    tmp.safe_append_u(gate_name, {target});
    sim->safe_do_circuit(tmp);
}

stimhs_result_t stimhs_tableau_sim_do_h(stimhs_tableau_sim_t s, uint32_t target,
                                        char* err_buf, size_t err_buf_len) {
    try {
        auto* sim = reinterpret_cast<TableauSim*>(s);
        do_single_target_gate(sim, "H", target);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_tableau_sim_do_cnot(stimhs_tableau_sim_t s, uint32_t control, uint32_t target,
                                           char* err_buf, size_t err_buf_len) {
    try {
        auto* sim = reinterpret_cast<TableauSim*>(s);
        stim::Circuit tmp;
        tmp.safe_append_u("CNOT", {control, target});
        sim->safe_do_circuit(tmp);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_tableau_sim_do_mz(stimhs_tableau_sim_t s, uint32_t target, uint8_t* out_result,
                                         char* err_buf, size_t err_buf_len) {
    try {
        auto* sim = reinterpret_cast<TableauSim*>(s);
        auto result = sim->measure_kickback_z(stim::GateTarget::qubit(target));
        *out_result = result.first ? 1 : 0;
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

stimhs_result_t stimhs_tableau_sim_current_tableau(stimhs_tableau_sim_t s, stimhs_tableau_t* out_t,
                                                   char* err_buf, size_t err_buf_len) {
    try {
        auto* sim = reinterpret_cast<TableauSim*>(s);
        auto* t = new Tableau(sim->inv_state.inverse());
        *out_t = reinterpret_cast<stimhs_tableau_t>(t);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

void stimhs_tableau_free(stimhs_tableau_t t) {
    delete reinterpret_cast<Tableau*>(t);
}

stimhs_result_t stimhs_tableau_to_string(stimhs_tableau_t t, char** out_str,
                                         char* err_buf, size_t err_buf_len) {
    try {
        auto* tab = reinterpret_cast<Tableau*>(t);
        std::string s = tab->str();
        *out_str = stimhs::dup_string(s);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

} // extern "C"
