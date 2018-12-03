module ConfigTest exposing (configTest)

{-| Tests the configuration functions.
-}

import Check
import Configuration
import Elm.Syntax.Range exposing (Range)
import Expect
import Models exposing (EntityType(..))
import Test


{-| Tests the correct parsing of the configuration from flags.
-}
configTest : Test.Test
configTest =
    Test.describe "Test config parsing."
        [ Test.test "Test that flags are correctly parsed with format=JSON." <|
            \() ->
                Expect.equal
                    (Ok
                        { excludedChecks = []
                        , checkAllDefinitions = True
                        , verbose = True
                        , format = Configuration.JSON
                        }
                    )
                    (let
                        flags =
                            { format = "json"
                            , verbose = True
                            , excludedChecks = []
                            , checkAllDefinitions = True
                            }
                     in
                     Configuration.fromFlags flags
                    )
        , Test.test "Test that flags are correctly parsed with format=HUMAN." <|
            \() ->
                Expect.equal
                    (Ok
                        { excludedChecks = []
                        , checkAllDefinitions = False
                        , verbose = False
                        , format = Configuration.HUMAN
                        }
                    )
                    (let
                        flags =
                            { format = "human"
                            , verbose = False
                            , excludedChecks = []
                            , checkAllDefinitions = False
                            }
                     in
                     Configuration.fromFlags flags
                    )
        , Test.test "Test that wrong flags throw an error." <|
            \() ->
                Expect.equal
                    (Err
                        ("Failed to parse the format flag. Expected \"\", "
                            ++ "\"human\" or \"json\", got: somethingelse"
                        )
                    )
                    (let
                        flags =
                            { format = "somethingelse"
                            , verbose = False
                            , excludedChecks = []
                            , checkAllDefinitions = False
                            }
                     in
                     Configuration.fromFlags flags
                    )
        , Test.test "Test that excluded checks are correctly parsed (small test)." <|
            \() ->
                Expect.equal
                    [ Check.TodoComment
                    , Check.WrongCommentType
                    , Check.NotAnnotatedArgument ""
                    ]
                    (Configuration.fromFlags
                        { format = "human"
                        , verbose = False
                        , excludedChecks =
                            [ "TodoComment"
                            , "WrongCommentType"
                            , "NotAnnotatedArgument"
                            ]
                        , checkAllDefinitions = False
                        }
                        |> Result.map .excludedChecks
                        |> Result.withDefault []
                    )
        , Test.test "Test that excluded checks are correctly parsed (larger test)." <|
            \() ->
                Expect.equal
                    [ Check.NotCapitalized
                    , Check.NoStartingVerb
                    , Check.NoStartingSpace
                    , Check.NoEntityComment
                    , Check.NoEndingPeriod
                    , Check.NoTopLevelComment
                    , Check.NotExistingArgument ""
                    ]
                    (Configuration.fromFlags
                        { format = "human"
                        , verbose = False
                        , excludedChecks =
                            [ "NotCapitalized"
                            , "NoStartingVerb"
                            , "NoStartingSpace"
                            , "NoEntityComment"
                            , "NoEndingPeriod"
                            , "NoTopLevelComment"
                            , "NotExistingArgument"
                            ]
                        , checkAllDefinitions = False
                        }
                        |> Result.map .excludedChecks
                        |> Result.withDefault []
                    )
        , Test.test "Test that non-existing excluded checks throw an error." <|
            \() ->
                Expect.equal
                    (Err
                        ("Illegal check name(s): \"SomeCheck\""
                            ++ ", \"SomeOtherCheck\"."
                        )
                    )
                    (Configuration.fromFlags
                        { format = "human"
                        , verbose = False
                        , excludedChecks =
                            [ "SomeCheck"
                            , "SomeOtherCheck"
                            , "TodoComment"
                            , "WrongCommentType"
                            ]
                        , checkAllDefinitions = False
                        }
                    )
        ]
