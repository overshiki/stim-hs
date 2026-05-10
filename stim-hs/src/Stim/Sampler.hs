module Stim.Sampler
    ( ShotData (..)
    , compileDetectorSampler
    , detectorSamplerFree
    , sampleDetectors
    , compileMeasurementSampler
    , measurementSamplerFree
    , sampleMeasurements
    ) where

import Foreign
import Data.Vector.Storable (Vector)
import qualified Data.Vector.Storable as VS

import Stim.Internal.Types
import Stim.Internal.FFI
import Stim.Internal.Error

data ShotData = ShotData
    { shotDataNumShots :: !Int
    , shotDataNumBits  :: !Int
    , shotDataBytes    :: !(Vector Word8)
    } deriving (Eq, Show)

compileDetectorSampler :: Circuit -> IO (Either StimError DetectorSampler)
compileDetectorSampler (Circuit fp) =
    withForeignPtr fp $ \cPtr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_compile_detector_sampler cPtr outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    sPtr <- peek outPtr
                    sampler <- DetectorSampler <$> newForeignPtr p_stimhs_det_sampler_free sPtr
                    return (Right sampler)

detectorSamplerFree :: DetectorSampler -> IO ()
detectorSamplerFree (DetectorSampler fp) = finalizeForeignPtr fp

sampleDetectors :: DetectorSampler -> Int -> IO (Either StimError ShotData)
sampleDetectors (DetectorSampler fp) numShots =
    withForeignPtr fp $ \sPtr ->
        alloca $ \bufPtr ->
            alloca $ \bytesPtr ->
                alloca $ \detsPtr ->
                    alloca $ \obsPtr -> do
                        result <- withErrorBuffer $ \errBuf errLen ->
                            c_stimhs_det_sampler_sample sPtr (fromIntegral numShots) bufPtr bytesPtr detsPtr obsPtr errBuf errLen
                        case result of
                            Left err -> return (Left err)
                            Right () -> do
                                cbuf <- peek bufPtr
                                numBytes <- fromIntegral <$> peek bytesPtr
                                numDets <- fromIntegral <$> peek detsPtr
                                -- Copy data into a Haskell-managed Vector
                                vec <- VS.generateM numBytes (\i -> peekElemOff cbuf i)
                                c_stimhs_buffer_free cbuf
                                return (Right (ShotData numShots numDets vec))

compileMeasurementSampler :: Circuit -> IO (Either StimError MeasurementSampler)
compileMeasurementSampler (Circuit fp) =
    withForeignPtr fp $ \cPtr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_circuit_compile_measurement_sampler cPtr outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    sPtr <- peek outPtr
                    sampler <- MeasurementSampler <$> newForeignPtr p_stimhs_meas_sampler_free sPtr
                    return (Right sampler)

measurementSamplerFree :: MeasurementSampler -> IO ()
measurementSamplerFree (MeasurementSampler fp) = finalizeForeignPtr fp

sampleMeasurements :: MeasurementSampler -> Int -> IO (Either StimError ShotData)
sampleMeasurements (MeasurementSampler fp) numShots =
    withForeignPtr fp $ \sPtr ->
        alloca $ \bufPtr ->
            alloca $ \bytesPtr ->
                alloca $ \measPtr -> do
                    result <- withErrorBuffer $ \errBuf errLen ->
                        c_stimhs_meas_sampler_sample sPtr (fromIntegral numShots) bufPtr bytesPtr measPtr errBuf errLen
                    case result of
                        Left err -> return (Left err)
                        Right () -> do
                            cbuf <- peek bufPtr
                            numBytes <- fromIntegral <$> peek bytesPtr
                            numMeas <- fromIntegral <$> peek measPtr
                            vec <- VS.generateM numBytes (\i -> peekElemOff cbuf i)
                            c_stimhs_buffer_free cbuf
                            return (Right (ShotData numShots numMeas vec))
