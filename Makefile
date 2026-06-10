# ============================================================================
# NT219 PQC Benchmark - Makefile  (Linux x86_64 / ARM aarch64)
# ----------------------------------------------------------------------------
# Builds the microbenchmark executable  build/bench_evp  from src/*.cpp,
# linking against a custom OpenSSL (>= 3.5) that provides ML-KEM / ML-DSA.
#
# Linking follows the official OpenSSL demos convention: dynamic link with
# -lcrypto, NO rpath baked in. To RUN the binary, put libcrypto on the
# library path first by sourcing scripts/setenv.sh:
#     source scripts/setenv.sh
#     ./build/bench_evp rsa 2048
#
# OpenSSL location is read automatically from scripts/versions.env
# (OSSL_PREFIX). Override with:  make OSSLROOT=/path/to/openssl
# Build a debug binary with:     make DEBUG=1
#
# Measurement helpers (call scripts/, do NOT affect how bench_evp is built):
#     make bench       # run the whole algorithm matrix -> data/summary_micro_<arch>.csv
#     make memory      # peak RSS per algorithm        -> data/memory_<arch>.csv
#     make codesize    # code size of crypto libraries -> data/codesize_<arch>.csv
# ============================================================================

# ---- Project layout --------------------------------------------------------
SRCDIR  := src
BINDIR  := build
EXEC    := $(BINDIR)/bench_evp
SOURCES := $(wildcard $(SRCDIR)/*.cpp)
OBJECTS := $(patsubst $(SRCDIR)/%.cpp,$(BINDIR)/%.o,$(SOURCES))

# ---- Toolchain and base flags ----------------------------------------------
# C++ standard is intentionally NOT pinned: modern g++ (GCC 11+) defaults to
# C++17.
# -pthread: enables POSIX threads correctly at BOTH compile and link time
#   (use this, not a bare -lpthread). Harmless if the code is single-threaded.
CXX      ?= g++
WARNINGS := -Wall
# Release = "RelWithDebInfo" for a benchmark:
#   -O3            full optimization (representative timing)
#   -g2            debug symbols -> profile with perf / get crash backtraces
#                  (symbols do NOT slow execution; they only enlarge the file)
#   -DNDEBUG       disable assert() -> clean release timing
RELEASE  := -O3 -g2 -DNDEBUG
# Debug = step through with a debugger (NOT for profiling: -O0 is unrepresentative)
DEBUGOPT := -g2 -O0

CXXFLAGS += $(WARNINGS) -pthread
LDFLAGS  += -pthread
LDLIBS   += -lcrypto -lm

# ---- Build mode: release (default) or debug (make DEBUG=1) -----------------
ifdef DEBUG
  CXXFLAGS += $(DEBUGOPT)
  LDFLAGS  += -g
else
  CXXFLAGS += $(RELEASE)
endif

# ---- OpenSSL location (single source of truth: scripts/versions.env) -------
# ROOT_DIR is the absolute directory of THIS Makefile, so `make` works from
# any working directory. OSSLROOT defaults to OSSL_PREFIX from versions.env.
ROOT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OSSLROOT ?= $(shell bash -c '. "$(ROOT_DIR)scripts/versions.env" 2>/dev/null && echo "$$OSSL_PREFIX"')

# Fail loudly if OpenSSL cannot be located, instead of silently linking the
# system OpenSSL (which may lack PQC and cause runtime crypto failures).
ifeq ($(strip $(OSSLROOT)),)
  $(error Cannot determine OSSLROOT. Run make from the repo root, or pass OSSLROOT=/path/to/openssl)
endif

# OpenSSL installs its libraries under lib/ or lib64/ depending on the build.
# Detect which one exists so the link-time -L points to the real directory.
ifneq ($(wildcard $(OSSLROOT)/lib64),)
  OSSLLIBDIR := $(OSSLROOT)/lib64
else
  OSSLLIBDIR := $(OSSLROOT)/lib
endif

# Header path (-I) and link-time library path (-L). No rpath: the OpenSSL
# library is found at RUN time via LD_LIBRARY_PATH (see scripts/setenv.sh),
# matching the official OpenSSL demos convention.
CPPFLAGS += -I$(OSSLROOT)/include
LDFLAGS  += -L$(OSSLLIBDIR)

# ---- Targets: build --------------------------------------------------------
.PHONY: all clean distclean
.DEFAULT_GOAL := all

all: $(EXEC)

# Link the executable from all object files (libraries last, as OpenSSL does).
$(EXEC): $(OBJECTS)
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@

# Compile each src/*.cpp into build/*.o (create build/ on demand).
$(BINDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(BINDIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Remove build artifacts.
clean:
	rm -rf $(BINDIR)

# Remove build artifacts plus generated analysis output.
distclean: clean
	rm -rf analysis_out *.log core

# ---- Targets: measurement helpers (WP5) ------------------------------------
# Thin wrappers over scripts/. They never change how bench_evp is compiled;
# the "per algorithm" view comes from arguments, exactly like the official
# liboqs speed_kem/speed_sig and `openssl speed` tools.
.PHONY: bench memory codesize

# Run the whole algorithm matrix -> raw CSVs + data/summary_micro_<arch>.csv
bench: $(EXEC)
	scripts/run_micro.sh

# Peak RSS per algorithm via GNU time -v -> data/memory_<arch>.csv
memory: $(EXEC)
	scripts/measure_memory.sh

# Code size of built crypto libraries via `size` -> data/codesize_<arch>.csv
codesize:
	scripts/measure_codesize.sh