module Stim.Internal.Memory
    ( withForeignPtrMaybe
    , newStimObject
    ) where

import Foreign

withForeignPtrMaybe :: ForeignPtr a -> (Ptr a -> IO b) -> IO b
withForeignPtrMaybe fp action = withForeignPtr fp action

newStimObject :: IO (Ptr a) -> FunPtr (Ptr a -> IO ()) -> IO (ForeignPtr a)
newStimObject constructor finalizer = do
    ptr <- constructor
    if ptr == nullPtr
        then fail "stim-hs: constructor returned null pointer"
        else newForeignPtr finalizer ptr
