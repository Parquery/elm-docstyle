module Constraints exposing (Type(..), getViolationsDangling, getViolationsEntity, getViolationsTopLevel, stringToViolation, violationToMessage)

{-| A constraint type with an explanation about how the comment is not respecting it.
-}

import Models
import Regex


getViolationsEntity : Models.Entity -> Bool -> List Type -> List Type
getViolationsEntity entity checkAllDefinitions ignored =
    if not (entity.exposed || checkAllDefinitions) then
        []

    else
        (case entity.comment of
            Just ( _, comment ) ->
                case entity.eType of
                    Models.Function params ->
                        let
                            firstLine =
                                String.split "\n" comment
                                    |> List.head

                            commentArgs =
                                parseArguments comment

                            notAnnotatedArgsCheck =
                                List.map (notAnnotatedArgumentCheck commentArgs) params
                                    |> List.filterMap identity

                            notExistingArgsCheck =
                                notExistingArgumentCheck commentArgs params
                        in
                        firstLine
                            |> Maybe.map
                                (\line ->
                                    [ startingCapitalizedCheck line
                                    , startingVerbCheck line
                                    , startingSpaceCheck line
                                    , endingPeriodCheck line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append [ todoCommentCheck comment ]
                            |> List.filterMap identity
                            |> List.append notExistingArgsCheck
                            |> List.append notAnnotatedArgsCheck

                    Models.Record fields ->
                        let
                            firstLine =
                                String.split "\n" comment
                                    |> List.head

                            commentArgs =
                                parseArguments comment

                            notAnnotatedArgsCheck =
                                List.map (notAnnotatedArgumentCheck commentArgs) fields
                                    |> List.filterMap identity

                            notExistingArgsCheck =
                                notExistingArgumentCheck commentArgs fields
                        in
                        firstLine
                            |> Maybe.map
                                (\line ->
                                    [ startingCapitalizedCheck line
                                    , startingVerbCheck line
                                    , startingSpaceCheck line
                                    , endingPeriodCheck line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append [ todoCommentCheck comment ]
                            |> List.filterMap identity
                            |> List.append notExistingArgsCheck
                            |> List.append notAnnotatedArgsCheck

                    _ ->
                        let
                            firstLine =
                                String.split "\n" comment
                                    |> List.head
                        in
                        firstLine
                            |> Maybe.map
                                (\line ->
                                    [ startingCapitalizedCheck line
                                    , startingVerbCheck line
                                    , endingPeriodCheck line
                                    , startingSpaceCheck line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append [ todoCommentCheck comment ]
                            |> List.filterMap identity

            Nothing ->
                case entity.eType of
                    Models.Function params ->
                        params
                            |> List.map NotAnnotatedArgument
                            |> (::) NoEntityComment

                    Models.Record fields ->
                        fields
                            |> List.map NotAnnotatedArgument
                            |> (::) NoEntityComment

                    _ ->
                        [ NoEntityComment ]
        )
            |> filterIgnored ignored


getViolationsDangling : Models.Comment -> List Type -> List Type
getViolationsDangling ( _, comment ) ignored =
    let
        commentLine =
            if String.startsWith "--" comment then
                comment

            else
                String.split "\n" comment
                    |> List.head
                    |> Maybe.withDefault ""
    in
    [ startingCapitalizedCheck commentLine
    , startingSpaceCheck commentLine
    , endingPeriodCheck commentLine
    , commentTypeCheck commentLine
    , todoCommentCheck commentLine
    ]
        |> List.filterMap identity
        |> filterIgnored ignored


getViolationsTopLevel : Maybe Models.Comment -> List Type -> List Type
getViolationsTopLevel maybeComment ignored =
    (case maybeComment of
        Just ( _, comment ) ->
            [ startingSpaceCheck comment
            , todoCommentCheck comment
            ]
                |> List.filterMap identity

        Nothing ->
            [ NoTopLevelComment ]
    )
        |> filterIgnored ignored


startingCapitalizedCheck : String -> Maybe Type
startingCapitalizedCheck comment =
    let
        first =
            String.words comment
                |> List.head
                -- if no words, no violation of the rule
                |> Maybe.withDefault "A"
    in
    if String.toUpper first == first then
        Nothing

    else
        Just NotCapitalized


startingSpaceCheck : String -> Maybe Type
startingSpaceCheck comment =
    if
        String.startsWith "{- " comment
            || String.startsWith "-- " comment
            || String.startsWith "{-| " comment
    then
        Nothing

    else
        Just NoStartingSpace


startingVerbCheck : String -> Maybe Type
startingVerbCheck comment =
    let
        firstWord =
            String.words comment
                -- drop the prefix (--, {- or {-|)
                |> List.drop 1
                |> List.head
                -- if no words, no violation of the rule
                |> Maybe.withDefault "s"
    in
    if String.endsWith "s" firstWord then
        Nothing

    else
        Just NoStartingVerb


endingPeriodCheck : String -> Maybe Type
endingPeriodCheck comment =
    let
        last =
            if String.endsWith "-}" comment then
                comment
                    |> String.dropRight 2
                    |> String.trim
                    |> String.right 1

            else
                String.right 1 comment
    in
    if last == "." || last == "" then
        Nothing

    else
        Just NoEndingPeriod


todoCommentCheck : String -> Maybe Type
todoCommentCheck comment =
    comment
        |> String.toLower
        |> (\str ->
                if String.contains "todo" str || String.contains "fixme" str then
                    Just TodoComment

                else
                    Nothing
           )


commentTypeCheck : String -> Maybe Type
commentTypeCheck comment =
    if String.startsWith "{-|" comment then
        Just WrongCommentType

    else
        Nothing


notAnnotatedArgumentCheck : List String -> String -> Maybe Type
notAnnotatedArgumentCheck parsedArguments shouldBeAnnotated =
    if List.member shouldBeAnnotated parsedArguments then
        Nothing

    else
        Just <| NotAnnotatedArgument shouldBeAnnotated


notExistingArgumentCheck : List String -> List String -> List Type
notExistingArgumentCheck parsedArguments allowed =
    parsedArguments
        |> List.filter (\el -> not (List.member el allowed))
        |> List.map NotExistingArgument


{-| Contains a matcher for a documentation argument check.

It matches arguments documented like "\* ´argname´ --" or "\* ´argname´ &mdash;".

  - ´hello´ -- some shit

-}
argumentRegex : Regex.Regex
argumentRegex =
    Regex.regex "\\* ´([a-zA-Z0-9]+)´ (--|&mdash;)"


{-| Parses the docuemnted arguments or fields from a comment.
-}
parseArguments : String -> List String
parseArguments comment =
    let
        matchToArgumentName match =
            match.submatches
                |> List.map (Maybe.withDefault "")
                |> List.head
                |> Maybe.withDefault ""
    in
    comment
        |> Regex.find Regex.All argumentRegex
        |> List.map matchToArgumentName


{-| Returns the difference of the second list and the first.
-}
filterIgnored : List Type -> List Type -> List Type
filterIgnored toIgnore checks =
    let
        toKeep check =
            case check of
                NotExistingArgument _ ->
                    not (List.member (NotExistingArgument "") toIgnore)

                NotAnnotatedArgument _ ->
                    not (List.member (NotAnnotatedArgument "") toIgnore)

                _ ->
                    not (List.member check toIgnore)
    in
    List.filter toKeep checks


{-| Describes a constraint violation.
-}
type Type
    = -- the first word should be capitalized.
      NotCapitalized
      -- the comment should start with a space.
    | NoStartingSpace
      -- the comment should start with a verb in present tense and third person (stem -s).
    | NoStartingVerb
      -- the comment should end with a period (ignoring one newline).
    | NoEndingPeriod
      -- wrong documentation comment type "{-|-}" for a non-documentation comment.
    | WrongCommentType
      -- the comment should not contain the strings (with no dots) "t.o.d.o" or "f.i.x.m.e".
    | TodoComment
      -- a comment is expected on top of the entity.
    | NoEntityComment
      -- a top level comment is expected.
    | NoTopLevelComment
      -- an argument appearing in the documentation does not exist.
    | NotExistingArgument String
      -- an argument appearing in the function is not documented.
    | NotAnnotatedArgument String


violationToMessage : Type -> String
violationToMessage tajp =
    case tajp of
        NoStartingSpace ->
            "the first line of the comment does not start with a space"

        NotCapitalized ->
            "in one line of the comment, the first word is not capitalized"

        NoStartingVerb ->
            "one line of the comment does not start with a verb in third person (stem -s)"

        NoEndingPeriod ->
            "one line of the comment does not end with a period"

        WrongCommentType ->
            "the comment syntax {-|...-} is not allowed here"

        TodoComment ->
            "the comment contains one of the words (todo, fixme)"

        NoEntityComment ->
            "expected a comment on top of the declaration, but found none"

        NoTopLevelComment ->
            "expected a top-level module comment, but found none"

        NotExistingArgument arg ->
            "the argument (" ++ arg ++ ") does not exist"

        NotAnnotatedArgument arg ->
            "the argument (" ++ arg ++ ") does not appear in the documentation"


stringToViolation : String -> Maybe Type
stringToViolation str =
    case str of
        "NoStartingSpace" ->
            Just NoStartingSpace

        "NotCapitalized" ->
            Just NotCapitalized

        "NoStartingVerb" ->
            Just NoStartingVerb

        "NoEndingPeriod" ->
            Just NoEndingPeriod

        "WrongCommentType" ->
            Just WrongCommentType

        "TodoComment" ->
            Just TodoComment

        "NoEntityComment" ->
            Just NoEntityComment

        "NoTopLevelComment" ->
            Just NoTopLevelComment

        "NotExistingArgument" ->
            Just <| NotExistingArgument ""

        "NotAnnotatedArgument" ->
            Just <| NotAnnotatedArgument ""

        _ ->
            Nothing
