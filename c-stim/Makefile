# Stim C Compatibility Layer Makefile
# Builds libstimhs.a from vendored Stim sources + our C shims.

VENDOR_DIR := ../vendor/stim
STIM_SRC_DIR := $(VENDOR_DIR)/src
STIM_FILE_LIST := $(VENDOR_DIR)/file_lists/source_files_no_main

CXX := g++
AR := ar
CXXFLAGS := -std=c++20 -O3 -Wall -Wpedantic -fno-strict-aliasing -fPIC -I$(STIM_SRC_DIR) -Iinclude

# Detect SIMD capability for -march flag
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    CXXFLAGS += -march=native
endif
ifeq ($(OS),Windows_NT)
    CXXFLAGS += -march=native
endif

# Stim source files (read from upstream file list, prefix with vendor dir)
STIM_SOURCES := $(shell cat $(STIM_FILE_LIST) | sed 's|^src/|$(STIM_SRC_DIR)/src/|')
# Adjust: file list uses paths like src/stim.cc relative to vendor root
STIM_SOURCES := $(shell cat $(STIM_FILE_LIST) | sed 's|^|$(VENDOR_DIR)/|')

# Our shim sources
SHIM_SOURCES := $(wildcard src/*.cpp)

# All object files
BUILD_DIR := build
STIM_OBJS := $(patsubst $(VENDOR_DIR)/%,$(BUILD_DIR)/stim/%.o,$(STIM_SOURCES))
SHIM_OBJS := $(patsubst src/%.cpp,$(BUILD_DIR)/shim/%.o,$(SHIM_SOURCES))
ALL_OBJS := $(STIM_OBJS) $(SHIM_OBJS)

TARGET := libstimhs.a

.PHONY: all clean dirs check-vendor

all: dirs check-vendor $(TARGET)

dirs:
	@mkdir -p $(BUILD_DIR)/stim $(BUILD_DIR)/shim

check-vendor:
	@if [ ! -f "$(STIM_FILE_LIST)" ]; then \
		echo "ERROR: vendor/stim is missing. Run: git submodule update --init --recursive"; \
		exit 1; \
	fi

$(TARGET): $(ALL_OBJS)
	$(AR) rcs $@ $^

# Pattern rule for Stim vendor sources
$(BUILD_DIR)/stim/%.cc.o: $(VENDOR_DIR)/%.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Pattern rule for our shim sources
$(BUILD_DIR)/shim/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

# Print source list for debugging
print-sources:
	@echo "=== Stim sources ==="
	@echo $(STIM_SOURCES) | tr ' ' '\n'
	@echo "=== Shim sources ==="
	@echo $(SHIM_SOURCES) | tr ' ' '\n'
