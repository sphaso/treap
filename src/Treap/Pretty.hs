-- | 'Treap' visualisation.

module Treap.Pretty
       ( pretty
       , prettyWith
       , verboseShowNode
       , compactShowNode

         -- * Internal implementation details
       , BinTree (..)
       , showTree
       , middleLabelPos
       , branchLines
       ) where

import Data.Char (isSpace)
import Data.List (dropWhileEnd, intercalate)

import Treap.Pure (Treap (..))


-- | Intermidiate structure to help string conversion.
data BinTree
    = Leaf
    | Branch String BinTree BinTree

{- | Show 'Treap' in an extremely nice and pretty way using 'compactShowNode'.
-}
pretty :: forall k p a . (Show k, Show p, Show a) => Treap k p a -> String
pretty = prettyWith compactShowNode

{- | Show 'Treap' node in a format:

@
(k: <key>, p: <priority>) -> a
@
-}
verboseShowNode :: (Show k, Show p, Show a) => k -> p -> a -> String
verboseShowNode k p a = "(k: " ++ show k ++ ", p: " ++ show p ++ ") -> " ++ show a

{- | Show 'Treap' node in a format:

@
<key>,<priority>:a
@
-}
compactShowNode :: (Show k, Show p, Show a) => k -> p -> a -> String
compactShowNode k p a = show k ++ "," ++ show p ++ ":" ++ show a

-- | Show 'Treap' in a nice way using given function to display node.
prettyWith
    :: forall k p a .
       (k -> p -> a -> String)
    -> Treap k p a
    -> String
prettyWith display = showTree . toBinTree
  where
    toBinTree :: Treap k p a -> BinTree
    toBinTree Empty                   = Leaf
    toBinTree (Node k p a left right) = Branch (display k p a) (toBinTree left) (toBinTree right)

showTree :: BinTree -> String
showTree Leaf                  = ""
showTree (Branch label left right) = case (left, right) of
    (Leaf, Leaf) -> label

    (_, Leaf) -> toLines $
        [ spaces rootShiftOnlyLeft   ++ label
        , spaces branchShiftOnlyLeft ++ "╱"
        ] ++ map (spaces leftShiftOnlyLeft ++) leftLines

    (Leaf, _) -> toLines $
        [ spaces rootShiftOnlyRight   ++ label
        , spaces branchShiftOnlyRight ++ "╲"
        ] ++ map (spaces rightShiftOnlyRight ++) rightLines

    (_, _) -> toLines $
        [ spaces rootOffset ++ label
        ]
        ++ map (spaces rootOffset ++ ) (branchLines branchHeight)
        ++ map (spaces childrenOffset ++) (zipChildren leftLines rightLines)
  where
    leftStr, rightStr :: String
    leftStr  = showTree left
    rightStr = showTree right

    leftLines :: [String]
    leftLines  = lines leftStr
    rightLines = lines rightStr

    rootLabelMiddle, leftLabelMiddle, rightLabelMiddle :: Int
    rootLabelMiddle  = middleLabelPos label
    leftLabelMiddle  = middleLabelPos $ head leftLines
    rightLabelMiddle = middleLabelPos $ head rightLines

    -- Case 1: all offsets when node has only left branch
    rootShiftOnlyLeft, leftShiftOnlyLeft, branchShiftOnlyLeft :: Int
    (rootShiftOnlyLeft, leftShiftOnlyLeft) = case compare rootLabelMiddle leftLabelMiddle of
        EQ -> (1, 0)
        GT -> (0, rootLabelMiddle - leftLabelMiddle - 1)
        LT -> (leftLabelMiddle - rootLabelMiddle + 1, 0)
    branchShiftOnlyLeft = rootLabelMiddle + rootShiftOnlyLeft - 1

    -- Case 2: all offsets when node has only right branch
    rootShiftOnlyRight, rightShiftOnlyRight, branchShiftOnlyRight :: Int
    (rootShiftOnlyRight, rightShiftOnlyRight) = case compare rootLabelMiddle rightLabelMiddle of
        EQ -> (0, 1)
        GT -> (0, rootLabelMiddle - rightLabelMiddle + 1)
        LT -> (rightLabelMiddle - rootLabelMiddle - 1, 0)
    branchShiftOnlyRight = rootLabelMiddle + rootShiftOnlyRight + 1

    -- Case 3: both
    leftWidth, rightOffMiddle, childDistance, branchHeight, rootMustMiddle :: Int
    leftWidth      = 1 + maximum (map length leftLines)
    rightOffMiddle = leftWidth + rightLabelMiddle
    childDistance  = rightOffMiddle - leftLabelMiddle
    branchHeight   = childDistance `div` 2
    rootMustMiddle = (leftLabelMiddle + rightOffMiddle) `div` 2

    rootOffset, childrenOffset :: Int
    (rootOffset, childrenOffset) = case compare rootLabelMiddle rootMustMiddle of
        EQ -> (0, 0)
        LT -> (rootMustMiddle - rootLabelMiddle, 0)
        GT -> (0, rootLabelMiddle - rootMustMiddle)

    zipChildren :: [String] -> [String] -> [String]
    zipChildren l []          = l
    zipChildren [] r          = map (spaces leftWidth ++ ) r
    zipChildren (x:xs) (y:ys) =
        let xLen = length x
            newX = x ++ spaces (leftWidth - xLen)
        in (newX ++ y) : zipChildren xs ys

-- | Generates strings containing of @n@ spaces.
spaces :: Int -> String
spaces n = replicate n ' '

{- | Calculates position of middle of non-space part of the string.

>>> s = "   abc "
>>> length s
7
>>> middleLabelPos s
4
-}
middleLabelPos :: String -> Int
middleLabelPos s =
    let (spacePrefix, rest) = span isSpace s
    in length spacePrefix + (length (dropWhileEnd isSpace rest) `div` 2)

-- | Like 'unlines' but doesn't add "\n" to the end.
toLines :: [String] -> String
toLines = intercalate "\n"

{- | Draws branches of the given height.

>>> putStrLn $ toLines $ branchLines 1
╱╲

>>> putStrLn $ toLines $ branchLines 2
 ╱╲
╱  ╲

>>> putStrLn $ toLines $ branchLines 3
  ╱╲
 ╱  ╲
╱    ╲
-}
branchLines :: Int -> [String]
branchLines n = go 0
  where
    go :: Int -> [String]
    go i
        | i == n    = []
        | otherwise = line : go (i + 1)
      where
        line :: String
        line = spaces (n - i - 1) ++ "╱" ++ spaces (2 * i) ++ "╲"