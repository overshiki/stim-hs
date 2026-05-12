module Main where

import Data.List (isInfixOf)
import qualified Data.Vector.Storable as VS
import Test.Tasty
import Test.Tasty.HUnit
import Stim

main :: IO ()
main = defaultMain $ testGroup "stim-hs tests"
    [ testCase "Circuit construction and stringification" testCircuitConstruction
    , testCase "Circuit from string" testCircuitFromString
    , testCase "TableauSimulator" testTableauSimulator
    , testCase "MeasurementSampler" testMeasurementSampler
    , testCase "Circuit to Detector Error Model" testDetectorErrorModel
    , testCase "DetectorSampler with observables" testDetectorSamplerWithObservables
    , testCase "Surface code generation (text)" testSurfaceCodeText
    , testCase "Surface code generation (circuit)" testSurfaceCodeCircuit
    , testCase "Surface code generation with noise" testSurfaceCodeNoise
    ]

assertRight :: Either StimError a -> IO a
assertRight (Left err) = assertFailure (show err)
assertRight (Right x)  = return x

testCircuitConstruction :: Assertion
testCircuitConstruction = do
    circ <- circuitNew
    _ <- assertRight =<< appendH circ (VS.fromList [0])
    _ <- assertRight =<< appendCNOT circ (VS.fromList [0, 1])
    _ <- assertRight =<< appendM circ (VS.fromList [0, 1])
    s <- assertRight =<< circuitToString circ
    assertBool "Expected H gate" ("H 0" `isInfixOf` s)
    assertBool "Expected CNOT gate" ("CX 0 1" `isInfixOf` s)
    assertBool "Expected M gate" ("M 0 1" `isInfixOf` s)

testCircuitFromString :: Assertion
testCircuitFromString = do
    circ <- assertRight =<< circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    s <- assertRight =<< circuitToString circ
    assertBool "Expected H gate" ("H 0" `isInfixOf` s)
    assertBool "Expected CNOT gate" ("CX 0 1" `isInfixOf` s)
    assertBool "Expected M gate" ("M 0 1" `isInfixOf` s)

testTableauSimulator :: Assertion
testTableauSimulator = do
    sim <- assertRight =<< tableauSimNew 2
    _ <- assertRight =<< doH sim 0
    _ <- assertRight =<< doCNOT sim 0 1
    tab <- assertRight =<< currentTableau sim
    ts <- assertRight =<< tableauToString tab
    assertBool "Tableau should contain ZX" ("ZX" `isInfixOf` ts)

testMeasurementSampler :: Assertion
testMeasurementSampler = do
    circ <- assertRight =<< circuitFromString "H 0\nCNOT 0 1\nM 0 1"
    sampler <- assertRight =<< compileMeasurementSampler circ
    shots <- assertRight =<< sampleMeasurements sampler 10
    assertEqual "Num shots" 10 (shotDataNumShots shots)
    assertEqual "Num measurements" 2 (shotDataNumBits shots)
    assertEqual "Data length" 20 (VS.length (shotDataBytes shots))

testDetectorErrorModel :: Assertion
testDetectorErrorModel = do
    circ <- assertRight =<< circuitFromString "H 0\nCNOT 0 1\nM 0 1\nDETECTOR rec[-1] rec[-2]"
    dem <- assertRight =<< circuitToDetectorErrorModel circ
    assertBool "DEM should contain D0" ("D0" `isInfixOf` dem)

testDetectorSamplerWithObservables :: Assertion
testDetectorSamplerWithObservables = do
    circ <- assertRight =<< circuitFromString
        "H 0\nCNOT 0 1\nM 0 1\nDETECTOR rec[-1] rec[-2]\nOBSERVABLE_INCLUDE(0) rec[-1]"
    sampler <- assertRight =<< compileDetectorSampler circ
    (detShots, obsShots) <- assertRight =<< sampleDetectorsWithObservables sampler 10
    assertEqual "Detector shots" 10 (shotDataNumShots detShots)
    assertEqual "Detector bits" 1 (shotDataNumBits detShots)
    assertEqual "Detector data length" 10 (VS.length (shotDataBytes detShots))
    assertEqual "Observable shots" 10 (shotDataNumShots obsShots)
    assertEqual "Observable bits" 1 (shotDataNumBits obsShots)
    assertEqual "Observable data length" 10 (VS.length (shotDataBytes obsShots))

testSurfaceCodeText :: Assertion
testSurfaceCodeText = do
    txt <- assertRight =<< generateSurfaceCodeCircuitText
        (defaultSurfaceCodeParams RotatedMemoryZ 3 3)
    assertBool "Circuit should contain R gates" ("R" `isInfixOf` txt)
    assertBool "Circuit should contain M gates" ("M" `isInfixOf` txt)

testSurfaceCodeCircuit :: Assertion
testSurfaceCodeCircuit = do
    circ <- assertRight =<< generateSurfaceCodeCircuit
        (defaultSurfaceCodeParams UnrotatedMemoryX 2 2)
    s <- assertRight =<< circuitToString circ
    assertBool "Circuit should contain H gates" ("H" `isInfixOf` s)

testSurfaceCodeNoise :: Assertion
testSurfaceCodeNoise = do
    let noisyParams = (defaultSurfaceCodeParams RotatedMemoryZ 2 2)
            { scAfterCliffordDepolarization = 0.01
            , scBeforeMeasureFlipProbability = 0.001
            }
    noisyTxt <- assertRight =<< generateSurfaceCodeCircuitText noisyParams
    assertBool "Noisy circuit should contain DEPOLARIZE1"
        ("DEPOLARIZE1" `isInfixOf` noisyTxt || "X_ERROR" `isInfixOf` noisyTxt)
