module Configuration exposing (Format(..), Model, defaultModel, fromFlags)

import Constraints
import Models


fromFlags : Models.Flags -> Result String Model
fromFlags { verbose, format, excludedChecks, checkAllDefinitions } =
    let
        parsedChecks =
            excludedChecks
                |> List.map (\str -> ( str, Constraints.stringToViolation str ))
                |> (\list ->
                        case List.filter (\( _, el ) -> el == Nothing) list of
                            [] ->
                                list
                                    |> List.map Tuple.second
                                    |> List.filterMap identity
                                    |> Ok

                            lst ->
                                lst
                                    |> List.map Tuple.first
                                    |> String.join """", \""""
                                    |> (\errs -> Err ("""Illegal check name(s): \"""" ++ errs ++ """"."""))
                   )

        parsedFormat =
            if format == "" || String.toLower format == "human" then
                Ok HUMAN

            else if String.toLower format == "json" then
                Ok JSON

            else
                Err ("""Failed to parse the format flag. Expected "", "human" or "json", got: """ ++ format)
    in
    case parsedFormat of
        Ok fmt ->
            parsedChecks
                |> Result.map
                    (\checks ->
                        { excludedChecks = checks
                        , checkAllDefinitions = checkAllDefinitions
                        , verbose = verbose
                        , format = fmt
                        }
                    )

        Err err ->
            Err err


type alias Model =
    { excludedChecks : List Constraints.Type
    , checkAllDefinitions : Bool
    , verbose : Models.Verbose
    , format : Format
    }


{-| Default value for the config model.
-}
defaultModel : Model
defaultModel =
    { excludedChecks = []
    , checkAllDefinitions = False
    , verbose = False
    , format = defaultFormat
    }


defaultFormat : Format
defaultFormat =
    HUMAN


type Format
    = JSON
    | HUMAN
