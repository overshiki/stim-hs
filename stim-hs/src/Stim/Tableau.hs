module Stim.Tableau
    ( tableauToString
    , tableauFree
    ) where

import Foreign
import Foreign.C

import Stim.Internal.Types
import Stim.Internal.FFI
import Stim.Internal.Error

tableauToString :: Tableau -> IO (Either StimError String)
tableauToString (Tableau fp) =
    withForeignPtr fp $ \ptr ->
        alloca $ \strPtr -> do
            result <- withErrorBuffer $ \errBuf errLen ->
                c_stimhs_tableau_to_string ptr strPtr errBuf errLen
            case result of
                Left err -> return (Left err)
                Right () -> do
                    cstr <- peek strPtr
                    str <- peekCString cstr
                    c_stimhs_string_free cstr
                    return (Right str)

tableauFree :: Tableau -> IO ()
tableauFree (Tableau fp) = finalizeForeignPtr fp
