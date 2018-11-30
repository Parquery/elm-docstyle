module ConfigTest exposing (configTest)

import Configuration
import Constraints
import Elm.Syntax.Range exposing (Range)
import Expect
import Models exposing (EntityType(..))
import Test


configTest : Test.Test
configTest =
    Test.describe "Test config parsing."
        [ Test.test "Test that flags are correctly parsed 1." <|
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
        , Test.test "Test that flags are correctly parsed 2." <|
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
                        """Failed to parse the format flag. Expected "", "human" or "json", got: somethingelse"""
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
        , Test.test "Test that excluded checks are correctly parsed 1." <|
            \() ->
                Expect.equal
                    [ Constraints.TodoComment
                    , Constraints.WrongCommentType
                    , Constraints.NotAnnotatedArgument ""
                    ]
                    (Configuration.fromFlags
                        { format = "human"
                        , verbose = False
                        , excludedChecks = [ "TodoComment", "WrongCommentType", "NotAnnotatedArgument" ]
                        , checkAllDefinitions = False
                        }
                        |> Result.map .excludedChecks
                        |> Result.withDefault []
                    )
        , Test.test "Test that excluded checks are correctly parsed 2." <|
            \() ->
                Expect.equal
                    [ Constraints.NotCapitalized
                    , Constraints.NoStartingVerb
                    , Constraints.NoStartingSpace
                    , Constraints.NoEntityComment
                    , Constraints.NoEndingPeriod
                    , Constraints.NoTopLevelComment
                    , Constraints.NotExistingArgument ""
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
        , Test.test "Test that non-existing checks throw an error." <|
            \() ->
                Expect.equal
                    (Err """Illegal check name(s): "SomeCheck", "SomeOtherCheck".""")
                    (Configuration.fromFlags
                        { format = "human"
                        , verbose = False
                        , excludedChecks = [ "SomeCheck", "SomeOtherCheck", "TodoComment", "WrongCommentType" ]
                        , checkAllDefinitions = False
                        }
                    )
        ]
