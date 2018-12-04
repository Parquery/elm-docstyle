module EncodersTest exposing (encodeIssueTest)

{-| Tests the JSON encoding.
-}

import Check
import Elm.Syntax.Range exposing (Range)
import Encoders
import Expect
import Issue
import Json.Encode
import Messages
import Models exposing (EntityType(..))
import Test
import TestUtil as TU


{-| Tests encoding an Issue.
-}
encodeIssueTest : Test.Test
encodeIssueTest =
    Test.describe "Test the function encoding Issue to JSON."
        [ Test.test "Trigger type top level comment." <|
            \() ->
                Expect.equal
                    (String.join ""
                        [ """{ violations = { 0 = "expected a top-level module comment, """
                        , """but found none" }, trigger = { trigger_type = """
                        , """"top-level comment", comment = "" } }"""
                        ]
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoTopLevelComment ]
                        (Issue.TopLevel Nothing)
                        |> Maybe.map Encoders.encodeIssue
                        |> Maybe.map toString
                        |> Maybe.withDefault ""
                    )
        , Test.test "Trigger type dangling comment." <|
            \() ->
                Expect.equal
                    (String.join ""
                        [ """{ violations = { 0 = "the first word of the comment"""
                        , """ is not capitalized", 1 = "the first line of the comment """
                        , """does not start with a space" }, trigger = { trigger_type = """
                        , """"dangling comment", comment = { text = """
                        , """"--some wrong dangling comment.", line = 23 } } }"""
                        ]
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NotCapitalized
                        , Check.NoStartingSpace
                        ]
                        (Issue.Dangling
                            ( TU.range 23 0 23 40
                            , "--some wrong dangling comment."
                            )
                        )
                        |> Maybe.map Encoders.encodeIssue
                        |> Maybe.map toString
                        |> Maybe.withDefault ""
                    )
        , Test.test "Trigger type entity (function)." <|
            \() ->
                let
                    offendingComment =
                        Just
                            ( TU.range 20 0 20 20
                            , "{-| A function. Fixme: write a description. -}"
                            )

                    functionDef =
                        { range = TU.range 20 0 25 0
                        , eType = Models.Function [ "aString" ]
                        , name = "someFunction"
                        , comment = offendingComment
                        , exposed = True
                        }
                in
                Expect.equal
                    (String.join ""
                        [ """{ violations = { 0 = "the first line of the comment does not start """
                        , """with a verb in third person (stem -s)", 1 = "the comment """
                        , """contains one of the words (todo, fixme)" }, """
                        , """trigger = { trigger_type = "entity", entity = """
                        , """{ range = { 0 = 20, 1 = 0, 2 = 25, 3 = 0 }, """
                        , """type = "function with parameters (aString)", """
                        , """name = "someFunction", comment = { text = """
                        , """"{-| A function. Fixme: write a description. -}", """
                        , """line = 20 }, exposed = True } } }"""
                        ]
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoStartingVerb
                        , Check.TodoComment
                        ]
                        (Issue.Entity functionDef)
                        |> Maybe.map Encoders.encodeIssue
                        |> Maybe.map toString
                        |> Maybe.withDefault ""
                    )
        , Test.test "Trigger type entity (type alias)." <|
            \() ->
                let
                    typeAliasDef =
                        { range = TU.range 20 0 25 0
                        , eType = Models.TypeAlias
                        , name = "StringAlias"
                        , comment = Nothing
                        , exposed = True
                        }
                in
                Expect.equal
                    (String.join ""
                        [ """{ violations = { 0 = "expected a comment on top of the """
                        , """declaration, but found none" }, trigger = { trigger_type """
                        , """= "entity", entity = { range = { 0 = 20, 1 = 0, 2 = 25, """
                        , """3 = 0 }, type = "type alias", name = "StringAlias", """
                        , """comment = "", exposed = True } } }"""
                        ]
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoEntityComment
                        ]
                        (Issue.Entity typeAliasDef)
                        |> Maybe.map Encoders.encodeIssue
                        |> Maybe.map toString
                        |> Maybe.withDefault ""
                    )
        ]
