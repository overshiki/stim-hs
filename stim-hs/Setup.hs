{-# LANGUAGE CPP #-}
import Distribution.Simple
import Distribution.Simple.Setup
import Distribution.Simple.LocalBuildInfo
import Distribution.PackageDescription
#if MIN_VERSION_Cabal(3,14,0)
import Distribution.Utils.Path (makeSymbolicPath)
#endif
import System.Process
import System.Exit
import System.Directory


main :: IO ()
main = defaultMainWithHooks simpleUserHooks
    { preConf = \args flags -> do
        let cStimDir = "../c-stim"
        exists <- doesDirectoryExist cStimDir
        if not exists
            then die ("ERROR: " ++ cStimDir ++ " not found. The C compatibility layer is required.")
            else do
                exitCode <- rawSystem "make" ["-C", cStimDir]
                case exitCode of
                    ExitSuccess -> return ()
                    ExitFailure n -> die ("ERROR: Failed to build C layer (exit code " ++ show n ++ ")")
        preConf simpleUserHooks args flags
    , confHook = \pd flags -> do
        lbi <- confHook simpleUserHooks pd flags
        cwd <- getCurrentDirectory
        let cStimDir = cwd ++ "/../c-stim"
            absCStimDir = cStimDir
#if MIN_VERSION_Cabal(3,14,0)
            libDir  = makeSymbolicPath absCStimDir
            incDir  = makeSymbolicPath (absCStimDir ++ "/include")
#else
            libDir  = absCStimDir
            incDir  = absCStimDir ++ "/include"
#endif
            updBI bi = bi
                { extraLibDirs = extraLibDirs bi ++ [libDir]
                , includeDirs = includeDirs bi ++ [incDir]
                , extraLibs = extraLibs bi ++ ["stimhs"]
                , ldOptions = ldOptions bi ++ ["/usr/local/lib64/libstdc++.a"]
                }
            updLib lib = lib { libBuildInfo = updBI (libBuildInfo lib) }
            updExe exe = exe { buildInfo = updBI (buildInfo exe) }
            oldPd = localPkgDescr lbi
            newPd = oldPd
                { library = fmap updLib (library oldPd)
                , executables = map updExe (executables oldPd)
                , testSuites = map (\ts -> ts { testBuildInfo = updBI (testBuildInfo ts) }) (testSuites oldPd)
                }
        return lbi { localPkgDescr = newPd }
    }
