{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE OverloadedStrings #-}

import Protolude hiding (Down)

import Options.Applicative
import Control.Applicative

import qualified Data.Text as T
import qualified Data.Text.IO as T

import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty(..))

import Control.Arrow ((>>>))

data CommonOptions =
  CommonOptions
    { files :: NonEmpty FilePath
    , pkgs :: Text
    }
  deriving (Show)

newtype DockerComposeArgs =
  DockerComposeArgs { unDockerComposeArgs :: [Text] }

ensureConfigFile :: [FilePath] -> NonEmpty FilePath
ensureConfigFile []     = "./arion-compose.nix" :| []
ensureConfigFile (x:xs) = x :| xs

parseOptions :: Parser CommonOptions
parseOptions = do
    files <-
      ensureConfigFile <$>
        many (strOption
               (  short 'f'
               <> long "file"
               <> metavar "FILE"
               <> help "Use FILE instead of the default ./arion-compose.nix. \
                        \Can be specified multiple times for a merged configuration" ))
    pkgs <- T.pack <$> strOption
          (  short 'p'
          <> long "pkgs"
          <> metavar "EXPR"
          <> showDefault
          <> value "./arion-pkgs.nix"
          <> help "Use EXPR to get the Nixpkgs attrset used for bootstrapping \
                   \and evaluating the configuration." )
    pure CommonOptions{..}

parseCommand :: Parser (CommonOptions -> IO ())
parseCommand =
  hsubparser
    (    command "cat" (info (pure runCat) (progDesc "TODO: cat doc" <> fullDesc))
      <> command "repl" (info (pure runRepl) (progDesc "TODO: repl doc" <> fullDesc))
      <> command "exec" (info (pure runExec) (progDesc "TODO: exec doc" <> fullDesc))
    )
  <|>
  hsubparser
    (    commandDC runBuildAndDC "build" "Build or rebuild services"
      <> commandDC runBuildAndDC "bundle" "Generate a Docker bundle from the Compose file"
      <> commandDC runEvalAndDC "config" "Validate and view the Compose file"
      <> commandDC runBuildAndDC "create" "Create services"
      <> commandDC runEvalAndDC "down" "Stop and remove containers, networks, images, and volumes"
      <> commandDC runEvalAndDC "events" "Receive real time events from containers"
      <> commandDC runEvalAndDC "exec" "Execute a command in a running container"
      <> commandDC runDC "help" "Get help on a command"
      <> commandDC runEvalAndDC "images" "List images"
      <> commandDC runEvalAndDC "kill" "Kill containers"
      <> commandDC runEvalAndDC "logs" "View output from containers"
      <> commandDC runEvalAndDC "pause" "Pause services"
      <> commandDC runEvalAndDC "port" "Print the public port for a port binding"
      <> commandDC runEvalAndDC "ps" "List containers"
      <> commandDC runBuildAndDC "pull" "Pull service images"
      <> commandDC runBuildAndDC "push" "Push service images"
      <> commandDC runBuildAndDC "restart" "Restart services"
      <> commandDC runEvalAndDC "rm" "Remove stopped containers"
      <> commandDC runBuildAndDC "run" "Run a one-off command"
      <> commandDC runBuildAndDC "scale" "Set number of containers for a service"
      <> commandDC runBuildAndDC "start" "Start services"
      <> commandDC runEvalAndDC "stop" "Stop services"
      <> commandDC runEvalAndDC "top" "Display the running processes"
      <> commandDC runEvalAndDC "unpause" "Unpause services"
      <> commandDC runBuildAndDC "up" "Create and start containers"
      <> commandDC runDC "version" "Show the Docker-Compose version information"

      <> metavar "DOCKER-COMPOSE-COMMAND"
      <> commandGroup "Docker Compose Commands:"
    )

parseAll :: Parser (IO ())
parseAll =
  flip ($) <$> parseOptions <*> parseCommand

parseDockerComposeArgs :: Parser DockerComposeArgs
parseDockerComposeArgs =
  DockerComposeArgs <$>
    many (argument (T.pack <$> str) (metavar "DOCKER-COMPOSE ARGS..."))

commandDC
  :: (Text -> DockerComposeArgs -> CommonOptions -> IO ())
  -> Text
  -> Text
  -> Mod CommandFields (CommonOptions -> IO ())
commandDC run cmdStr help =
  command
    (T.unpack cmdStr)
    (info
      (run cmdStr <$> parseDockerComposeArgs)
      (progDesc (T.unpack help) <> fullDesc <> forwardOptions))

--------------------------------------------------------------------------------

modulesNixExpr :: NonEmpty FilePath -> Text
modulesNixExpr =
        NE.toList
    >>> fmap pathExpr
    >>> T.unwords
    >>> wrapList
  where
    pathExpr path | isAbsolute path = "(/. + \""  <> T.pack path <> "\")"
                  | otherwise       = "(./. + \"" <> T.pack path <> "\")"

    isAbsolute ('/':_) = True
    isAbsolute _       = False

    wrapList s = "[ " <> s <> " ]"

--------------------------------------------------------------------------------

runDC :: Text -> DockerComposeArgs -> CommonOptions -> IO ()
runDC cmd (DockerComposeArgs args) opts =
  T.putStrLn $ "TODO: docker-compose " <> cmd <> " " <> T.unwords args

runBuildAndDC :: Text -> DockerComposeArgs -> CommonOptions -> IO ()
runBuildAndDC cmd dopts opts = do
  T.putStrLn "TODO: build"
  runDC cmd dopts opts

runEvalAndDC :: Text -> DockerComposeArgs -> CommonOptions -> IO ()
runEvalAndDC cmd dopts opts = do
  T.putStrLn "TODO: eval"
  runDC cmd dopts opts

runCat :: CommonOptions -> IO ()
runCat (CommonOptions files pkgs) = do
  T.putStrLn "Running cat ... TODO"
  T.putStrLn (modulesNixExpr files)

runRepl :: CommonOptions -> IO ()
runRepl opts =
  T.putStrLn "Running repl ... TODO"

runExec :: CommonOptions -> IO ()
runExec opts =
  T.putStrLn "Running exec ... TODO"

main :: IO ()
main = 
  (join . execParser) (info (parseAll <**> helper) fullDesc)
  where
    execParser = customExecParser (prefs showHelpOnEmpty)

