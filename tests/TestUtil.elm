module TestUtil exposing (range, stringToIntermediate)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.Range
import Intermediate
import Models


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


range : Int -> Int -> Int -> Int -> Elm.Syntax.Range.Range
range startRow startCol endRow endCol =
    { start = { row = startRow, column = startCol }
    , end = { row = endRow, column = endCol }
    }
