module Merkle.Higher.Store.Deref where

--------------------------------------------
import           Data.Functor.Compose
--------------------------------------------
import           Util.HRecursionSchemes
import           Merkle.Higher.Functors
import           Merkle.Higher.Store
import           Merkle.Higher.Types
--------------------------------------------

-- | construct a potentially-infinite tree-shaped stream of further values constructed by
-- deref-ing hash pointers using a hash-addressed store. Allows for store returning multiple
-- layers of tree structure in a single response (to enable future optimizations) via 'CoAttr'
lazyDeref
  :: forall m p
   . Monad m
  => HFunctor p
  => Store m p
  -> Hash :-> Term (Tagged Hash `HCompose` Lazy m `HCompose` p)
lazyDeref store = ana alg
  where
    alg :: Coalg (Tagged Hash `HCompose` Lazy m `HCompose` p) Hash
    alg p = HC . Tagged p . HC . Compose $ sDeref store p
