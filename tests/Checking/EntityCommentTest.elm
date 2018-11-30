module Checking.EntityCommentTest exposing (checkEntityCommentTest)

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


checkEntityCommentTest : Test.Test
checkEntityCommentTest =
    let
        checkExpectation expected modString ignored checkAll =
            case TestUtil.stringToIntermediate modString of
                Just m ->
                    m.entities
                        |> List.map (\ent -> Constraints.getViolationsEntity ent checkAll ignored)
                        |> List.concat
                        |> Expect.equalLists expected

                Nothing ->
                    Expect.fail "Failed to parse the module!"
    in
    Test.describe "Test the checker on the entity documentation comments."
        [ Test.test "Module with no comment on exposed function." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment
                    , Constraints.NotAnnotatedArgument "anInt"
                    ]
                    exposedUncommentedFunction
                    []
                    True
        , Test.test "Module with no comment on exposed record." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment
                    , Constraints.NotAnnotatedArgument "aField"
                    , Constraints.NotAnnotatedArgument "anotherField"
                    ]
                    exposedUncommentedRecord
                    []
                    True
        , Test.test "Module with no comment on exposed type def." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment ]
                    exposedUncommentedTypeDef
                    []
                    True
        , Test.test "Module with no comment on exposed type alias." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment ]
                    exposedUncommentedTypeAlias
                    []
                    False
        , Test.describe "Unexposed declarations with no documentation and checkAll=false."
            (List.indexedMap
                (\idx ->
                    \moduleStr ->
                        Test.test
                            ("Unexposed declarations with no documentation and checkAll=false " ++ toString idx)
                        <|
                            \() ->
                                checkExpectation
                                    []
                                    moduleStr
                                    []
                                    False
                )
                [ unexposedUncommentedFunction
                , unexposedUncommentedRecord
                , unexposedUncommentedTypeDef
                , unexposedUncommentedTypeAlias
                ]
            )
        , Test.test "Module with no comment on unexposed function, and checkAll = true." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment
                    , Constraints.NotAnnotatedArgument "anInt"
                    ]
                    unexposedUncommentedFunction
                    []
                    True
        , Test.test "Module with no comment on unexposed record, and checkAll = true." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment
                    , Constraints.NotAnnotatedArgument "aField"
                    , Constraints.NotAnnotatedArgument "anotherField"
                    ]
                    unexposedUncommentedRecord
                    []
                    True
        , Test.test "Module with no comment on unexposed type def, and checkAll = true." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment ]
                    exposedUncommentedTypeDef
                    []
                    True
        , Test.test "Module with no comment on unexposed type alias, and checkAll = true." <|
            \() ->
                checkExpectation
                    [ Constraints.NoEntityComment ]
                    exposedUncommentedTypeAlias
                    []
                    True
        , Test.test "Module with many issues 1." <|
            \() ->
                checkExpectation
                    [ Constraints.NotAnnotatedArgument "anInt"
                    , Constraints.TodoComment
                    , Constraints.NoStartingVerb
                    , Constraints.NoStartingSpace
                    , Constraints.NoEndingPeriod
                    ]
                    largerExample1
                    []
                    True
        , Test.test "Module with many issues 2." <|
            \() ->
                checkExpectation
                    [ Constraints.NotAnnotatedArgument "anInt"
                    , Constraints.NotAnnotatedArgument "anotherInt"
                    , Constraints.NotAnnotatedArgument "aThirdInt"
                    , Constraints.TodoComment
                    , Constraints.NotCapitalized
                    , Constraints.NoStartingVerb
                    , Constraints.NoStartingSpace
                    , Constraints.NoEndingPeriod
                    ]
                    largerExample2
                    []
                    True
        , Test.test "Module with many issues 2, all ignored." <|
            \() ->
                checkExpectation
                    []
                    largerExample2
                    [ Constraints.NotAnnotatedArgument ""
                    , Constraints.TodoComment
                    , Constraints.NotCapitalized
                    , Constraints.NoStartingVerb
                    , Constraints.NoStartingSpace
                    , Constraints.NoEndingPeriod
                    ]
                    True
        ]


exposedCommentedTypeDef : String
exposedCommentedTypeDef =
    """module SomeName exposing (..)

{-| Is a simple type def.
-}
type Something = A | B
"""


exposedUncommentedTypeDef : String
exposedUncommentedTypeDef =
    """module SomeName exposing (..)

type Something = A | B
"""


unexposedUncommentedTypeDef : String
unexposedUncommentedTypeDef =
    """module SomeName exposing (Param)

{-| Contains a correctly documented type alias.
-}
type alias Param = String

type Something = A | B
"""


exposedCommentedTypeAlias : String
exposedCommentedTypeAlias =
    """module SomeName exposing (..)

{-| Is a simple type alias.
-}
type alias Something = String
"""


exposedUncommentedTypeAlias : String
exposedUncommentedTypeAlias =
    """module SomeName exposing (..)

type alias Something = String
"""


unexposedUncommentedTypeAlias : String
unexposedUncommentedTypeAlias =
    """module SomeName exposing (Param)

{-| Contains a correctly documented type alias.
-}
type alias Param = String

type alias Something = String
"""


exposedCommentedRecord : String
exposedCommentedRecord =
    """module SomeName exposing (..)

{-| Is a simple record.
-}
type alias Something =
    { aField : String
    , anotherField : Int
    }
"""


recordWithDocumentedFields : String
recordWithDocumentedFields =
    """module SomeName exposing (..)

{-| Is a simple record.

* ´aField´ &mdash; contains a string.
* ´anotherField´ -- contains an int.
-}
type alias Something =
    { aField : String
    , anotherField : Int
    }
"""


exposedUncommentedRecord : String
exposedUncommentedRecord =
    """module SomeName exposing (..)

type alias Something =
     { aField : String
     , anotherField : Int
     }
"""


unexposedUncommentedRecord : String
unexposedUncommentedRecord =
    """module SomeName exposing (Param)

{-| Contains a correctly documented type alias.
-}
type alias Param = String

type alias Something =
     { aField : String
     , anotherField : Int
     }
"""


exposedCommentedFunction : String
exposedCommentedFunction =
    """module SomeName exposing (..)

{-| Is a simple function.
-}
value : Int -> String
value anInt =
    toString anInt
"""


functionWithDocumentedParams : String
functionWithDocumentedParams =
    """module SomeName exposing (..)


{-| Is a simple function.

* ´anInt´ &mdash; any integer you like.
-}
value : Int -> String
value anInt =
    toString anInt
"""


exposedUncommentedFunction : String
exposedUncommentedFunction =
    """module SomeName exposing (..)

value : Int -> String
value anInt =
    toString anInt
"""


unexposedUncommentedFunction : String
unexposedUncommentedFunction =
    """module SomeName exposing (Param)

{-| Contains a correctly documented type alias.
-}
type alias Param = String

value : Int -> String
value anInt =
    toString anInt
"""


largerExample1 : String
largerExample1 =
    """module SomeName exposing (..)

{-|TODO make this nicer
-}
value : Int -> String
value anInt =
    toString anInt
"""


largerExample2 : String
largerExample2 =
    """module SomeName exposing (Param)

{-| Contains a correctly documented type alias.
-}
type alias Param = String


{-|some value. fixme: add a better doc
-}
value : Int -> Int -> Int -> String
value anInt anotherInt aThirdInt =
    toString anInt
"""
