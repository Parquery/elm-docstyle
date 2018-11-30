module Checking.TopLevelCommentTest exposing (checkTopLevelCommentTest)

import Constraints
import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil


checkTopLevelCommentTest : Test.Test
checkTopLevelCommentTest =
    let
        checkExpectation expected modString ignored =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Constraints.getViolationsTopLevel m.topLevelComment ignored
                        |> Expect.equalLists expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the checker on the top-level documentation comment."
        [ Test.test "No documentation comment." <|
            \() ->
                checkExpectation [ Constraints.NoTopLevelComment ] emptyModuleWithoutDoc []
        , Test.test "No documentation comment but NoTopLevelComment error ignored." <|
            \() ->
                checkExpectation [] emptyModuleWithoutDoc [ Constraints.NoTopLevelComment ]
        , Test.test "t.o.d.o in documentation." <|
            \() ->
                checkExpectation [ Constraints.TodoComment ] moduleWithDocTodo []
        , Test.test "f.i.x.m.e in documentation." <|
            \() ->
                checkExpectation [ Constraints.TodoComment ] moduleWithDocFixme []
        , Test.test "no starting space in documentation." <|
            \() ->
                checkExpectation [ Constraints.NoStartingSpace ] moduleWithOutStartingSpace []
        , Test.test "Correct documentation comment." <|
            \() ->
                checkExpectation [] emptyModuleWithDoc []
        , Test.test "Several errors." <|
            \() ->
                checkExpectation [ Constraints.NoStartingSpace, Constraints.TodoComment ] moduleWithErrorsInDoc []
        , Test.test "Several errors, all ignored." <|
            \() ->
                checkExpectation [] moduleWithErrorsInDoc [ Constraints.NoStartingSpace, Constraints.TodoComment ]
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
