module Parsing.TopLevelCommentTest exposing (parseTopLevelCommentTest)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil


parseTopLevelCommentTest : Test.Test
parseTopLevelCommentTest =
    let
        expectedDocs =
            Just ( TestUtil.range 2 0 3 2, "{-| This module is empty. One day, though...\n-}" )

        checkExpectation expected modString =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    Expect.equal m.topLevelComment expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the intermediate representation parsing function for the top level comment."
        [ Test.test "Empty module with doc." <|
            \() ->
                checkExpectation expectedDocs emptyModuleWithDoc
        , Test.test "Empty module without doc." <|
            \() ->
                checkExpectation Nothing emptyModuleWithoutDoc
        , Test.test "Module with doc and no imports." <|
            \() ->
                checkExpectation expectedDocs moduleNoImportsWithDoc
        , Test.test "Module without doc and no imports." <|
            \() ->
                checkExpectation Nothing moduleNoImportsWithoutDoc
        , Test.test "Module with doc and no declarations." <|
            \() ->
                checkExpectation expectedDocs moduleNoDeclarationsWithDoc
        , Test.test "Module without doc and no declarations." <|
            \() ->
                checkExpectation Nothing moduleNoDeclarationsWithoutDoc
        , Test.test "Module with doc and commented declaration." <|
            \() ->
                checkExpectation expectedDocs moduleWithDocumentedTypeAndDoc
        , Test.test "Module without doc and commented declaration." <|
            \() ->
                checkExpectation Nothing moduleWithDocumentedTypeAndNoDoc
        , Test.test "Module with doc and imports and commented declaration." <|
            \() ->
                checkExpectation expectedDocs moduleWithDocumentedTypeAndImportsAndDoc
        , Test.test "Larger example." <|
            \() ->
                checkExpectation
                    (Just ( TestUtil.range 4 0 5 2, "{-| This module is empty. One day, though...\n-}" ))
                    largerExample
        , Test.test "Doc with wrong comment type 1." <|
            \() ->
                checkExpectation Nothing moduleWithWrongDocsType1
        , Test.test "Doc with wrong comment type 2." <|
            \() ->
                checkExpectation Nothing moduleWithWrongDocsType2
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
