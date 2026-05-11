{-# LANGUAGE ForeignFunctionInterface #-}

module Stim.Internal.FFI where

import Foreign
import Foreign.C
import Stim.Internal.Types

foreign import ccall safe "stimhs_circuit_new"
    c_stimhs_circuit_new :: IO (Ptr StimCircuit)

foreign import ccall safe "stimhs_circuit_free"
    c_stimhs_circuit_free :: Ptr StimCircuit -> IO ()

foreign import ccall safe "&stimhs_circuit_free"
    p_stimhs_circuit_free :: FunPtr (Ptr StimCircuit -> IO ())

foreign import ccall safe "stimhs_circuit_clear"
    c_stimhs_circuit_clear :: Ptr StimCircuit -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_h"
    c_stimhs_circuit_append_h :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_cnot"
    c_stimhs_circuit_append_cnot :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_m"
    c_stimhs_circuit_append_m :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_mx"
    c_stimhs_circuit_append_mx :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_detector"
    c_stimhs_circuit_append_detector :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_observable_include"
    c_stimhs_circuit_append_observable_include :: Ptr StimCircuit -> Word32 -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_depolarize1"
    c_stimhs_circuit_append_depolarize1 :: Ptr StimCircuit -> CDouble -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_depolarize2"
    c_stimhs_circuit_append_depolarize2 :: Ptr StimCircuit -> CDouble -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_x_error"
    c_stimhs_circuit_append_x_error :: Ptr StimCircuit -> CDouble -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_z_error"
    c_stimhs_circuit_append_z_error :: Ptr StimCircuit -> CDouble -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_mr"
    c_stimhs_circuit_append_mr :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_append_r"
    c_stimhs_circuit_append_r :: Ptr StimCircuit -> Ptr Word32 -> CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_to_string"
    c_stimhs_circuit_to_string :: Ptr StimCircuit -> Ptr CString -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_from_string"
    c_stimhs_circuit_from_string :: CString -> Ptr (Ptr StimCircuit) -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_circuit_to_detector_error_model"
    c_stimhs_circuit_to_detector_error_model :: Ptr StimCircuit -> Ptr CString -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_string_free"
    c_stimhs_string_free :: CString -> IO ()

-- TableauSimulator
foreign import ccall safe "stimhs_tableau_sim_new"
    c_stimhs_tableau_sim_new :: CSize -> Ptr CChar -> CSize -> IO (Ptr StimTableauSim)

foreign import ccall safe "stimhs_tableau_sim_free"
    c_stimhs_tableau_sim_free :: Ptr StimTableauSim -> IO ()

foreign import ccall safe "&stimhs_tableau_sim_free"
    p_stimhs_tableau_sim_free :: FunPtr (Ptr StimTableauSim -> IO ())

foreign import ccall safe "stimhs_tableau_sim_do_h"
    c_stimhs_tableau_sim_do_h :: Ptr StimTableauSim -> Word32 -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_tableau_sim_do_cnot"
    c_stimhs_tableau_sim_do_cnot :: Ptr StimTableauSim -> Word32 -> Word32 -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_tableau_sim_do_mz"
    c_stimhs_tableau_sim_do_mz :: Ptr StimTableauSim -> Word32 -> Ptr Word8 -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_tableau_sim_current_tableau"
    c_stimhs_tableau_sim_current_tableau :: Ptr StimTableauSim -> Ptr (Ptr StimTableau) -> Ptr CChar -> CSize -> IO CInt

-- Tableau
foreign import ccall safe "stimhs_tableau_free"
    c_stimhs_tableau_free :: Ptr StimTableau -> IO ()

foreign import ccall safe "&stimhs_tableau_free"
    p_stimhs_tableau_free :: FunPtr (Ptr StimTableau -> IO ())

foreign import ccall safe "stimhs_tableau_to_string"
    c_stimhs_tableau_to_string :: Ptr StimTableau -> Ptr CString -> Ptr CChar -> CSize -> IO CInt

-- DetectorSampler
foreign import ccall safe "stimhs_circuit_compile_detector_sampler"
    c_stimhs_circuit_compile_detector_sampler :: Ptr StimCircuit -> Ptr (Ptr StimDetSampler) -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_det_sampler_free"
    c_stimhs_det_sampler_free :: Ptr StimDetSampler -> IO ()

foreign import ccall safe "&stimhs_det_sampler_free"
    p_stimhs_det_sampler_free :: FunPtr (Ptr StimDetSampler -> IO ())

foreign import ccall safe "stimhs_det_sampler_sample"
    c_stimhs_det_sampler_sample :: Ptr StimDetSampler -> CSize -> Ptr (Ptr Word8) -> Ptr CSize -> Ptr CSize -> Ptr CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_det_sampler_sample_with_observables"
    c_stimhs_det_sampler_sample_with_observables :: Ptr StimDetSampler -> CSize -> Ptr (Ptr Word8) -> Ptr CSize -> Ptr CSize -> Ptr (Ptr Word8) -> Ptr CSize -> Ptr CSize -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_buffer_free"
    c_stimhs_buffer_free :: Ptr Word8 -> IO ()

-- MeasurementSampler
foreign import ccall safe "stimhs_circuit_compile_measurement_sampler"
    c_stimhs_circuit_compile_measurement_sampler :: Ptr StimCircuit -> Ptr (Ptr StimMeasSampler) -> Ptr CChar -> CSize -> IO CInt

foreign import ccall safe "stimhs_meas_sampler_free"
    c_stimhs_meas_sampler_free :: Ptr StimMeasSampler -> IO ()

foreign import ccall safe "&stimhs_meas_sampler_free"
    p_stimhs_meas_sampler_free :: FunPtr (Ptr StimMeasSampler -> IO ())

foreign import ccall safe "stimhs_meas_sampler_sample"
    c_stimhs_meas_sampler_sample :: Ptr StimMeasSampler -> CSize -> Ptr (Ptr Word8) -> Ptr CSize -> Ptr CSize -> Ptr CChar -> CSize -> IO CInt
