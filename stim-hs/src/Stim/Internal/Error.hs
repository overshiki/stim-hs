{-# LANGUAGE StrictData #-}

module Stim.Internal.Error
    ( StimError (..)
    , withErrorBuffer
    , withErrorBufferPtr
    ) where

import Control.Exception
import Foreign
import Foreign.C
import Data.Text (Text)
import qualified Data.Text as T

data StimError = StimError
    { stimErrorCode :: !Int
    , stimErrorMessage :: !Text
    } deriving (Eq, Show)

instance Exception StimError

errBufSize :: Int
errBufSize = 4096

withErrorBuffer :: (Ptr CChar -> CSize -> IO CInt) -> IO (Either StimError ())
withErrorBuffer action =
    allocaBytes errBufSize $ \errBuf -> do
        result <- action errBuf (fromIntegral errBufSize)
        if result == 0
            then return (Right ())
            else Left <$> readError result errBuf

checkResult :: IO CInt -> IO (Ptr CChar) -> IO (Either StimError ())
checkResult action getErrBuf = do
    result <- action
    if result == 0
        then return (Right ())
        else do
            errBuf <- getErrBuf
            Left <$> readError result errBuf

withErrorBufferPtr :: (Ptr CChar -> CSize -> IO (Ptr a)) -> IO (Either StimError (Ptr a))
withErrorBufferPtr action =
    allocaBytes errBufSize $ \errBuf -> do
        ptr <- action errBuf (fromIntegral errBufSize)
        if ptr == nullPtr
            then Left <$> readError 1 errBuf
            else return (Right ptr)

readError :: CInt -> Ptr CChar -> IO StimError
readError code errBuf = do
    msg <- peekCString errBuf
    return (StimError (fromIntegral code) (T.pack msg))
