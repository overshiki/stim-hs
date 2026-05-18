#include "stimhs.h"
#include "stim/circuit/circuit.h"
#include "stim/simulators/error_analyzer.h"
#include <string>

namespace stimhs {
    char* dup_string(const std::string& s);
    stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len);
}

extern "C" {

/* Compile a circuit to its Detector Error Model string representation.
 *
 * Parameters chosen for QEC decoder workloads (CPT-BP use case):
 *   - decompose_errors=false: matches Stim Python's default; avoids '^'
 *     separator syntax that external parsers typically cannot handle
 *   - fold_loops=true: unrolls REPEAT blocks for full expansion
 *   - allow_gauge_detectors=false: rejects circuits with gauge detectors
 *   - approximate_disjoint_errors_threshold=1.0: never merge disjoint errors
 *     (conservative, preserves full error information)
 *   - ignore_decomposition_failures=false: fail loudly on undecomposed errors
 *   - block_decomposition_from_introducing_remnant_edges=false
 *
 * Note: approximate_disjoint_errors_threshold=1.0 differs from Stim Python's
 * default of false. A future extended API may expose all parameters.
 */
stimhs_result_t stimhs_circuit_to_detector_error_model(
    stimhs_circuit_t c, char** out_str,
    char* err_buf, size_t err_buf_len) {
    try {
        auto* circ = reinterpret_cast<stim::Circuit*>(c);
        stim::DetectorErrorModel dem =
            stim::ErrorAnalyzer::circuit_to_detector_error_model(
                *circ,
                /*decompose_errors=*/false,
                /*fold_loops=*/true,
                /*allow_gauge_detectors=*/false,
                /*approximate_disjoint_errors_threshold=*/1.0,
                /*ignore_decomposition_failures=*/false,
                /*block_decomposition_from_introducing_remnant_edges=*/false);
        std::string s = dem.str();
        *out_str = stimhs::dup_string(s);
        return STIMHS_OK;
    } catch (...) {
        return stimhs::catch_exceptions(err_buf, err_buf_len);
    }
}

} // extern "C"
