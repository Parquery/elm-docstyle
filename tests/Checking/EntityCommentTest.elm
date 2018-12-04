module Checking.EntityCommentTest exposing (checkEntityCommentTest)

import Check
import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil
import Violations


checkEntityCommentTest : Test.Test
checkEntityCommentTest =
    let
        checkExpectation expected modString ignored checkAll =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    m.entities
                        |> List.map
                            (\ent ->
                                Violations.entity
                                    ent
                                    checkAll
                                    ignored
                            )
                        |> List.concat
                        |> Expect.equalLists expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the checker on the entity documentation comments."
        [ Test.test "Module with no comment on exposed function." <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment
                    , Check.NotAnnotatedArgument "anInt"
                    ]
                    ("""
                    module SomeName exposing (..)

                    value : Int -> String
                    value anInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with no comment on exposed record." <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment
                    , Check.NotAnnotatedArgument "aField"
                    , Check.NotAnnotatedArgument "anotherField"
                    ]
                    ("""
                    module SomeName exposing (..)

                    type alias Something =
                         { aField : String
                         , anotherField : Int
                         }
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with wrong argument comment on exposed record." <|
            \() ->
                checkExpectation
                    [ Check.NotAnnotatedArgument "aField"
                    , Check.NotExistingArgument "aFieldWrong"
                    ]
                    ("""
                    module SomeName exposing (..)

                    {-| Is a simple record.

                      - ´aFieldWrong´ &mdash; contains a string.
                      - ´anotherField´ -- contains an int.
                    -}
                    type alias Something =
                        { aField : String
                        , anotherField : Int
                        }
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with no comment on exposed type def." <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment ]
                    ("""
                    module SomeName exposing (..)

                    type Something = A | B
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with no comment on exposed type alias." <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment ]
                    ("""
                    module SomeName exposing (..)

                    type alias Something = String
                    """ |> TestUtil.dedent)
                    []
                    False
        , Test.describe
            "Unexposed declarations with no documentation and checkAll=false."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("Unexposed declarations with no documentation"
                                ++ "and checkAll=false "
                                ++ toString idx
                            )
                        <|
                            \() ->
                                checkExpectation
                                    []
                                    moduleStr
                                    []
                                    False
                )
                [ """
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    value : Int -> String
                    value anInt =
                      toString anInt
                    """ |> TestUtil.dedent
                , """
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    type alias Something =
                       { aField : String
                       , anotherField : Int
                       }
                    """ |> TestUtil.dedent
                , """
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    type Something = A | B
                    """ |> TestUtil.dedent
                , """
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    type alias Something = String
                    """ |> TestUtil.dedent
                ]
            )
        , Test.test
            "Module with no comment on unexposed function, and checkAll = true."
          <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment
                    , Check.NotAnnotatedArgument "anInt"
                    ]
                    ("""
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    value : Int -> String
                    value anInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test
            "Module with no comment on unexposed record, and checkAll = true."
          <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment
                    , Check.NotAnnotatedArgument "aField"
                    , Check.NotAnnotatedArgument "anotherField"
                    ]
                    ("""
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String

                    type alias Something =
                         { aField : String
                         , anotherField : Int
                         }
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test
            "Module with no comment on unexposed type def, and checkAll = true."
          <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment ]
                    ("""
                    module SomeName exposing (..)

                    type Something = A | B
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test
            "Module with no comment on unexposed type alias, and checkAll = true."
          <|
            \() ->
                checkExpectation
                    [ Check.NoEntityComment ]
                    ("""
                    module SomeName exposing (..)

                    type alias Something = String
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with comment violating numerous checks." <|
            \() ->
                checkExpectation
                    [ Check.NotAnnotatedArgument "anInt"
                    , Check.TodoComment
                    , Check.NoStartingVerb
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    ]
                    ("""
                    module SomeName exposing (..)

                    {-|TODO make this nicer
                    -}
                    value : Int -> String
                    value anInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with comment violating numerous checks 2." <|
            \() ->
                checkExpectation
                    [ Check.NotAnnotatedArgument "anInt"
                    , Check.NotAnnotatedArgument "anotherInt"
                    , Check.NotAnnotatedArgument "aThirdInt"
                    , Check.TodoComment
                    , Check.NotCapitalized
                    , Check.NoStartingVerb
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    ]
                    ("""
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String


                    {-|some value. fixme: add a better doc
                    -}
                    value : Int -> Int -> Int -> String
                    value anInt anotherInt aThirdInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with comment violating numerous checks, all ignored." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (Param)

                    {-| Contains a correctly documented type alias.
                    -}
                    type alias Param = String


                    {-|some value. fixme: add a better doc
                    -}
                    value : Int -> Int -> Int -> String
                    value anInt anotherInt aThirdInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    [ Check.NotAnnotatedArgument ""
                    , Check.TodoComment
                    , Check.NotCapitalized
                    , Check.NoStartingVerb
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    ]
                    True
        , Test.test "Module with correctly documented record." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (..)

                    {-| Is a simple record.

                      - ´aField´ &mdash; contains a string.
                      - ´anotherField´ -- contains an int.
                    -}
                    type alias Something =
                        { aField : String
                        , anotherField : Int
                        }
                    """ |> TestUtil.dedent)
                    []
                    True
        , Test.test "Module with correctly documented function." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (..)


                    {-| Is a simple function.

                      - ´anInt´ &mdash; any integer you like.
                    -}
                    value : Int -> String
                    value anInt =
                        toString anInt
                    """ |> TestUtil.dedent)
                    []
                    True
        ]
