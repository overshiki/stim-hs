module Main where

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

    putStrLn "=== All tests passed! ==="
