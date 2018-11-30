module Messages exposing (checkToString, commentToString, entityToString, entityTypeToString, issueToString)

{-| Contains function to translate records to strings.
-}

import Check
import Issue
import Models exposing (Entity, EntityType(..), Verbose)


{-| Computes the string representation of an Entity.

If verbose=True, the comment is included fully.

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


{-| Computes the string representation of an EntityType.

If verbose=True, the comment is included in full.

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


{-| Computes the string representation of an Issue.
-}
issueToString : Bool -> Issue.Issue -> String
issueToString verbose issue =
    let
        ( violated, underlying ) =
            Issue.unwrap issue

        violatedStr =
            violated
                |> List.map checkToString
                |> String.join ";\n"
                |> (\s -> s ++ ".")
    in
    case underlying of
        Issue.Entity entity ->
            entityToString entity verbose
                ++ ": "
                ++ violatedStr

        Issue.Dangling comment ->
            commentToString comment verbose
                ++ ": "
                ++ violatedStr

        Issue.TopLevel mbcomment ->
            case mbcomment of
                Just comment ->
                    "line 2: "
                        ++ commentToString comment verbose
                        ++ ": "
                        ++ violatedStr

                Nothing ->
                    "line 2: "
                        ++ violatedStr


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


{-| Describes a violated check.
-}
checkToString : Check.Type -> String
checkToString tajp =
    case tajp of
        Check.NoStartingSpace ->
            "the first line of the comment does not start with a space"

        Check.NotCapitalized ->
            "in one line of the comment, the first word is not capitalized"

        Check.NoStartingVerb ->
            "one line of the comment does not start "
                ++ "with a verb in third person (stem -s)"

        Check.NoEndingPeriod ->
            "one line of the comment does not end with a period"

        Check.WrongCommentType ->
            "the comment syntax {-|...-} is not allowed here"

        Check.TodoComment ->
            "the comment contains one of the words (todo, fixme)"

        Check.NoEntityComment ->
            "expected a comment on top of the declaration, but found none"

        Check.NoTopLevelComment ->
            "expected a top-level module comment, but found none"

        Check.NotExistingArgument arg ->
            "the argument (" ++ arg ++ ") does not exist"

        Check.NotAnnotatedArgument arg ->
            "the argument (" ++ arg ++ ") does not appear in the documentation"
