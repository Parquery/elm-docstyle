module MessagesTest exposing (entityToString, issueToString)

{-| Tests the toString functions.
-}

import Check
import Elm.Syntax.Range exposing (Range)
import Expect
import Issue
import Messages
import Models exposing (EntityType(..))
import Test


{-| Tests the entityToString function.
-}
entityToString : Test.Test
entityToString =
    Test.describe "Test the entityToString function."
        [ Test.test "Test type alias with no comment." <|
            \() ->
                Expect.equal
                    "line 13, type alias \"someTypeAlias\" with no comment"
                    (let
                        entity =
                            { range = aRange
                            , eType = TypeAlias
                            , name = "someTypeAlias"
                            , comment = Nothing
                            , exposed = False
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test function with no params and a comment." <|
            \() ->
                Expect.equal
                    ("line 13, exposed function with no parameters "
                        ++ "\"someParameterLessFunction\" with comment \"{-|A "
                        ++ "function.\n-}\""
                    )
                    (let
                        entity =
                            { range = aRange
                            , eType = Function []
                            , name = "someParameterLessFunction"
                            , comment =
                                Just
                                    ( anotherRange
                                    , "{-|A function.\n-}"
                                    )
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test function with params and comment." <|
            \() ->
                Expect.equal
                    ("line 13, function with parameters (aString, anInt) "
                        ++ "\"someFunction\" with comment \"{-|A function with "
                        ++ "parameters.\n-}\""
                    )
                    (let
                        entity =
                            { range = aRange
                            , eType = Function [ "aString", "anInt" ]
                            , name = "someFunction"
                            , comment =
                                Just
                                    ( anotherRange
                                    , "{-|A function with parameters.\n-}"
                                    )
                            , exposed = False
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test record with fields and comment." <|
            \() ->
                Expect.equal
                    ("line 13, exposed record with fields (aMap, aListOfInts) "
                        ++ "\"SomeRecord\" with comment \"{-|A record.\n-}\""
                    )
                    (let
                        entity =
                            { range = aRange
                            , eType = Record [ "aMap", "aListOfInts" ]
                            , name = "SomeRecord"
                            , comment =
                                Just ( anotherRange, "{-|A record.\n-}" )
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test type def with no comment." <|
            \() ->
                Expect.equal
                    "line 13, exposed type definition \"SomeType\""
                    (let
                        entity =
                            { range = aRange
                            , eType = TypeDef
                            , name = "SomeType"
                            , comment = Nothing
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity False
                    )
        ]


{-| Tests the issueToString function.
-}
issueToString : Test.Test
issueToString =
    Test.describe "Test the issueToString function."
        [ Test.test "Test top-level issue to string." <|
            \() ->
                Expect.equal
                    ("line 2: expected a top-level module comment, "
                        ++ "but found none."
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoTopLevelComment ]
                        (Issue.TopLevel Nothing)
                        |> Maybe.map (Messages.issueToString True)
                        |> Maybe.withDefault ""
                    )
        , Test.test "Test dangling comment issue to string." <|
            \() ->
                Expect.equal
                    ("line 13, comment reading \"--some wrong dangling "
                        ++ "comment.\": the first word of the comment "
                        ++ "is not capitalized;\nthe first line of the "
                        ++ "comment does not start with a space."
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NotCapitalized
                        , Check.NoStartingSpace
                        ]
                        (Issue.Dangling
                            ( aRange
                            , "--some wrong dangling comment."
                            )
                        )
                        |> Maybe.map (Messages.issueToString True)
                        |> Maybe.withDefault ""
                    )
        , Test.test "Test function declaration issue to string." <|
            \() ->
                let
                    offendingComment =
                        Just
                            ( anotherRange
                            , "{-| A function. Fixme: write a description. -}"
                            )

                    functionDef =
                        { range = aRange
                        , eType = Models.Function [ "aString" ]
                        , name = "someFunction"
                        , comment = offendingComment
                        , exposed = True
                        }
                in
                Expect.equal
                    ("line 13, exposed function with parameters (aString) "
                        ++ "\"someFunction\" with comment \"{-| A function. "
                        ++ "Fixme: write a description. -}\": the first line of the "
                        ++ "comment does not start with a verb in third person "
                        ++ "(stem -s);\nthe comment contains one of the words "
                        ++ "(todo, fixme)."
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoStartingVerb
                        , Check.TodoComment
                        ]
                        (Issue.Entity functionDef)
                        |> Maybe.map (Messages.issueToString True)
                        |> Maybe.withDefault ""
                    )
        , Test.test "Test record declaration issue to string." <|
            \() ->
                Expect.equal
                    ("line 13, exposed record with fields (aMap, aListOfInts) "
                        ++ "\"SomeRecord\" with comment \"{-|A record.\n-}\""
                    )
                    (let
                        entity =
                            { range = aRange
                            , eType = Record [ "aMap", "aListOfInts" ]
                            , name = "SomeRecord"
                            , comment =
                                Just ( anotherRange, "{-|A record.\n-}" )
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test type alias declaration issue to string." <|
            \() ->
                let
                    typeAliasDef =
                        { range = aRange
                        , eType = Models.TypeAlias
                        , name = "StringAlias"
                        , comment = Nothing
                        , exposed = True
                        }
                in
                Expect.equal
                    ("line 13, exposed type alias \"StringAlias\" with no "
                        ++ "comment: expected a comment on top of the "
                        ++ "declaration, but found none."
                    )
                    (Issue.fromViolationsAndTrigger
                        [ Check.NoEntityComment
                        ]
                        (Issue.Entity typeAliasDef)
                        |> Maybe.map (Messages.issueToString True)
                        |> Maybe.withDefault ""
                    )
        ]


aRange : Range
aRange =
    { start = { row = 12, column = 1 }
    , end = { row = 14, column = 1 }
    }


anotherRange : Range
anotherRange =
    { start = { row = 10, column = 1 }
    , end = { row = 11, column = 1 }
    }
