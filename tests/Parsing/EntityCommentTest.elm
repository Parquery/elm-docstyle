module Parsing.EntityCommentTest exposing (parseEntityCommentTest)

{-| Tests the correct parsing of entities.
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


parseEntityCommentTest : Test.Test
parseEntityCommentTest =
    let
        expectedComment r1 c1 r2 c2 =
            Just ( TestUtil.range r1 c1 r2 c2, "{-| SomeType is a type.\n-}" )

        checkNoEntities modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Expect.equal m.entities []

                Nothing ->
                    Expect.fail "Failed to parse the module!"

        checkExpectation expected modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    m.entities
                        |> List.head
                        |> Maybe.map
                            (\ent -> Expect.equal ent.comment expected)
                        |> Maybe.withDefault
                            (Expect.fail "No entities parsed.")

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the parsing function for the declaration comments."
        [ Test.describe "Modules with no declarations."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("no declarations " ++ toString idx)
                            (\() -> checkNoEntities moduleStr)
                )
                [ """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}
                  """ |> TestUtil.dedent 18
                , """module SomeName exposing (..)"""
                , """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}

                  import Dict
                  import List
                  """ |> TestUtil.dedent 18
                , """
                  module SomeName exposing (..)

                  import Dict
                  import List
                  """ |> TestUtil.dedent 18
                ]
            )
        , Test.describe "Modules with declarations and no comment."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("declarations with no comments " ++ toString idx)
                            (\() -> checkExpectation Nothing moduleStr)
                )
                [ """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}

                  type alias SomeType = String
                  """ |> TestUtil.dedent 18
                , """
                  module SomeName exposing (..)

                  type alias SomeType = String
                  """ |> TestUtil.dedent 18
                ]
            )
        , Test.describe
            "Modules with wrong comment format, which does not get parsed."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("declarations with no comments " ++ toString idx)
                            (\() -> checkExpectation Nothing moduleStr)
                )
                [ """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}

                  {- SomeType is a type.
                  -}
                  type alias SomeType = String
                  """ |> TestUtil.dedent 18
                , """
                  module SomeName exposing (..)

                  {-| This module is empty. One day, though...
                  -}

                  -- SomeType is a type.
                  type alias SomeType = String
                  """ |> TestUtil.dedent 18
                ]
            )
        , Test.test "Basic example of documented entity." <|
            \() ->
                checkExpectation (expectedComment 5 0 6 2)
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}

                    {-| SomeType is a type.
                    -}
                    type alias SomeType = String
                    """ |> TestUtil.dedent 20)
        , Test.test "Module with documented entity and top-level comment." <|
            \() ->
                checkExpectation (expectedComment 9 0 10 2)
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
        , Test.test "A more complex example." <|
            \() ->
                checkExpectation (expectedComment 11 0 12 2)
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
        ]
