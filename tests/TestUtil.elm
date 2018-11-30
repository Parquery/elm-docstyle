module TestUtil exposing (range, stringToIntermediate)

{-| Contains utility functions for the test suite.
-}

import Elm.Parser
import Elm.Processing
import Elm.Syntax.Range
import Intermediate
import Models


{-| Parses a string to a ParsedModule.
-}
stringToIntermediate : String -> Maybe Models.ParsedModule
stringToIntermediate str =
    case Elm.Parser.parse str of
        Ok ast ->
            ast
                |> Elm.Processing.process Elm.Processing.init
                |> Intermediate.translate
                |> (\a -> Just a)

        Err e ->
            Nothing


{-| Creates a range from the two given (row, column) tuples.
-}
range : Int -> Int -> Int -> Int -> Elm.Syntax.Range.Range
range startRow startCol endRow endCol =
    { start = { row = startRow, column = startCol }
    , end = { row = endRow, column = endCol }
    }
