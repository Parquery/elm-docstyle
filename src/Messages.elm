module Messages exposing (commentToString, entityToString, entityTypeToString)

import Models exposing (Entity, EntityType(..), Verbose)


{-| Computes the string representation of an Entity. If verbose, the comment is included fully.
-}
entityToString : Entity -> Verbose -> String
entityToString { range, eType, name, comment, exposed } verbose =
    let
        firstRow =
            toString (range.start.row + 1)

        exposedStr =
            if exposed then
                "exposed "

            else
                ""

        suffix =
            if verbose then
                case Maybe.map Tuple.second comment of
                    Just commentStr ->
                        " with comment \"" ++ commentStr ++ "\""

                    Nothing ->
                        " with no comment"

            else
                ""
    in
    "line "
        ++ firstRow
        ++ ", "
        ++ exposedStr
        ++ entityTypeToString eType
        ++ " "
        ++ "\""
        ++ name
        ++ "\""
        ++ suffix


{-| Computes the string representation of an EntityType. If verbose, the comment is included in full.
-}
commentToString : Models.Comment -> Verbose -> String
commentToString ( range, comment ) verbose =
    let
        lStart =
            toString (range.start.row + 1)

        suffix =
            if verbose then
                ", comment reading \"" ++ comment ++ "\""

            else
                ""
    in
    "line "
        ++ lStart
        ++ suffix


{-| Computes the string representation of an EntityType.
-}
entityTypeToString : EntityType -> String
entityTypeToString entType =
    case entType of
        Function params ->
            let
                paramsStr =
                    case params of
                        [] ->
                            "no parameters"

                        _ ->
                            "parameters (" ++ String.join ", " params ++ ")"
            in
            "function with " ++ paramsStr

        Record fields ->
            let
                fieldsStr =
                    "fields (" ++ String.join ", " fields ++ ")"
            in
            "record with " ++ fieldsStr

        TypeDef ->
            "type definition"

        TypeAlias ->
            "type alias"
