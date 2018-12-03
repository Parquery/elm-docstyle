module Parsing.DanglingCommentTest exposing (parseDanglingCommentTest)

{-| Tests the correct parsing of dangling comments.
-}

import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil


parseDanglingCommentTest : Test.Test
parseDanglingCommentTest =
    let
        expectedComment r1 c1 r2 c2 str =
            ( TestUtil.range r1 c1 r2 c2, str )

        checkNoDanglingComments modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Expect.equal m.otherComments []

                Nothing ->
                    Expect.fail "Failed to parse the module!"

        checkExpectation expected modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    m.otherComments
                        |> List.head
                        |> Maybe.map (\cmm -> Expect.equal cmm expected)
                        |> Maybe.withDefault
                            (Expect.fail "No dangling comments parsed.")

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe
        "Test the parsing function for dangling comments."
        [ Test.describe "Modules with no dangling comments."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("no dangling comments " ++ toString idx)
                            (\() ->
                                moduleStr
                                    |> TestUtil.dedent 18
                                    |> checkNoDanglingComments
                            )
                )
                [ """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}
                  """
                , """
                  module SomeName exposing (..)
                  """
                , """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}

                  type alias SomeType = String
                  """
                , """
                  module SomeName exposing ( SomeType
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
                  """
                ]
            )
        , Test.test "Module with top-level comment in the wrong format {--}, parsed as dangling." <|
            \() ->
                checkExpectation
                    (expectedComment 4
                        0
                        5
                        2
                        "{- This module is empty. One day, though...\n-}"
                    )
                    ("""
                    module SomeName exposing ( SomeType
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
                    """
                        |> TestUtil.dedent 20
                    )
        , Test.test "Module with top-level comment in the wrong format --, parsed as dangling." <|
            \() ->
                checkExpectation
                    (expectedComment 4
                        0
                        4
                        43
                        "-- This module is empty. One day, though..."
                    )
                    ("""
                    module SomeName exposing ( SomeType
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
                    """
                        |> TestUtil.dedent 20
                    )
        , Test.test "Basic dangling comment wrapped in --." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        26
                        "-- just a dangling comment"
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

                    -- just a dangling comment

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """
                        |> TestUtil.dedent 20
                    )
        , Test.test "Basic dangling comment wrapped in {--}." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        29
                        "{- just a dangling comment -}"
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

                    {- just a dangling comment -}

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """
                        |> TestUtil.dedent 20
                    )
        , Test.test "Dangling documentation comment {-|-}." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        30
                        "{-| just a dangling comment -}"
                    )
                    ("""
                    module SomeName exposing ( SomeType
                                             , buildSomeType
                                             )

                    {-| This module is empty. One day, though...
                    -}

                    import Dict
                    import List
                    import Models

                    {-| just a dangling comment -}

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String

                    {-| buildSomeType builds some type.
                    -}
                    buildSomeType = "hello"
                    """
                        |> TestUtil.dedent 20
                    )
        ]
