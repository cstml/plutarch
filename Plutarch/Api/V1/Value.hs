{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Plutarch.Api.V1.Value (
  PValue (PValue),
  PCurrencySymbol (PCurrencySymbol),
  PTokenName (PTokenName),
  singleton,
  valueOf,
) where

import qualified Plutus.V1.Ledger.Api as Plutus

import Plutarch.Api.V1.AssocMap (PMap)
import qualified Plutarch.Api.V1.AssocMap as AssocMap
import Plutarch.Lift (
  DerivePConstantViaBuiltin (DerivePConstantViaBuiltin),
  DerivePConstantViaNewtype (DerivePConstantViaNewtype),
  PLifted,
  PUnsafeLiftDecl,
 )
import Plutarch.Unsafe (punsafeFrom)

import Plutarch.Prelude

newtype PTokenName (s :: S) = PTokenName (Term s PByteString)
  deriving (PlutusType, PIsData, PEq, POrd) via (DerivePNewtype PTokenName PByteString)

instance PUnsafeLiftDecl PTokenName where type PLifted PTokenName = Plutus.TokenName
deriving via
  (DerivePConstantViaBuiltin Plutus.TokenName PTokenName PByteString)
  instance
    (PConstant Plutus.TokenName)

newtype PCurrencySymbol (s :: S) = PCurrencySymbol (Term s PByteString)
  deriving (PlutusType, PIsData, PEq, POrd) via (DerivePNewtype PCurrencySymbol PByteString)

instance PUnsafeLiftDecl PCurrencySymbol where type PLifted PCurrencySymbol = Plutus.CurrencySymbol
deriving via
  (DerivePConstantViaBuiltin Plutus.CurrencySymbol PCurrencySymbol PByteString)
  instance
    (PConstant Plutus.CurrencySymbol)

newtype PValue (s :: S) = PValue (Term s (PMap PCurrencySymbol (PMap PTokenName PInteger)))
  deriving
    (PlutusType, PIsData)
    via (DerivePNewtype PValue (PMap PCurrencySymbol (PMap PTokenName PInteger)))

instance PUnsafeLiftDecl PValue where type PLifted PValue = Plutus.Value
deriving via
  (DerivePConstantViaNewtype Plutus.Value PValue (PMap PCurrencySymbol (PMap PTokenName PInteger)))
  instance
    (PConstant Plutus.Value)

-- | Construct a singleton 'PValue' containing only the given quantity of the given currency.
singleton :: Term (s :: S) (PCurrencySymbol :--> PTokenName :--> PInteger :--> PValue)
singleton = phoistAcyclic $
  plam $ \symbol token amount ->
    punsafeFrom (AssocMap.singleton # symbol #$ AssocMap.singleton # token # amount)

-- | Get the quantity of the given currency in the 'PValue'.
valueOf :: Term (s :: S) (PValue :--> PCurrencySymbol :--> PTokenName :--> PInteger)
valueOf = phoistAcyclic $
  plam $ \value symbol token ->
    pmatch (AssocMap.lookup # symbol # pto value) $ \case
      PNothing -> 0
      PJust submap -> pmatch (AssocMap.lookup # token # submap) $ \case
        PNothing -> 0
        PJust amount -> amount
