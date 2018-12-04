module Checking.DanglingCommentTest exposing (checkDanglingCommentTest)

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


checkDanglingCommentTest : Test.Test
checkDanglingCommentTest =
    let
        checkExpectation expected modString ignored =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    m.otherComments
                        |> List.head
                        |> Maybe.map
                            (\cm ->
                                Violations.dangling cm ignored
                            )
                        |> Maybe.withDefault []
                        |> Expect.equalLists expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the checker on the dangling comments."
        [ Test.test "Ok dangling comment wrapped in {--}." <|
            \() ->
                checkExpectation []
                    ("""
                    module SomeName exposing (..)

                    {- A dangling comment.-}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Ok dangling comment wrapped in --." <|
            \() ->
                checkExpectation []
                    ("""
                    module SomeName exposing (..)

                    -- A dangling comment.
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Empty dangling comment wrapped in {--}." <|
            \() ->
                checkExpectation
                    [ Check.EmptyComment ]
                    ("""
                    module SomeName exposing (..)

                    {-

                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Empty dangling comment wrapped in --." <|
            \() ->
                checkExpectation
                    [ Check.EmptyComment ]
                    ("""
                    module SomeName exposing (..)

                    --
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Wrong dangling comment type (documentation comment)." <|
            \() ->
                checkExpectation
                    [ Check.WrongCommentType ]
                    ("""
                    module SomeName exposing (..)

                    import String


                    type alias Tp = Int

                    {-| This is a well-formed but ill-placed dangling comment.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Larger example: comment violating numerous checks." <|
            \() ->
                checkExpectation
                    [ Check.NotCapitalized
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    , Check.TodoComment
                    ]
                    ("""
                    module SomeName exposing (..)

                    import String


                    type alias Tp = Int

                    --this is a poorly-formed dangling comment. fixme: make it better
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Larger example, ignoring all violated checks." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (..)

                    import String


                    type alias Tp = Int

                    --this is a poorly-formed dangling comment. fixme: make it better
                    """
                        |> TestUtil.dedent
                    )
                    [ Check.NotCapitalized
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    , Check.TodoComment
                    ]
        , Test.test "Another larger example." <|
            \() ->
                checkExpectation
                    [ Check.NotCapitalized
                    , Check.TodoComment
                    ]
                    ("""
                    module SomeName exposing (..)

                    import String


                    type alias Tp = Int

                    {- this is a poorly-formed dangling comment. todo: improve it.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        ]
