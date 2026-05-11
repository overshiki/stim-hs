module Main where

import Data.List (isInfixOf)
import qualified Data.Vector.Storable as VS
import Stim

main :: IO ()
main = do
    putStrLn "=== Test 1: Circuit construction and stringification ==="
    circ <- circuitNew
    _ <- appendH circ (VS.fromList [0])
    _ <- appendCNOT circ (VS.fromList [0, 1])
    _ <- appendM circ (VS.fromList [0, 1])
    strResult <- circuitToString circ
    case strResult of
        Left err -> error (show err)
        Right s -> putStrLn s

    putStrLn "=== Test 2: Circuit from string ==="
    circ2Result <- circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    case circ2Result of
        Left err -> error (show err)
        Right circ2 -> do
            str2Result <- circuitToString circ2
            case str2Result of
                Left err -> error (show err)
                Right s2 -> putStrLn s2

    putStrLn "=== Test 3: TableauSimulator ==="
    simResult <- tableauSimNew 2
    case simResult of
        Left err -> error (show err)
        Right sim -> do
            _ <- doH sim 0
            _ <- doCNOT sim 0 1
            tabResult <- currentTableau sim
            case tabResult of
                Left err -> error (show err)
                Right tab -> do
                    tabStrResult <- tableauToString tab
                    case tabStrResult of
                        Left err -> error (show err)
                        Right ts -> putStrLn ts

    putStrLn "=== Test 4: MeasurementSampler ==="
    circ3Result <- circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    case circ3Result of
        Left err -> error (show err)
        Right circ3 -> do
            samplerResult <- compileMeasurementSampler circ3
            case samplerResult of
                Left err -> error (show err)
                Right sampler -> do
                    shotResult <- sampleMeasurements sampler 10
                    case shotResult of
                        Left err -> error (show err)
                        Right shots -> do
                            putStrLn $ "Num shots: " ++ show (shotDataNumShots shots)
                            putStrLn $ "Num measurements: " ++ show (shotDataNumBits shots)
                            putStrLn $ "Data: " ++ show (shotDataBytes shots)

    putStrLn "=== Test 5: Circuit to Detector Error Model ==="
    circ4Result <- circuitFromString "H 0\nCNOT 0 1\nM 0 1\nDETECTOR rec[-1] rec[-2]"
    case circ4Result of
        Left err -> error (show err)
        Right circ4 -> do
            demResult <- circuitToDetectorErrorModel circ4
            case demResult of
                Left err -> error (show err)
                Right dem -> do
                    putStrLn dem
                    -- Basic sanity check: DEM should mention detector D0
                    if "D0" `isInfixOf` dem
                        then putStrLn "DEM contains D0."
                        else error "DEM missing expected D0 detector"

    putStrLn "=== Test 6: DetectorSampler with observables ==="
    circ5Result <- circuitFromString "H 0\nCNOT 0 1\nM 0 1\nDETECTOR rec[-1] rec[-2]\nOBSERVABLE_INCLUDE(0) rec[-1]"
    case circ5Result of
        Left err -> error (show err)
        Right circ5 -> do
            samplerResult <- compileDetectorSampler circ5
            case samplerResult of
                Left err -> error (show err)
                Right sampler -> do
                    shotResult <- sampleDetectorsWithObservables sampler 10
                    case shotResult of
                        Left err -> error (show err)
                        Right (detShots, obsShots) -> do
                            putStrLn $ "Detector shots: " ++ show (shotDataNumShots detShots)
                            putStrLn $ "Detector bits: " ++ show (shotDataNumBits detShots)
                            putStrLn $ "Detector data: " ++ show (shotDataBytes detShots)
                            putStrLn $ "Observable shots: " ++ show (shotDataNumShots obsShots)
                            putStrLn $ "Observable bits: " ++ show (shotDataNumBits obsShots)
                            putStrLn $ "Observable data: " ++ show (shotDataBytes obsShots)
                            -- Sanity checks
                            if shotDataNumShots detShots == 10
                                then putStrLn "Correct number of detector shots."
                                else error "Wrong number of detector shots"
                            if shotDataNumBits detShots == 1
                                then putStrLn "Correct number of detectors."
                                else error "Wrong number of detectors"
                            if shotDataNumShots obsShots == 10
                                then putStrLn "Correct number of observable shots."
                                else error "Wrong number of observable shots"
                            if shotDataNumBits obsShots == 1
                                then putStrLn "Correct number of observables."
                                else error "Wrong number of observables"

    putStrLn "=== All tests passed! ==="
