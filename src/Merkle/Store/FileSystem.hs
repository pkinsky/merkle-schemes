module Merkle.Store.FileSystem where

--------------------------------------------
import           Control.Exception.Safe (MonadThrow, throwString)
import           Control.Monad.Except
import qualified Data.Aeson as AE
import qualified Data.Aeson.Encoding as AE (encodingToLazyByteString)
import qualified Data.ByteString.Lazy as BL
import           Data.Functor.Const
import           Data.Text (unpack)
import           System.Directory (doesFileExist)
--------------------------------------------
import           Merkle.Store
import           Merkle.Types
--------------------------------------------

-- | Filesystem backed store using the provided dir
fsStore
  :: forall m f
   . ( MonadIO m
     , MonadThrow m
     , Functor f
     , Hashable f
     , AE.ToJSON1   f
     , AE.FromJSON1 f
     )
  => FilePath
  -> ShallowStore m f
fsStore root
  = ShallowStore
  { ssDeref = \p -> do
      let fp = root ++ "/" ++ fn p
      exists <- liftIO $ doesFileExist fp
      if not exists
        then pure Nothing
        else liftIO $ AE.eitherDecodeFileStrict fp >>= \case
            -- throw if deserialization fails
            Left  e -> throwString e
            Right (HashTerm x) -> pure $ Just x

  , ssUploadShallow = \x -> do
      let p = hash x
      liftIO . BL.writeFile (root ++ "/" ++ fn p)
             . AE.encodingToLazyByteString
             . AE.toEncoding
             $ HashTerm x
      pure p
  }
  where
    fn :: Hash i -> String
    fn = unpack . hashToText . getConst
