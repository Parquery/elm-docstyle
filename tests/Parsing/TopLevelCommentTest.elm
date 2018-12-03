module Parsing.TopLevelCommentTest exposing (parseTopLevelCommentTest)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil


parseTopLevelCommentTest : Test.Test
parseTopLevelCommentTest =
    let
        expectedDocs =
            Just
                ( TestUtil.range 2 0 3 2
                , "{-| This module is empty. One day, though...\n-}"
                )

        checkExpectation expected modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Expect.equal m.topLevelComment expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the parsing function for the top level comment."
        [ Test.test "Empty module with doc." <|
            \() ->
                checkExpectation expectedDocs
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}
                    """ |> TestUtil.dedent 20)
        , Test.test "Empty module without doc." <|
            \() ->
                checkExpectation Nothing
                    """module SomeName exposing (..)"""
        , Test.test "Module with doc and no imports." <|
            \() ->
                checkExpectation expectedDocs
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}

                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Module without doc and no imports." <|
            \() ->
                checkExpectation Nothing
                    ("""
                    module SomeName exposing (..)

                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Module with doc and no declarations." <|
            \() ->
                checkExpectation expectedDocs
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}

                    import Dict
                    import List
                    """ |> TestUtil.dedent 20)
        , Test.test "Module without doc and no declarations." <|
            \() ->
                checkExpectation Nothing
                    ("""
                    module SomeName exposing (..)

                    import Dict
                    import List
                    """ |> TestUtil.dedent 20)
        , Test.test "Module with doc and commented declaration." <|
            \() ->
                checkExpectation expectedDocs
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Module without doc and commented declaration." <|
            \() ->
                checkExpectation Nothing
                    ("""
                    module SomeName exposing (..)

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Module with doc and imports and commented declaration." <|
            \() ->
                checkExpectation expectedDocs
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}

                    import Dict
                    import List
                    import Models

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Larger example." <|
            \() ->
                checkExpectation
                    (Just
                        ( TestUtil.range 4 0 5 2
                        , "{-| This module is empty. One day, though...\n-}"
                        )
                    )
                    ("""
                    module SomeName exposing (SomeType
                            , buildSomeType
                            )

                    {-| This module is empty. One day, though...
                    -}

                    import Dict
                    import List
                    import Models

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """ |> TestUtil.dedent 20)
        , Test.test "Doc with wrong comment type {--}." <|
            \() ->
                checkExpectation Nothing
                    ("""
                    module SomeName exposing (SomeType
                                , buildSomeType
                                )

                    {- This module is empty. One day, though...
                    -}

                    import Dict
                    import List
                    import Models

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """ |> TestUtil.dedent 20)
        , Test.test "Doc with wrong comment type --." <|
            \() ->
                checkExpectation Nothing
                    ("""
                    module SomeName exposing (SomeType
                                        , buildSomeType
                                        )

                    -- This module is empty. One day, though...

                    import Dict
                    import List
                    import Models

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """ |> TestUtil.dedent 20)
        ]
