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
                    emptyModuleWithoutDoc
                    []
        , Test.test "No documentation comment but NoTopLevelComment error ignored." <|
            \() ->
                checkExpectation
                    []
                    emptyModuleWithoutDoc
                    [ Check.NoTopLevelComment ]
        , Test.test "t.o.d.o in documentation." <|
            \() ->
                checkExpectation
                    [ Check.TodoComment ]
                    moduleWithDocTodo
                    []
        , Test.test "f.i.x.m.e in documentation." <|
            \() ->
                checkExpectation
                    [ Check.TodoComment ]
                    moduleWithDocFixme
                    []
        , Test.test "no starting space in documentation." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace ]
                    moduleWithOutStartingSpace
                    []
        , Test.test "Correct documentation comment." <|
            \() ->
                checkExpectation
                    []
                    emptyModuleWithDoc
                    []
        , Test.test "Several errors." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace, Check.TodoComment ]
                    moduleWithErrorsInDoc
                    []
        , Test.test "Several errors, all ignored." <|
            \() ->
                checkExpectation
                    []
                    moduleWithErrorsInDoc
                    [ Check.NoStartingSpace, Check.TodoComment ]
        ]


emptyModuleWithDoc : String
emptyModuleWithDoc =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}
"""


emptyModuleWithoutDoc : String
emptyModuleWithoutDoc =
    """module SomeName exposing (..)
"""


moduleWithDocTodo : String
moduleWithDocTodo =
    """module SomeName exposing (..)

{-| This module is empty. todo: change it.
-}
"""


moduleWithDocFixme : String
moduleWithDocFixme =
    """module SomeName exposing (..)

{-| This module is empty. fixme: change it.
-}
"""


moduleWithOutStartingSpace : String
moduleWithOutStartingSpace =
    """module SomeName exposing (..)

{-|This module is empty.
-}
"""


moduleWithErrorsInDoc : String
moduleWithErrorsInDoc =
    """module SomeName exposing (..)

{-|This module is empty. fixme: change it.
-}
"""
