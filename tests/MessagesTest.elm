module MessagesTest exposing (entityToString)

import Elm.Syntax.Range exposing (Range)
import Expect
import Messages
import Models exposing (EntityType(..))
import Test


entityToString : Test.Test
entityToString =
    Test.describe "Test the entityToString function."
        [ Test.test "Test 1." <|
            \() ->
                Expect.equal
                    "line 13, type alias \"someTypeAlias\" with no comment"
                    (let
                        entity =
                            { range = aRange
                            , eType = TypeAlias
                            , name = "someTypeAlias"
                            , comment = Nothing
                            , exposed = False
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test 2." <|
            \() ->
                Expect.equal
                    "line 13, exposed function with no parameters \"someParameterLessFunction\" with comment \"{-|A function used for some computation.\n-}\""
                    (let
                        entity =
                            { range = aRange
                            , eType = Function []
                            , name = "someParameterLessFunction"
                            , comment = Just ( anotherRange, "{-|A function used for some computation.\n-}" )
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test 3." <|
            \() ->
                Expect.equal
                    "line 13, function with parameters (aString, anInt) \"someFunction\" with comment \"{-|A function with parameters used for some computation.\n-}\""
                    (let
                        entity =
                            { range = aRange
                            , eType = Function [ "aString", "anInt" ]
                            , name = "someFunction"
                            , comment = Just ( anotherRange, "{-|A function with parameters used for some computation.\n-}" )
                            , exposed = False
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test 4." <|
            \() ->
                Expect.equal
                    "line 13, exposed record with fields (aMap, aListOfInts) \"SomeRecord\" with comment \"{-|A record.\n-}\""
                    (let
                        entity =
                            { range = aRange
                            , eType = Record [ "aMap", "aListOfInts" ]
                            , name = "SomeRecord"
                            , comment = Just ( anotherRange, "{-|A record.\n-}" )
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity True
                    )
        , Test.test "Test 5." <|
            \() ->
                Expect.equal
                    "line 13, exposed type definition \"SomeType\""
                    (let
                        entity =
                            { range = aRange
                            , eType = TypeDef
                            , name = "SomeType"
                            , comment = Nothing
                            , exposed = True
                            }
                     in
                     Messages.entityToString entity False
                    )
        ]


aRange : Range
aRange =
    { start = { row = 12, column = 1 }
    , end = { row = 14, column = 1 }
    }


anotherRange : Range
anotherRange =
    { start = { row = 10, column = 1 }
    , end = { row = 11, column = 1 }
    }
