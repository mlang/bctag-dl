{-# LANGUAGE OverloadedStrings #-}
module Bandcamp (Album(..), albumsWithTags) where

import Control.Lens
import Control.Monad
import Data.Aeson
import Data.Aeson.Lens
import Data.Aeson.Types
import Data.Text
import Data.Vector as V
import Network.Wreq

digDeeper :: [Text] -> Int -> IO (Response Value)
digDeeper tags page = asJSON =<< post "https://bandcamp.com/api/hub/2/dig_deeper" d
 where
  d = object [("filters", f), ("page", Number . fromIntegral $ page)]
  f = object [ ("format", "all"), ("location", Number 0), ("sort", "pop")
             , ("tags", Array . V.fromList $ String <$> tags)
             ]

data Album = Album {
  subdomain :: Text
, slug :: Text
, artist :: Text
, title :: Text
, url :: Text 
} deriving (Eq, Show)

albumsWithTags :: [Text] -> IO [Album]
albumsWithTags s = V.toList . V.mapMaybe album <$> go 1 where
  album = parseMaybe . withObject "Album" $ \obj ->
    Album <$> obj .: "subdomain"
          <*> obj .: "slug_text"
          <*> obj .: "artist"
          <*> obj .: "title"
          <*> obj .: "tralbum_url"
  go n = do
    r <- digDeeper s n
    case r ^? responseBody . key "items" of
      Just (Array items) -> case r ^? responseBody . key "more_available" of
        Just (Bool True) -> (items <>) <$!> go (n + 1)
        _ -> pure items
      _ -> pure mempty

