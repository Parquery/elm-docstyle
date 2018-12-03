module Configuration exposing (Format(..), Model, defaultModel, fromFlags)

{-| Provides the configuration for customizing elm-docstyle's behavior.
-}

import Check
import Models


{-| Creates a configuration record from the flags passed to elm-docstyle.

  - ´verbose´ -- if set, the violations will include the offending comment
  - ´format´ -- human or JSON format for the checks
  - ´excludedChecks´ -- an optional list of constraints to ignore
  - ´checkAllDefinitions´ -- if set, all declarations are checked;
    otherwise, only exported ones.

-}
fromFlags : Models.Flags -> Result String Model
fromFlags { verbose, format, excludedChecks, checkAllDefinitions } =
    let
        parsedChecks =
            excludedChecks
                |> List.map (\s -> ( s, Check.stringToViolation s ))
                |> (\list ->
                        case
                            List.filter
                                (\( _, el ) -> el == Nothing)
                                list
                        of
                            [] ->
                                list
                                    |> List.map Tuple.second
                                    |> List.filterMap identity
                                    |> Ok

                            lst ->
                                lst
                                    |> List.map Tuple.first
                                    |> String.join """", \""""
                                    |> (\errs ->
                                            Err
                                                ("Illegal check name(s): "
                                                    ++ "\""
                                                    ++ errs
                                                    ++ "\"."
                                                )
                                       )
                   )

        parsedFormat =
            if format == "" || String.toLower format == "human" then
                Ok HUMAN

            else if String.toLower format == "json" then
                Ok JSON

            else
                Err
                    ("Failed to parse the format flag. "
                        ++ "Expected \"\", \"human\" or \"json\""
                        ++ ", got: "
                        ++ format
                    )
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


{-| Is the configuration model.

  - ´excludedChecks´ -- an optional list of constraints to ignore
  - ´checkAllDefinitions´ -- if set, all declarations are checked;
    otherwise, only exported ones.
  - ´verbose´ -- if set, the violations will include the offending comment
  - ´format´ -- human or JSON format for the checks

-}
type alias Model =
    { excludedChecks : List Check.Type
    , checkAllDefinitions : Bool
    , verbose : Models.Verbose
    , format : Format
    }


{-| Is the default value for the configuration model.
-}
defaultModel : Model
defaultModel =
    { excludedChecks = []
    , checkAllDefinitions = False
    , verbose = False
    , format = defaultFormat
    }


{-| Specifies the default output format as human (string).
-}
defaultFormat : Format
defaultFormat =
    HUMAN


{-| Contains the supported formats.
-}
type Format
    = JSON
    | HUMAN
