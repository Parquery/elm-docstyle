module Encoders exposing (encodeIssue)

import Constraints
import Elm.Syntax.Range
import Issue
import Json.Encode
import Messages
import Models


{-| Encodes an Issue record to JSON.
-}
encodeIssue : Issue.Issue -> Json.Encode.Value
encodeIssue issue =
    let
        ( violated, trigger ) =
            Issue.unwrap issue

        violationsStr =
            List.map Constraints.violationToMessage violated
    in
    Json.Encode.object
        [ ( "violations", Json.Encode.list <| List.map Json.Encode.string <| violationsStr )
        , ( "trigger", encodeTrigger trigger )
        ]


{-| Encodes a Trigger union type to JSON.
-}
encodeTrigger : Issue.Trigger -> Json.Encode.Value
encodeTrigger trigger =
    case trigger of
        Issue.Entity entity ->
            Json.Encode.object
                [ ( "trigger_type", Json.Encode.string "entity" )
                , ( "entity", encodeEntity entity )
                ]

        Issue.Dangling comment ->
            Json.Encode.object
                [ ( "trigger_type", Json.Encode.string "dangling comment" )
                , ( "comment", encodeComment comment )
                ]

        Issue.TopLevel mbcomment ->
            Json.Encode.object
                [ ( "trigger_type", Json.Encode.string "top-level comment" )
                , ( "comment", Maybe.withDefault (Json.Encode.string "") <| Maybe.map encodeComment <| mbcomment )
                ]


encodeEntity : Models.Entity -> Json.Encode.Value
encodeEntity entity =
    Json.Encode.object
        [ ( "range", Elm.Syntax.Range.encode <| entity.range )
        , ( "type", Json.Encode.string <| Messages.entityTypeToString <| entity.eType )
        , ( "name", Json.Encode.string <| entity.name )
        , ( "comment", Maybe.withDefault (Json.Encode.string "") <| Maybe.map encodeComment <| entity.comment )
        , ( "exposed", Json.Encode.bool <| entity.exposed )
        ]


encodeComment : Models.Comment -> Json.Encode.Value
encodeComment ( rng, comment ) =
    Json.Encode.object
        [ ( "text", Json.Encode.string comment )
        , ( "line", Json.Encode.int rng.start.row )
        ]
