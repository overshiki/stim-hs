# stim-hs

Haskell bindings for [Stim](https://github.com/quantumlib/Stim)—Google's high-performance stabilizer circuit simulator.

**stim-hs** provides safe, idiomatic Haskell bindings to [Stim](https://github.com/quantumlib/Stim)—Google's high-performance stabilizer circuit simulator and analyzer widely used in quantum error-correction (QEC) research.

---

## Table of Contents

- [Background](#background)
- [Methodology](#methodology)
- [Design](#design)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture Overview](#architecture-overview)
- [Status & Roadmap](#status--roadmap)
- [License](#license)

---

## Background

Quantum error correction is computationally demanding. Stabilizer circuit simulation—the backbone of most QEC research—requires manipulating thousands of qubits, millions of gates, and complex detector error models. Google's **Stim** has emerged as the de facto standard for this workload, offering a highly optimized C++ core with a Python frontend that feels almost NumPy-native.

Python's ecosystem for numerical and quantum computing is far more mature, with NumPy, SciPy, and Stim's own Python frontend providing a polished, batteries-included experience. Haskell, by contrast, lacks of established libraries for quantum error correction.

**stim-hs** fills that gap. By providing high-quality bindings to Stim, it gives Haskell developers access to the same high-performance stabilizer simulation that powers Python QEC research. This opens the door for type-safe, composable QEC application development in Haskell—from decoder prototypes to classical control software—without requiring a Python runtime.

---

## Methodology

### Learning from `stim-rs`

This project deliberately mirrors the architectural decisions of [`stim-rs`](https://github.com/inmzhang/stim-rs), a Rust binding to Stim that demonstrates how to wrap a large C++ codebase with rigorous engineering discipline:

- **Vendored upstream sources**: Stim is pinned as a git submodule for hermetic, reproducible builds.
- **Two-layer abstraction**: a thin, unsafe bridge layer and a thick, safe wrapper layer.
- **Automated parity auditing**: Python-based inventory scripts verify API coverage against upstream Python docs.

Where Haskell diverges is in the **bridge technology**. Rust has the transformative `cxx` crate for safe, bidirectional C++ interop. Haskell's FFI is fundamentally C-oriented. There is no `cxx` equivalent. Therefore, `stim-hs` adopts the time-tested **C-shim pattern**: a hand-written C compatibility layer that exposes Stim's C++ API through C-callable functions with opaque pointers.

---

## Design

### Two-Layer Architecture

```
┌─────────────────────────────────────┐
│  stim (Haskell)                     │
│  ├── Stim.Circuit                   │
│  ├── Stim.TableauSimulator          │
│  ├── Stim.Tableau                   │
│  ├── Stim.Sampler                   │
│  └── Stim.Types                     │
├─────────────────────────────────────┤
│  stim-c (C compatibility layer)     │
│  ├── stimhs_circuit_*               │
│  ├── stimhs_tableau_sim_*           │
│  ├── stimhs_det_sampler_*           │
│  └── stimhs_meas_sampler_*          │
├─────────────────────────────────────┤
│  vendor/stim (C++ upstream)         │
│  ├── stim::Circuit                  │
│  ├── stim::TableauSimulator<W>      │
│  ├── stim::FrameSimulator<W>        │
│  └── ...                            │
└─────────────────────────────────────┘
```

### Memory Management

Stim's C++ objects hold significant native memory. Haskell's tracing garbage collector has non-deterministic finalization. `stim-hs` therefore provides **dual resource management**:

- **`ForeignPtr` with finalizers**: a GC safety net that eventually frees the C++ object.
- **`bracket`-style explicit management**: deterministic `withCircuit`, `withTableauSim`, etc., for predictable memory usage in tight loops.

```haskell
import qualified Data.Vector.Storable as VS
import Stim

-- Deterministic cleanup
withCircuit $ \circ -> do
    _ <- appendH circ (VS.fromList [0])
    _ <- appendCNOT circ (VS.fromList [0, 1])
    circuitToString circ
```

### Error Handling

All fallible C++ operations are caught at the boundary and translated into Haskell `Either StimError a`:

```haskell
data StimError = StimError
    { stimErrorCode    :: !Int
    , stimErrorMessage :: !Text
    } deriving (Eq, Show)

instance Exception StimError
```

The C layer guarantees that **no C++ exceptions leak across the FFI boundary**. Every entry point is wrapped in a `try/catch(...)` firewall that writes a UTF-8 error message into a caller-provided buffer.

### Array Representation

Shot data and measurement results are returned as strict `Data.Vector.Storable.Vector Word8` for zero-copy interoperability with Haskell's numerical ecosystem. Future versions may add bit-packed or `massiv` integrations.

---

## Installation

### Prerequisites

- GHC 9.6+ and Cabal 3.10+
- C++20-capable compiler (`g++` or `clang++`)
- `make`
- `git` with submodule support

### Clone and Build

```bash
git clone --recurse-submodules https://github.com/overshiki/stim-hs.git
cd stim-hs

# Build the C compatibility layer
make -C c-stim

# Build the Haskell library
cd stim-hs && cabal build

# Run the practical QEC demo
cabal run stim-hs-demo
```

The custom `Setup.hs` automatically invokes `make -C c-stim` during configuration, so in many cases a single `cabal build` inside `stim/` is sufficient.

### Platform Notes

- **Linux**: tested with GCC 15 + GHC 9.6.7
- **macOS**: should work with `clang++` + `-stdlib=libc++`
- **Windows**: a `CMakeLists.txt` is provided in `c-stim/` for MSVC compatibility; MinGW via `make` is also supported

---

## Usage

### Circuit Construction

```haskell
{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Vector.Storable as VS
import Stim

bellCircuit :: IO (Either StimError Circuit)
bellCircuit = do
    circ <- circuitNew
    _ <- appendH circ (VS.fromList [0])
    _ <- appendCNOT circ (VS.fromList [0, 1])
    _ <- appendM circ (VS.fromList [0, 1])
    return (Right circ)
```

### Parsing from Text

```haskell
main :: IO ()
main = do
    Right circ <- circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    Right s    <- circuitToString circ
    putStrLn s
```

### Tableau Simulation

```haskell
main :: IO ()
main = withTableauSim 2 $ \sim -> do
    Right () <- doH sim 0
    Right () <- doCNOT sim 0 1
    Right tab <- currentTableau sim
    Right s   <- tableauToString tab
    putStrLn s
```

### Sampling Measurements

```haskell
main :: IO ()
main = do
    Right circ <- circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    Right sampler <- compileMeasurementSampler circ
    Right shots   <- sampleMeasurements sampler 100
    print (shotDataBytes shots)
```

### Practical Demo: Repetition Code with Noise

A runnable demo is included in `stim-hs/app/Main.hs`. It constructs a distance-3 repetition code, adds depolarizing noise, samples detection events, and prints statistics:

```bash
cd stim-hs && cabal run stim-hs-demo
```

Sample output:
```
============================================================
  stim-hs: Distance-3 Repetition Code Demo
============================================================

[1] Parsing noiseless repetition code (2 rounds)...
[2] Sampling noiseless circuit (100 shots)...
    Average detection events per shot (noiseless): 0.0

[3] Parsing noisy repetition code (2 rounds, 1% depolarizing noise)...
    (Extra 0.5% depolarizing noise appended to data qubits)
[4] Sampling noisy circuit (1000 shots)...
    Number of detectors: 3
    Number of shots: 1000
    Average detection events per shot (noisy): 5.7e-2
```

### Error Handling

Every effectful operation returns `IO (Either StimError a)`. You can handle errors explicitly or use the convenience functions that throw:

```haskell
-- Explicit
result <- circuitFromString "invalid gate"
case result of
    Left err  -> putStrLn $ "Error: " ++ show err
    Right circ -> print circ

-- Throwing variant (would need to be defined in your app)
fromStringOrDie :: String -> IO Circuit
fromStringOrDie s = circuitFromString s >>= either throwIO return
```

---

## Architecture Overview

| Component | Technology | Responsibility |
|-----------|-----------|----------------|
| `vendor/stim` | Git submodule (C++20) | Upstream Stim sources, pinned to a stable release |
| `c-stim/` | C++ + C headers | Opaque-pointer C API, exception firewalls, buffer marshaling |
| `c-stim/Makefile` | GNU Make | Compiles `libstimhs.a` from vendored sources + shims |
| `stim/Setup.hs` | Custom Cabal setup | Builds C layer, injects absolute lib/include paths |
| `stim/src/Stim/Internal/` | Raw FFI | `ForeignPtr` newtypes, `withErrorBuffer`, `CString` helpers |
| `stim/src/Stim/` | Public API | Safe, `IO`-based, `Vector.Storable`-aware Haskell interface |

### Key Design Decisions

1. **No `cxx` equivalent**: Haskell lacks a `cxx`-like bridge. The C-shim route is the only production-viable path.
2. **Static `libstdc++` linking**: vendored C++ is compiled with a modern toolchain; `ld-options` embed the static archive to avoid runtime dependency mismatches.
3. **`IO` for all mutation**: Stim objects are inherently stateful. A pure fiction would destroy performance by copying C++ objects on every gate append.
4. **`safe` FFI calls**: CPU-bound Stim operations may take milliseconds to seconds; `foreign import ccall safe` allows other Haskell threads to run.

---

## Status & Roadmap

**Current status (v0.1.0)**:
- ✅ Core types: `Circuit`, `TableauSimulator`, `Tableau`
- ✅ Basic gate appending: `H`, `CNOT`, `M`, `MX`, `DETECTOR`, `OBSERVABLE_INCLUDE`
- ✅ String round-tripping: `circuitToString` / `circuitFromString`
- ✅ Measurement sampling via `CompiledMeasurementSampler`
- ✅ Detector sampling via `CompiledDetectorSampler`
- ✅ DetectorErrorModel` (DEM) construction and sampling

**Near-term roadmap**:
- [ ] `PauliString` and `Flow` types
- [ ] I/O for Stim shot data formats (`b8`, `r8`, `dets`, etc.)
- [ ] Hackage release

---

## License

Licensed under Apache-2.0. The vendored upstream Stim sources under `vendor/stim` are also distributed under Apache-2.0.

---

*This project is under active development. Issues and pull requests are welcome.*
