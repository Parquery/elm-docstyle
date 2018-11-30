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
                [ emptyModuleWithDoc
                , emptyModuleWithoutDoc
                , moduleNoDeclarationsWithDoc
                , moduleNoDeclarationsWithoutDoc
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
                [ moduleNoImportsWithDoc
                , moduleNoImportsWithoutDoc
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
                [ moduleWithWrongTypeDocFormat1
                , moduleWithWrongTypeDocFormat2
                ]
            )
        , Test.test "Module with documented type 1." <|
            \() ->
                checkExpectation (expectedComment 2 0 3 2)
                    moduleWithDocumentedTypeAndNoDoc
        , Test.test "Module with documented type 2." <|
            \() ->
                checkExpectation (expectedComment 5 0 6 2)
                    moduleWithDocumentedTypeAndDoc
        , Test.test "Module with documented type 3." <|
            \() ->
                checkExpectation (expectedComment 9 0 10 2)
                    moduleWithDocumentedTypeAndImportsAndDoc
        , Test.test "Module with documented type 4." <|
            \() ->
                checkExpectation (expectedComment 11 0 12 2)
                    largerExample
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


moduleWithWrongTypeDocFormat1 : String
moduleWithWrongTypeDocFormat1 =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

{- SomeType is a type.
-}
type alias SomeType = String
"""


moduleWithWrongTypeDocFormat2 : String
moduleWithWrongTypeDocFormat2 =
    """module SomeName exposing (..)

{-| This module is empty. One day, though...
-}

-- SomeType is a type.
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
