module Checking.TopLevelCommentTest exposing (checkTopLevelCommentTest)

{-| Tests the correct parsing of top-level comments.
-}

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


checkTopLevelCommentTest : Test.Test
checkTopLevelCommentTest =
    let
        checkExpectation expected modString ignored =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Violations.topLevel
                        m.topLevelComment
                        ignored
                        |> Expect.equalLists expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the checker on the top-level documentation comment."
        [ Test.test "No documentation comment." <|
            \() ->
                checkExpectation
                    [ Check.NoTopLevelComment ]
                    """module SomeName exposing (..)"""
                    []
        , Test.test "No documentation comment but NoTopLevelComment error ignored." <|
            \() ->
                checkExpectation
                    []
                    """module SomeName exposing (..)"""
                    [ Check.NoTopLevelComment ]
        , Test.test "t.o.d.o in documentation." <|
            \() ->
                checkExpectation
                    [ Check.TodoComment ]
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. todo: change it.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "f.i.x.m.e in documentation." <|
            \() ->
                checkExpectation
                    [ Check.TodoComment ]
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. fixme: change it.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "no starting space in documentation." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace ]
                    ("""
                    module SomeName exposing (..)

                    {-|This module is empty.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "empty top level comment." <|
            \() ->
                checkExpectation
                    [ Check.EmptyComment ]
                    ("""
                    module SomeName exposing (..)

                    {-|
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "Correct documentation comment." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (..)

                    {-| This module is empty. One day, though...
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "No starting space and f.i.x.m.e in comment." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace, Check.TodoComment ]
                    ("""
                    module SomeName exposing (..)

                    {-|This module is empty. fixme: change it.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    []
        , Test.test "No starting space and f.i.x.m.e in comment, both ignored." <|
            \() ->
                checkExpectation
                    []
                    ("""
                    module SomeName exposing (..)

                    {-|This module is empty. fixme: change it.
                    -}
                    """
                        |> TestUtil.dedent
                    )
                    [ Check.NoStartingSpace, Check.TodoComment ]
        ]
