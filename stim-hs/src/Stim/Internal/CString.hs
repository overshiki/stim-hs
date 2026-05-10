module Stim.Internal.CString
    ( withCStringText
    , peekCStringText
    , withCStringByteString
    ) where

import Foreign
import Foreign.C
import Data.Text (Text)
import qualified Data.Text.Foreign as TF
import qualified Data.ByteString as BS
import qualified Data.ByteString.Unsafe as BSU
import qualified Data.Text as T

withCStringText :: Text -> (CString -> IO a) -> IO a
withCStringText = TF.withCString

peekCStringText :: CString -> IO Text
peekCStringText cstr = T.pack <$> peekCString cstr

withCStringByteString :: BS.ByteString -> (CString -> IO a) -> IO a
withCStringByteString = BSU.unsafeUseAsCString
