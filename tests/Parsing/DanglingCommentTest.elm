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
                            (\() -> checkNoDanglingComments moduleStr)
                )
                [ emptyModuleWithDoc
                , emptyModuleWithoutDoc
                , moduleNoImportsWithDoc
                , moduleNoImportsWithoutDoc
                , moduleNoDeclarationsWithDoc
                , moduleNoDeclarationsWithoutDoc
                , moduleWithDocumentedTypeAndDoc
                , moduleWithDocumentedTypeAndNoDoc
                , moduleWithDocumentedTypeAndImportsAndDoc
                , largerExample
                ]
            )
        , Test.test "Module with wrong top-level parsed as dangling (1)." <|
            \() ->
                checkExpectation
                    (expectedComment 4
                        0
                        5
                        2
                        "{- This module is empty. One day, though...\n-}"
                    )
                    moduleWithWrongDocsType1
        , Test.test "Module with wrong top-level parsed as dangling (2)." <|
            \() ->
                checkExpectation
                    (expectedComment 4
                        0
                        4
                        43
                        "-- This module is empty. One day, though..."
                    )
                    moduleWithWrongDocsType2
        , Test.test "Module with dangling comment 1." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        26
                        "-- just a dangling comment"
                    )
                    moduleWithDanglingComment1
        , Test.test "Module with dangling comment 2." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        29
                        "{- just a dangling comment -}"
                    )
                    moduleWithDanglingComment2
        , Test.test "Module with dangling comment 3." <|
            \() ->
                checkExpectation
                    (expectedComment 11
                        0
                        11
                        30
                        "{-| just a dangling comment -}"
                    )
                    moduleWithDanglingComment3
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


moduleNoImportsWithDoc : String
moduleNoImportsWithDoc =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

type alias SomeType = String
"""


moduleNoImportsWithoutDoc : String
moduleNoImportsWithoutDoc =
    """module SomeName exposing (..)

type alias SomeType = String
"""


moduleNoDeclarationsWithDoc : String
moduleNoDeclarationsWithDoc =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

import Dict
import List
"""


moduleNoDeclarationsWithoutDoc : String
moduleNoDeclarationsWithoutDoc =
    """module SomeName exposing (..)

import Dict
import List
"""


moduleWithDocumentedTypeAndNoDoc : String
moduleWithDocumentedTypeAndNoDoc =
    """module SomeName exposing (..)

{-| SomeType is a type.
-}
type alias SomeType = String
"""


moduleWithDocumentedTypeAndDoc : String
moduleWithDocumentedTypeAndDoc =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

{-| SomeType is a type.
-}
type alias SomeType = String
"""


moduleWithDocumentedTypeAndImportsAndDoc : String
moduleWithDocumentedTypeAndImportsAndDoc =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

import Dict
import List
import Models

{-| SomeType is a type.
-}
type alias SomeType = String
"""


largerExample : String
largerExample =
    """module SomeName exposing (SomeType
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


moduleWithWrongDocsType1 : String
moduleWithWrongDocsType1 =
    """module SomeName exposing (SomeType
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


moduleWithWrongDocsType2 : String
moduleWithWrongDocsType2 =
    """module SomeName exposing (SomeType
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


moduleWithDanglingComment1 : String
moduleWithDanglingComment1 =
    """module SomeName exposing (SomeType
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


moduleWithDanglingComment2 : String
moduleWithDanglingComment2 =
    """module SomeName exposing (SomeType
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


moduleWithDanglingComment3 : String
moduleWithDanglingComment3 =
    """module SomeName exposing (SomeType
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
