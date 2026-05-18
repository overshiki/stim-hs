module Stim.Circuit
    ( circuitNew
    , circuitFree
    , withCircuit
    , circuitClear
    , appendH
    , appendCNOT
    , appendM
    , appendMX
    , appendDetector
    , appendObservableInclude
    , appendDepolarize1
    , appendDepolarize2
    , appendXError
    , appendZError
    , appendMR
    , appendR
    , circuitToString
    , circuitFromString
    , circuitToDetectorErrorModel
    ) where

import Control.Exception (bracket)
import Foreign
import Foreign.C
import Data.Vector.Storable (Vector)
import qualified Data.Vector.Storable as VS


import Stim.Internal.Types
import Stim.Internal.FFI
import Stim.Internal.Memory
import Stim.Internal.Error
import Stim.Internal.CString

circuitNew :: IO Circuit
circuitNew = do
    ptr <- c_stimhs_circuit_new
    Circuit <$> newForeignPtr p_stimhs_circuit_free ptr

circuitFree :: Circuit -> IO ()
circuitFree (Circuit fp) = finalizeForeignPtr fp

withCircuit :: (Circuit -> IO a) -> IO a
withCircuit = bracket circuitNew circuitFree

circuitClear :: Circuit -> IO (Either StimError ())
circuitClear (Circuit fp) =
    withForeignPtr fp $ \ptr ->
        withErrorBuffer $ \errBuf errLen ->
            c_stimhs_circuit_clear ptr errBuf errLen

appendGate :: (Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt)
           -> Circuit -> Vector Word32 -> IO (Either StimError ())
appendGate c_fn (Circuit fp) targets =
    withForeignPtr fp $ \cPtr ->
        VS.unsafeWith targets $ \tPtr ->
            withErrorBuffer $ \errBuf errLen ->
                c_fn cPtr tPtr (fromIntegral (VS.length targets)) errBuf errLen

appendH :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendH = appendGate c_stimhs_circuit_append_h

appendCNOT :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendCNOT = appendGate c_stimhs_circuit_append_cnot

appendM :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendM = appendGate c_stimhs_circuit_append_m

appendMX :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendMX = appendGate c_stimhs_circuit_append_mx

appendDetector :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendDetector = appendGate c_stimhs_circuit_append_detector

appendObservableInclude :: Circuit -> Word32 -> Vector Word32 -> IO (Either StimError ())
appendObservableInclude (Circuit fp) obsIdx targets =
    withForeignPtr fp $ \cPtr ->
        VS.unsafeWith targets $ \tPtr ->
            withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_append_observable_include cPtr obsIdx tPtr (fromIntegral (VS.length targets)) errBuf errLen

appendGateProb :: (Ptr StimCircuit -> CDouble -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt)
               -> Circuit -> Double -> Vector Word32 -> IO (Either StimError ())
appendGateProb c_fn (Circuit fp) prob targets =
    withForeignPtr fp $ \cPtr ->
        VS.unsafeWith targets $ \tPtr ->
            withErrorBuffer $ \errBuf errLen ->
                c_fn cPtr (realToFrac prob) tPtr (fromIntegral (VS.length targets)) errBuf errLen

appendDepolarize1 :: Circuit -> Double -> Vector Word32 -> IO (Either StimError ())
appendDepolarize1 = appendGateProb c_stimhs_circuit_append_depolarize1

appendDepolarize2 :: Circuit -> Double -> Vector Word32 -> IO (Either StimError ())
appendDepolarize2 = appendGateProb c_stimhs_circuit_append_depolarize2

appendXError :: Circuit -> Double -> Vector Word32 -> IO (Either StimError ())
appendXError = appendGateProb c_stimhs_circuit_append_x_error

appendZError :: Circuit -> Double -> Vector Word32 -> IO (Either StimError ())
appendZError = appendGateProb c_stimhs_circuit_append_z_error

appendMR :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendMR = appendGate c_stimhs_circuit_append_mr

appendR :: Circuit -> Vector Word32 -> IO (Either StimError ())
appendR = appendGate c_stimhs_circuit_append_r

circuitToString :: Circuit -> IO (Either StimError String)
circuitToString (Circuit fp) =
    withForeignPtr fp $ \cPtr ->
        alloca $ \strPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_to_string cPtr strPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    cstr <- peek strPtr
                    str <- peekCString cstr
                    c_stimhs_string_free cstr
                    return (Right str)

circuitFromString :: String -> IO (Either StimError Circuit)
circuitFromString str =
    withCString str $ \cstr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_from_string cstr outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    ptr <- peek outPtr
                    circ <- Circuit <$> newForeignPtr p_stimhs_circuit_free ptr
                    return (Right circ)

-- | Compile a circuit to its Detector Error Model text representation.
--
-- The output is safe for consumption by external decoders and parsers:
-- it contains no @^@ correlated-error separators.
--
-- The parameters used internally are chosen for QEC decoder workloads:
-- decompose_errors=false (matches Stim Python's default), fold_loops=true,
-- allow_gauge_detectors=false,
-- approximate_disjoint_errors_threshold=1.0 (never merge disjoint errors),
-- ignore_decomposition_failures=false.
-- Only approximate_disjoint_errors_threshold differs from Python's defaults.
circuitToDetectorErrorModel :: Circuit -> IO (Either StimError String)
circuitToDetectorErrorModel (Circuit fp) =
    withForeignPtr fp $ \cPtr ->
        alloca $ \strPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_to_detector_error_model cPtr strPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    cstr <- peek strPtr
                    str <- peekCString cstr
                    c_stimhs_string_free cstr
                    return (Right str)
