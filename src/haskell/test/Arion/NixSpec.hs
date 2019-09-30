{-# LANGUAGE OverloadedStrings #-}
module Arion.NixSpec
  ( spec
  )
where

import           Protolude
import           Test.Hspec
import           Test.QuickCheck
import qualified Data.List.NonEmpty            as NEL
import           Arion.Aeson
import           Arion.Nix
import qualified Data.Text                     as T
import qualified Data.Text.IO                  as T
import qualified Data.Text.Lazy.IO             as TL
import qualified Data.Text.Lazy.Builder        as TB
import qualified Data.Aeson.Encode.Pretty
import Data.Char (isSpace)

spec :: Spec
spec = describe "evaluateComposition" $ it "matches an example" $ do
  x <- Arion.Nix.evaluateComposition EvaluationArgs
    { evalUid      = 123
    , evalModules  = NEL.fromList
                       ["src/haskell/testdata/Arion/NixSpec/arion-compose.nix"]
    , evalPkgs     = "import <nixpkgs> {}"
    , evalWorkDir  = Nothing
    , evalMode     = ReadOnly
    , evalUserArgs = ["--show-trace"]
    }
  let actual = pretty x
  expected <- T.readFile "src/haskell/testdata/Arion/NixSpec/arion-compose.json"
  censorPaths actual `shouldBe` censorPaths expected

censorPaths = censorImages . censorStorePaths
--censorPaths = censorStorePaths

censorStorePaths :: Text -> Text
censorStorePaths x = case T.breakOn "/nix/store/" x of
  (prefix, tl) | (tl :: Text) == "" -> prefix
  (prefix, tl) -> prefix <> "<STOREPATH>" <> censorPaths
    (T.dropWhile isNixNameChar $ T.drop (T.length "/nix/store/") tl)

-- Probably slow, due to not O(1) <>
censorImages :: Text -> Text
censorImages x = case T.break (\c -> c == ':' || c == '"') x of
  (prefix, tl) | tl == "" -> prefix
  (prefix, tl) | let imageId = T.take 33 (T.drop 1 tl)
               , T.last imageId == '\"'
                 -- Approximation of nix hash validation
               , T.all (\c -> (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z')) (T.take 32 imageId)
               -> prefix <> T.take 1 tl <> "<HASH>" <> censorImages (T.drop 33 tl)
  (prefix, tl) -> prefix <> T.take 1 tl <> censorImages (T.drop 1 tl)


-- | WARNING: THIS IS LIKELY WRONG: DON'T REUSE
isNixNameChar :: Char -> Bool
isNixNameChar c | c >= '0' && c <= '9' = True
isNixNameChar c | c >= 'a' && c <= 'z' = True
isNixNameChar c | c >= 'A' && c <= 'Z' = True
isNixNameChar c | c == '-' = True
isNixNameChar c | c == '.' = True
isNixNameChar c | c == '_' = True -- WRONG?
isNixNameChar c = False -- WRONG?
