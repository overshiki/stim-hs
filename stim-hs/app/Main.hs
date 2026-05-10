{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Word (Word8)
import qualified Data.Vector.Storable as VS
import Stim
import Control.Monad (forM_)

-- | Average number of detection events per shot.
avgDetections :: VS.Vector Word8 -> Int -> Int -> Double
avgDetections bytes numDets numShots =
    let total = sum [ fromIntegral (bytes VS.! (shot * numDets + det))
                    | shot <- [0..numShots-1], det <- [0..numDets-1] ]
    in total / fromIntegral numShots

-- | Print the detector pattern for a single shot.
printShot :: VS.Vector Word8 -> Int -> Int -> IO ()
printShot bytes numDets shotIdx = do
    let dets = [ bytes VS.! (shotIdx * numDets + d) | d <- [0..numDets-1] ]
    putStrLn $ "  Shot " ++ show shotIdx ++ ": " ++ show dets

-- | Build a distance-3 repetition code circuit as text.
repetitionCodeText :: Int -> Double -> String
repetitionCodeText rounds noiseProb = unlines $
    [ "R 0 1 2 3 4" ]
    ++ concatMap (roundText noiseProb) [1..rounds]
    ++ [ "M 0 1 2"
       , "DETECTOR rec[-1] rec[-2] rec[-3]"
       , "OBSERVABLE_INCLUDE(0) rec[-1] rec[-2] rec[-3]"
       ]

roundText :: Double -> Int -> [String]
roundText noiseProb _roundNum =
    [ "CX 0 3"
    , "CX 2 4"
    , "CX 1 3"
    , "CX 1 4"
    , "MR 3 4"
    , "DETECTOR rec[-1] rec[-2]"
    , "DEPOLARIZE1(" ++ show noiseProb ++ ") 0 1 2 3 4"
    ]

main :: IO ()
main = do
    putStrLn "============================================================"
    putStrLn "  stim-hs: Distance-3 Repetition Code Demo"
    putStrLn "============================================================"
    putStrLn ""

    -- Noiseless circuit
    putStrLn "[1] Parsing noiseless repetition code (2 rounds)..."
    Right circNoiseless <- circuitFromString (repetitionCodeText 2 0.0)

    putStrLn "[2] Sampling noiseless circuit (100 shots)..."
    Right samplerNoiseless <- compileDetectorSampler circNoiseless
    Right shotsNoiseless   <- sampleDetectors samplerNoiseless 100
    putStrLn $ "    Average detection events per shot (noiseless): "
            ++ show (avgDetections (shotDataBytes shotsNoiseless)
                                   (shotDataNumBits shotsNoiseless)
                                   (shotDataNumShots shotsNoiseless))

    putStrLn ""

    -- Noisy circuit parsed from text
    putStrLn "[3] Parsing noisy repetition code (2 rounds, 1% depolarizing noise)..."
    Right circNoisyText <- circuitFromString (repetitionCodeText 2 0.01)

    -- Additionally append extra noise programmatically
    _ <- appendDepolarize1 circNoisyText 0.005 (VS.fromList [0, 1, 2])
    putStrLn "    (Extra 0.5% depolarizing noise appended to data qubits)"

    putStrLn "[4] Sampling noisy circuit (1000 shots)..."
    Right samplerNoisy <- compileDetectorSampler circNoisyText
    Right shotsNoisy   <- sampleDetectors samplerNoisy 1000

    let bytesNoisy    = shotDataBytes shotsNoisy
        numDetsNoisy  = shotDataNumBits shotsNoisy
        numShotsNoisy = shotDataNumShots shotsNoisy
        avgNoisy      = avgDetections bytesNoisy numDetsNoisy numShotsNoisy

    putStrLn $ "    Number of detectors: " ++ show numDetsNoisy
    putStrLn $ "    Number of shots: " ++ show numShotsNoisy
    putStrLn $ "    Average detection events per shot (noisy): " ++ show avgNoisy
    putStrLn ""

    putStrLn "[5] First 10 noisy shots (detector event patterns):"
    forM_ [0..9] $ \i -> printShot bytesNoisy numDetsNoisy i

    putStrLn ""
    putStrLn "============================================================"
    putStrLn "  Demo complete."
    putStrLn "============================================================"
