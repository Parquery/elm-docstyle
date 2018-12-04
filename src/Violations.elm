module Violations exposing (dangling, entity, topLevel)

{-| Determines which checks are violated by the parsed module.
-}

import Check
import Models
import Regex


{-| Computes the failed checks for an entity.

  - ´checkAllDefinitions´ -- if false, the entity is checked only if it exposed;
    otherwise, it is checked irregardless.
  - ´ignored´ -- the list of the checks not to be performed.

-}
entity : Models.Entity -> Bool -> List Check.Type -> List Check.Type
entity entity checkAllDefinitions ignored =
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
                                List.map
                                    (Check.notAnnotatedArgument
                                        commentArgs
                                    )
                                    params
                                    |> List.filterMap identity

                            notExistingArgsCheck =
                                Check.notExistingArgument commentArgs params
                        in
                        firstLine
                            |> Maybe.map
                                (\line ->
                                    [ Check.startingCapitalized line
                                    , Check.startingVerb line
                                    , Check.startingSpace line
                                    , Check.endingPeriod line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append
                                [ Check.todoComment comment
                                , Check.emptyComment comment
                                ]
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
                                List.map
                                    (Check.notAnnotatedArgument commentArgs)
                                    fields
                                    |> List.filterMap identity

                            notExistingArgsCheck =
                                Check.notExistingArgument commentArgs fields
                        in
                        firstLine
                            |> Maybe.map
                                (\line ->
                                    [ Check.startingCapitalized line
                                    , Check.startingVerb line
                                    , Check.startingSpace line
                                    , Check.emptyComment line
                                    , Check.endingPeriod line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append
                                [ Check.todoComment comment
                                , Check.emptyComment comment
                                ]
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
                                    [ Check.startingCapitalized line
                                    , Check.startingVerb line
                                    , Check.endingPeriod line
                                    , Check.emptyComment line
                                    , Check.startingSpace line
                                    ]
                                )
                            |> Maybe.withDefault []
                            |> List.append
                                [ Check.todoComment comment
                                , Check.emptyComment comment
                                ]
                            |> List.filterMap identity

            Nothing ->
                case entity.eType of
                    Models.Function params ->
                        params
                            |> List.map Check.NotAnnotatedArgument
                            |> (::) Check.NoEntityComment

                    Models.Record fields ->
                        fields
                            |> List.map Check.NotAnnotatedArgument
                            |> (::) Check.NoEntityComment

                    _ ->
                        [ Check.NoEntityComment ]
        )
            |> filterIgnored ignored


{-| Computes the failed checks for a dangling comment.

  - ´ignored´ -- the list of the checks not to be performed.

-}
dangling : Models.Comment -> List Check.Type -> List Check.Type
dangling ( _, comment ) ignored =
    let
        commentLine =
            if String.startsWith "--" comment then
                comment

            else
                String.split "\n" comment
                    |> List.head
                    |> Maybe.withDefault ""
    in
    [ Check.startingCapitalized commentLine
    , Check.startingSpace commentLine
    , Check.endingPeriod commentLine
    , Check.commentType commentLine
    , Check.todoComment commentLine
    , Check.emptyComment comment
    ]
        |> List.filterMap identity
        |> filterIgnored ignored


{-| Computes the failed checks for a top-level comment (or lack thereof).

  - ´ignored´ -- the list of the checks not to be performed.

-}
topLevel : Maybe Models.Comment -> List Check.Type -> List Check.Type
topLevel maybeComment ignored =
    (case maybeComment of
        Just ( _, comment ) ->
            [ Check.startingSpace comment
            , Check.todoComment comment
            , Check.emptyComment comment
            ]
                |> List.filterMap identity

        Nothing ->
            [ Check.NoTopLevelComment ]
    )
        |> filterIgnored ignored


{-| Defines a matcher for a documentation argument check.

It matches arguments documented like: "- ´some name´ --",
or "- ´some name´ &mdash;".

-}
argumentRegex : Regex.Regex
argumentRegex =
    Regex.regex "- ´([a-zA-Z0-9]+)´ (--|&mdash;)"


{-| Parses the documented arguments or fields from a comment.
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


{-| Filters the ignored checks from the list of all checks.
-}
filterIgnored : List Check.Type -> List Check.Type -> List Check.Type
filterIgnored toIgnore checks =
    let
        toKeep check =
            case check of
                Check.NotExistingArgument _ ->
                    not (List.member (Check.NotExistingArgument "") toIgnore)

                Check.NotAnnotatedArgument _ ->
                    not (List.member (Check.NotAnnotatedArgument "") toIgnore)

                _ ->
                    not (List.member check toIgnore)
    in
    List.filter toKeep checks
