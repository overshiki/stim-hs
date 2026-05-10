module Stim.TableauSimulator
    ( tableauSimNew
    , tableauSimFree
    , withTableauSim
    , doH
    , doCNOT
    , doMZ
    , currentTableau
    ) where

import Control.Exception (bracket, throwIO)
import Foreign

import Stim.Internal.Types
import Stim.Internal.FFI
import Stim.Internal.Error

tableauSimNew :: Int -> IO (Either StimError TableauSimulator)
tableauSimNew numQubits = do
    result <- withErrorBufferPtr $ \errBuf errLen ->
        c_stimhs_tableau_sim_new (fromIntegral numQubits) errBuf errLen
    case result of
        Left err -> return (Left err)
        Right ptr -> Right . TableauSimulator <$> newForeignPtr p_stimhs_tableau_sim_free ptr

tableauSimFree :: TableauSimulator -> IO ()
tableauSimFree (TableauSimulator fp) = finalizeForeignPtr fp

withTableauSim :: Int -> (TableauSimulator -> IO a) -> IO a
withTableauSim n = bracket
    (do r <- tableauSimNew n; case r of Left e -> throwIO e; Right v -> return v)
    tableauSimFree

doH :: TableauSimulator -> Word32 -> IO (Either StimError ())
doH (TableauSimulator fp) target =
    withForeignPtr fp $ \ptr ->
        withErrorBuffer $ \errBuf errLen ->
            c_stimhs_tableau_sim_do_h ptr target errBuf errLen

doCNOT :: TableauSimulator -> Word32 -> Word32 -> IO (Either StimError ())
doCNOT (TableauSimulator fp) control target =
    withForeignPtr fp $ \ptr ->
        withErrorBuffer $ \errBuf errLen ->
            c_stimhs_tableau_sim_do_cnot ptr control target errBuf errLen

doMZ :: TableauSimulator -> Word32 -> IO (Either StimError Bool)
doMZ (TableauSimulator fp) target =
    withForeignPtr fp $ \ptr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_tableau_sim_do_mz ptr target outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    val <- peek outPtr
                    return (Right (val /= 0))

currentTableau :: TableauSimulator -> IO (Either StimError Tableau)
currentTableau (TableauSimulator fp) =
    withForeignPtr fp $ \ptr ->
        alloca $ \outPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_tableau_sim_current_tableau ptr outPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    tPtr <- peek outPtr
                    tab <- Tableau <$> newForeignPtr p_stimhs_tableau_free tPtr
                    return (Right tab)
