module Main where

import BasePrelude hiding ((&), writeFile)
import Control.Lens
import Data.Aeson.Lens
import Network.Linklater
import System.Directory

import Data.Text (Text)
import Data.Text.IO (writeFile)
import Network.Wai.Handler.Warp (run)

import qualified Data.ByteString as ByteString
import qualified Data.Text as Text
import qualified Network.Wreq as Wreq
import qualified System.Process as Process
import qualified System.IO.Temp as Temp

cleverlyReadFile :: FilePath -> IO Text
cleverlyReadFile filename =
  Text.filter (/= '\n') . Text.pack <$> readFile filename

imgurID = "cf41a92dd376e2f"

configIO :: IO Config
configIO =
  Config <$> (cleverlyReadFile "hook")

makeTemp :: IO FilePath
makeTemp = do
  Temp.createTempDirectory "/tmp" "mathbotXXXXXXXX"

expand :: Text -> FilePath
expand old = do
  Text.unpack (Text.replace "./" "/data/texbooth/" old)

copy :: Text -> FilePath -> IO ()
copy src dst = do
  copyFile (expand src) dst

write text dst = do
  writeFile dst text

shell :: FilePath -> Text -> IO (Either Text Text)
shell dir src = do
  cwd <- getCurrentDirectory
  setCurrentDirectory dir
  (code, out, error) <- Process.readProcessWithExitCode (expand src) [] ""
  setCurrentDirectory cwd
  case code of
    ExitSuccess ->
      return (Right (Text.pack out))
    _ ->
      return (Left (Text.pack error))

upload :: FilePath -> IO (Maybe Text)
upload src = do
  let params = Wreq.partFileSource "image" src
  let opts = Wreq.defaults & Wreq.header "Authorization" .~ ["Client-ID " <> imgurID]
  response <- Wreq.postWith opts "https://api.imgur.com/3/image" params
  return (response ^? (Wreq.responseBody . key "data" . key "link" . _String))

mathbot cmd@(Just (Command "math" user channel (Just text))) = do
  putStrLn ("+ Incoming command: " <> show cmd)
  tmp <- makeTemp
  copy "./src/template.tex" (tmp <> "/instance.tex")
  write text (tmp <> "/input.tex")
  shell tmp "./src/build.sh"
  url <- maybe "oh no imgur" id <$> (upload (tmp <> "/formula.png"))
  let formats = [FormatAt user, FormatString ("`" <> text <> "`"), FormatLink url url]
  config <- configIO
  say (FormattedMessage (EmojiIcon "goat") "mathbot" channel formats) config
  return "ok"

mathbot _ = do
  return "*beezorp* no math"

main :: IO ()
main = do
  putStrLn ("+ Listening on port " <> show port)
  run port (slashSimple mathbot)
  where
    port = 4446
