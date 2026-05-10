#ifndef STIMHS_H
#define STIMHS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define STIMHS_OK 0
#define STIMHS_ERR_UNKNOWN 1
#define STIMHS_ERR_BAD_ARG 2
#define STIMHS_ERR_OOM 3

typedef int stimhs_result_t;

/* Opaque handles */
typedef struct stimhs_circuit* stimhs_circuit_t;
typedef struct stimhs_tableau_sim* stimhs_tableau_sim_t;
typedef struct stimhs_tableau* stimhs_tableau_t;
typedef struct stimhs_det_sampler* stimhs_det_sampler_t;
typedef struct stimhs_meas_sampler* stimhs_meas_sampler_t;

/* ========== Error helpers ========== */
/* Returns a human-readable string for a result code. */
const char* stimhs_result_string(stimhs_result_t result);

/* ========== Circuit ========== */
stimhs_circuit_t stimhs_circuit_new(void);
void stimhs_circuit_free(stimhs_circuit_t c);
stimhs_result_t stimhs_circuit_clear(stimhs_circuit_t c, char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_h(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_cnot(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                           char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_m(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_mx(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                         char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_detector(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_observable_include(stimhs_circuit_t c, uint32_t observable_index,
                                                         const uint32_t* targets, size_t n,
                                                         char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_depolarize1(stimhs_circuit_t c, double prob,
                                                   const uint32_t* targets, size_t n,
                                                   char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_depolarize2(stimhs_circuit_t c, double prob,
                                                   const uint32_t* targets, size_t n,
                                                   char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_x_error(stimhs_circuit_t c, double prob,
                                               const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_z_error(stimhs_circuit_t c, double prob,
                                               const uint32_t* targets, size_t n,
                                               char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_mr(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                         char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_append_r(stimhs_circuit_t c, const uint32_t* targets, size_t n,
                                        char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_to_string(stimhs_circuit_t c, char** out_str,
                                         char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_circuit_from_string(const char* str, stimhs_circuit_t* out_c,
                                           char* err_buf, size_t err_buf_len);

/* ========== TableauSimulator ========== */
stimhs_tableau_sim_t stimhs_tableau_sim_new(size_t num_qubits, char* err_buf, size_t err_buf_len);
void stimhs_tableau_sim_free(stimhs_tableau_sim_t s);
stimhs_result_t stimhs_tableau_sim_do_h(stimhs_tableau_sim_t s, uint32_t target,
                                        char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_tableau_sim_do_cnot(stimhs_tableau_sim_t s, uint32_t control, uint32_t target,
                                           char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_tableau_sim_do_mz(stimhs_tableau_sim_t s, uint32_t target, uint8_t* out_result,
                                         char* err_buf, size_t err_buf_len);
stimhs_result_t stimhs_tableau_sim_current_tableau(stimhs_tableau_sim_t s, stimhs_tableau_t* out_t,
                                                   char* err_buf, size_t err_buf_len);

/* ========== Tableau ========== */
void stimhs_tableau_free(stimhs_tableau_t t);
stimhs_result_t stimhs_tableau_to_string(stimhs_tableau_t t, char** out_str,
                                         char* err_buf, size_t err_buf_len);

/* ========== DetectorSampler ========== */
stimhs_result_t stimhs_circuit_compile_detector_sampler(stimhs_circuit_t c, stimhs_det_sampler_t* out,
                                                        char* err_buf, size_t err_buf_len);
void stimhs_det_sampler_free(stimhs_det_sampler_t s);
stimhs_result_t stimhs_det_sampler_sample(stimhs_det_sampler_t s, size_t num_shots,
                                          uint8_t** out_buffer, size_t* out_num_bytes,
                                          size_t* out_num_detectors, size_t* out_num_observables,
                                          char* err_buf, size_t err_buf_len);

/* ========== MeasurementSampler ========== */
stimhs_result_t stimhs_circuit_compile_measurement_sampler(stimhs_circuit_t c, stimhs_meas_sampler_t* out,
                                                           char* err_buf, size_t err_buf_len);
void stimhs_meas_sampler_free(stimhs_meas_sampler_t s);
stimhs_result_t stimhs_meas_sampler_sample(stimhs_meas_sampler_t s, size_t num_shots,
                                           uint8_t** out_buffer, size_t* out_num_bytes,
                                           size_t* out_num_measurements,
                                           char* err_buf, size_t err_buf_len);

/* ========== Buffers / Strings ========== */
void stimhs_buffer_free(uint8_t* buf);
void stimhs_string_free(char* str);

#ifdef __cplusplus
}
#endif

#endif /* STIMHS_H */
