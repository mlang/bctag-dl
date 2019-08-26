{-# LANGUAGE LambdaCase, NamedFieldPuns, OverloadedStrings #-}
module Main where

import Prelude hiding (concatMap)
import Bandcamp
import Control.Monad
import Data.Foldable
import Data.String
import Data.Text hiding (concatMap)
import System.Directory
import System.Environment (getArgs)
import System.Exit
import System.FilePath.Posix
import System.Process

main :: IO ()
main = do
  tags <- fmap fromString <$> getArgs
  traverse_ get =<< albumsWithTags tags

get :: Album -> IO ()
get a = shouldDownload a >>= \case
  True -> download a >>= \case
    ExitSuccess -> putStrLn $ "[bctag-dl] Downloaded " <> directory a
    ExitFailure _ -> putStrLn $ "[bctag-dl] Failed in " <> directory a
  False -> putStrLn $ "[bctag-dl] Skipping " <> directory a

shouldDownload :: Album -> IO Bool
shouldDownload = fmap not . doesDirectoryExist . directory

directory :: Album -> FilePath
directory Album{artist, title} = sanitize artist </> sanitize title

download :: Album -> IO ExitCode
download a@Album{url} = do
  let fp = directory a
  createDirectoryIfMissing True fp
  (_, _, _, h) <- createProcess (proc "youtube-dl" [unpack url]){ cwd = Just fp }
  waitForProcess h

sanitize :: Text -> FilePath
sanitize = concatMap f . unpack where
  f '/' = "_"
  f x = [x]
