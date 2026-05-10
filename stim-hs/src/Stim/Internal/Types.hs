{-# LANGUAGE StrictData #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Stim.Internal.Types
    ( StimCircuit
    , StimTableauSim
    , StimTableau
    , StimDetSampler
    , StimMeasSampler
    , Circuit (..)
    , TableauSimulator (..)
    , Tableau (..)
    , DetectorSampler (..)
    , MeasurementSampler (..)
    ) where

import Foreign

-- Foreign data tags (opaque to Haskell)
data StimCircuit
data StimTableauSim
data StimTableau
data StimDetSampler
data StimMeasSampler

newtype Circuit = Circuit (ForeignPtr StimCircuit)
    deriving (Eq, Ord)

newtype TableauSimulator = TableauSimulator (ForeignPtr StimTableauSim)
    deriving (Eq, Ord)

newtype Tableau = Tableau (ForeignPtr StimTableau)
    deriving (Eq, Ord)

newtype DetectorSampler = DetectorSampler (ForeignPtr StimDetSampler)
    deriving (Eq, Ord)

newtype MeasurementSampler = MeasurementSampler (ForeignPtr StimMeasSampler)
    deriving (Eq, Ord)
