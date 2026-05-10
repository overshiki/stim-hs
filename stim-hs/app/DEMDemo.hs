module Main where

import Data.List (isPrefixOf)
import Stim
import qualified Data.Vector.Storable as VS

-- | Distance-3 repetition code with 1% depolarizing noise (2 rounds).
-- | Remove duplicates while preserving order.
uniq :: Eq a => [a] -> [a]
uniq = foldr (\x acc -> if x `elem` acc then acc else x : acc) []

repetitionCode :: String
repetitionCode = unlines
    [ "RX 0 1 2"
    , "R 3 4"
    , "TICK"
    , "CX 0 3"
    , "CX 1 4"
    , "TICK"
    , "CX 2 3"
    , "CX 1 4"
    , "DEPOLARIZE1(0.01) 0 1 2 3 4"
    , "TICK"
    , "CX 0 3"
    , "CX 1 4"
    , "TICK"
    , "CX 2 3"
    , "CX 1 4"
    , "DEPOLARIZE1(0.01) 0 1 2 3 4"
    , "TICK"
    , "MX 0 1 2"
    , "M 3 4"
    , "DETECTOR rec[-5] rec[-3]"
    , "DETECTOR rec[-4] rec[-2]"
    , "OBSERVABLE_INCLUDE(0) rec[-1]"
    ]

main :: IO ()
main = do
    putStrLn "============================================================"
    putStrLn "  stim-hs: Detector Error Model (DEM) Demo"
    putStrLn "============================================================"
    putStrLn ""

    -- [1] Parse circuit
    putStrLn "[1] Parsing distance-3 repetition code with 1% depolarizing noise..."
    circResult <- circuitFromString repetitionCode
    circ <- case circResult of
        Left err -> error $ "Failed to parse circuit: " ++ show err
        Right c  -> return c

    -- [2] Show circuit text
    putStrLn ""
    putStrLn "[2] Circuit text:"
    circStrResult <- circuitToString circ
    case circStrResult of
        Left err -> error $ "Failed to stringify circuit: " ++ show err
        Right s  -> putStrLn s

    -- [3] Compile to DEM (the new feature)
    putStrLn "[3] Compiling circuit to Detector Error Model..."
    demResult <- circuitToDetectorErrorModel circ
    dem <- case demResult of
        Left err -> error $ "Failed to compile DEM: " ++ show err
        Right d  -> return d

    putStrLn "DEM text:"
    putStrLn dem

    -- [4] Light analysis of DEM text
    putStrLn "[4] DEM analysis:"
    let demLines = lines dem
        numErrors    = length $ filter ("error(" `isPrefixOf`) demLines
        -- Detectors and logicals are referenced inside error(...) lines,
        -- not declared separately in Stim's DEM format.
        detectorRefs = [ tok | line <- demLines, tok <- words line, "D" `isPrefixOf` tok, all (`elem` ('D':['0'..'9'])) tok ]
        logicalRefs  = [ tok | line <- demLines, tok <- words line, "L" `isPrefixOf` tok, all (`elem` ('L':['0'..'9'])) tok ]
        uniqueDets   = uniq detectorRefs
        uniqueLogs   = uniq logicalRefs
        errProbs     = [ read (takeWhile (/= ')') (drop 6 line)) :: Double
                       | line <- demLines
                       , "error(" `isPrefixOf` line
                       ]
    putStrLn $ "  Error mechanisms:     " ++ show numErrors
    putStrLn $ "  Unique detectors:     " ++ show uniqueDets
    putStrLn $ "  Unique logicals:      " ++ show uniqueLogs
    putStrLn $ "  Error probabilities:  " ++ show errProbs

    -- [5] Sample from circuit to show consistency
    putStrLn ""
    putStrLn "[5] Sampling 1000 shots from circuit sampler..."
    samplerResult <- compileDetectorSampler circ
    sampler <- case samplerResult of
        Left err -> error $ "Failed to compile sampler: " ++ show err
        Right s  -> return s

    shotsResult <- sampleDetectors sampler 1000
    shots <- case shotsResult of
        Left err -> error $ "Failed to sample: " ++ show err
        Right s  -> return s

    let avgDets :: Double
        avgDets = fromIntegral (VS.sum (shotDataBytes shots)) / fromIntegral (shotDataNumShots shots * shotDataNumBits shots)
    putStrLn $ "  Shots: " ++ show (shotDataNumShots shots)
    putStrLn $ "  Detectors per shot: " ++ show (shotDataNumBits shots)
    putStrLn $ "  Average detection events per shot: " ++ show avgDets

    putStrLn ""
    putStrLn "============================================================"
    putStrLn "  DEM Demo complete."
    putStrLn "============================================================"
