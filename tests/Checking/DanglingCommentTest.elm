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
        [ Test.test "Ok dangling comment 1." <|
            \() ->
                checkExpectation [] moduleWithOkDangling1 []
        , Test.test "Ok dangling comment 2." <|
            \() ->
                checkExpectation [] moduleWithOkDangling2 []
        , Test.test "Empty dangling comment 1." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    ]
                    moduleWithEmptyDangling1
                    []
        , Test.test "Empty dangling comment 2." <|
            \() ->
                checkExpectation
                    [ Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    ]
                    moduleWithEmptyDangling2
                    []
        , Test.test "Wrong dangling comment type." <|
            \() ->
                checkExpectation
                    [ Check.WrongCommentType ]
                    moduleWithDanglingDocComment
                    []
        , Test.test "Larger example." <|
            \() ->
                checkExpectation
                    [ Check.NotCapitalized
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    , Check.TodoComment
                    ]
                    largerExample
                    []
        , Test.test "Larger example, with ignored checks." <|
            \() ->
                checkExpectation
                    []
                    largerExample
                    [ Check.NotCapitalized
                    , Check.NoStartingSpace
                    , Check.NoEndingPeriod
                    , Check.TodoComment
                    ]
        ]


moduleWithOkDangling1 : String
moduleWithOkDangling1 =
    """module SomeName exposing (..)

{- A dangling comment.-}
"""


moduleWithOkDangling2 : String
moduleWithOkDangling2 =
    """module SomeName exposing (..)

-- A dangling comment.
"""


moduleWithEmptyDangling1 : String
moduleWithEmptyDangling1 =
    """module SomeName exposing (..)

{--}
"""


moduleWithEmptyDangling2 : String
moduleWithEmptyDangling2 =
    """module SomeName exposing (..)

--
"""


moduleWithDanglingDocComment : String
moduleWithDanglingDocComment =
    """module SomeName exposing (..)

import String


type alias Tp = Int

{-| This is a well-formed but ill-placed dangling comment.
-}
"""


largerExample : String
largerExample =
    """module SomeName exposing (..)

import String


type alias Tp = Int

--this is a poorly-formed dangling comment. fixme: make it better
"""
