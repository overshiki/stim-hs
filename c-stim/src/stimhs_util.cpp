#include "stimhs.h"
#include <cstring>
#include <string>
#include <stdexcept>
#include <new>

extern "C" {

const char* stimhs_result_string(stimhs_result_t result) {
    switch (result) {
        case STIMHS_OK: return "OK";
        case STIMHS_ERR_UNKNOWN: return "Unknown error";
        case STIMHS_ERR_BAD_ARG: return "Bad argument";
        case STIMHS_ERR_OOM: return "Out of memory";
        default: return "Invalid error code";
    }
}

void stimhs_buffer_free(uint8_t* buf) {
    delete[] buf;
}

void stimhs_string_free(char* str) {
    delete[] str;
}

} // extern "C"

namespace stimhs {

void write_err_buf(char* err_buf, size_t err_buf_len, const char* msg) {
    if (err_buf != nullptr && err_buf_len > 0) {
        std::strncpy(err_buf, msg, err_buf_len - 1);
        err_buf[err_buf_len - 1] = '\0';
    }
}

char* dup_string(const std::string& s) {
    char* out = new char[s.size() + 1];
    std::memcpy(out, s.c_str(), s.size() + 1);
    return out;
}

stimhs_result_t catch_exceptions(char* err_buf, size_t err_buf_len) {
    try {
        throw;
    } catch (const std::bad_alloc& e) {
        write_err_buf(err_buf, err_buf_len, e.what());
        return STIMHS_ERR_OOM;
    } catch (const std::invalid_argument& e) {
        write_err_buf(err_buf, err_buf_len, e.what());
        return STIMHS_ERR_BAD_ARG;
    } catch (const std::exception& e) {
        write_err_buf(err_buf, err_buf_len, e.what());
        return STIMHS_ERR_UNKNOWN;
    } catch (...) {
        write_err_buf(err_buf, err_buf_len, "unknown C++ exception");
        return STIMHS_ERR_UNKNOWN;
    }
}

} // namespace stimhs
