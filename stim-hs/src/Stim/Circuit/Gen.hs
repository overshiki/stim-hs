{-# LANGUAGE StrictData #-}

module Stim.Circuit.Gen
    ( SurfaceCodeTask (..)
    , SurfaceCodeParams (..)
    , defaultSurfaceCodeParams
    , generateSurfaceCodeCircuit
    , generateSurfaceCodeCircuitText
    ) where

import Foreign
import Foreign.C

import Stim.Internal.Types
import Stim.Internal.FFI
import Stim.Internal.Error

-- | Surface code tasks supported by Stim.
data SurfaceCodeTask
    = RotatedMemoryX
    | RotatedMemoryZ
    | UnrotatedMemoryX
    | UnrotatedMemoryZ
    deriving (Eq, Show)

taskToString :: SurfaceCodeTask -> String
taskToString RotatedMemoryX   = "rotated_memory_x"
taskToString RotatedMemoryZ   = "rotated_memory_z"
taskToString UnrotatedMemoryX = "unrotated_memory_x"
taskToString UnrotatedMemoryZ = "unrotated_memory_z"

-- | Parameters for surface code circuit generation.
data SurfaceCodeParams = SurfaceCodeParams
    { scRounds :: !Int
      -- ^ Number of rounds of syndrome extraction.
    , scDistance :: !Int
      -- ^ Code distance.
    , scTask :: !SurfaceCodeTask
      -- ^ Surface code task variant.
    , scAfterCliffordDepolarization :: !Double
      -- ^ Depolarization probability after each Clifford gate.
    , scBeforeRoundDataDepolarization :: !Double
      -- ^ Depolarization probability applied to data qubits at the start of each round.
    , scBeforeMeasureFlipProbability :: !Double
      -- ^ Bit-flip probability applied immediately before measurements.
    , scAfterResetFlipProbability :: !Double
      -- ^ Bit-flip probability applied immediately after resets.
    } deriving (Eq, Show)

-- | Default parameters with zero noise.
defaultSurfaceCodeParams :: SurfaceCodeTask -> Int -> Int -> SurfaceCodeParams
defaultSurfaceCodeParams task rounds distance = SurfaceCodeParams
    { scRounds = rounds
    , scDistance = distance
    , scTask = task
    , scAfterCliffordDepolarization = 0
    , scBeforeRoundDataDepolarization = 0
    , scBeforeMeasureFlipProbability = 0
    , scAfterResetFlipProbability = 0
    }

-- | Generate a surface code circuit as a 'Circuit' value.
generateSurfaceCodeCircuit :: SurfaceCodeParams -> IO (Either StimError Circuit)
generateSurfaceCodeCircuit params =
    withCString (taskToString (scTask params)) $ \taskStr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_generate_surface_code_circuit
                    (fromIntegral (scRounds params))
                    (fromIntegral (scDistance params))
                    taskStr
                    (realToFrac (scAfterCliffordDepolarization params))
                    (realToFrac (scBeforeRoundDataDepolarization params))
                    (realToFrac (scBeforeMeasureFlipProbability params))
                    (realToFrac (scAfterResetFlipProbability params))
                    outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    ptr <- peek outPtr
                    circ <- Circuit <$> newForeignPtr p_stimhs_circuit_free ptr
                    return (Right circ)

-- | Generate a surface code circuit and return its text representation.
generateSurfaceCodeCircuitText :: SurfaceCodeParams -> IO (Either StimError String)
generateSurfaceCodeCircuitText params =
    withCString (taskToString (scTask params)) $ \taskStr ->
        alloca $ \strPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_generate_surface_code_circuit_text
                    (fromIntegral (scRounds params))
                    (fromIntegral (scDistance params))
                    taskStr
                    (realToFrac (scAfterCliffordDepolarization params))
                    (realToFrac (scBeforeRoundDataDepolarization params))
                    (realToFrac (scBeforeMeasureFlipProbability params))
                    (realToFrac (scAfterResetFlipProbability params))
                    strPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    cstr <- peek strPtr
                    str <- peekCString cstr
                    c_stimhs_string_free cstr
                    return (Right str)
