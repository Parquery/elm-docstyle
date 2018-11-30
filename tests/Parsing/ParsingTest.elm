module Parsing.ParsingTest exposing (parseTest)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.File
import Elm.Syntax.Range
import Expect
import Intermediate
import Models
import Test
import TestUtil


parseTest : Test.Test
parseTest =
    let
        checkExpectation expected modString =
            case TestUtil.stringToIntermediate modString of
                Just parsed ->
                    Expect.equal parsed expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the parsing function in its entirety."
        [ Test.test "Empty module." <|
            \() ->
                checkExpectation
                    { entities = [], moduleName = "SomeName", topLevelComment = Nothing, otherComments = [] }
                    "module SomeName exposing (..)"
        , Test.test "Large example." <|
            \() ->
                checkExpectation
                    { moduleName = "SomeName"
                    , entities =
                        [ { range = TestUtil.range 15 0 15 28
                          , eType = Models.TypeAlias
                          , name = "SomeType"
                          , comment = Just ( TestUtil.range 13 0 14 2, "{-| SomeType is a type.\n-}" )
                          , exposed = True
                          }
                        , { range = TestUtil.range 19 0 19 23
                          , eType = Models.Function []
                          , name = "buildSomeType"
                          , comment = Just ( TestUtil.range 17 0 18 2, "{-| buildSomeType builds some type.\n-}" )
                          , exposed = True
                          }
                        ]
                    , topLevelComment = Just ( TestUtil.range 4 0 5 2, "{-| This module is empty. One day, though...\n-}" )
                    , otherComments = [ ( TestUtil.range 11 0 11 26, "-- just a dangling comment" ) ]
                    }
                    largeExample
        ]


largeExample : String
largeExample =
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
