module Checker exposing (getIssues, getIssuesJSON, getIssuesString)

{-| Contains the logic for analyzing the parsed module.
-}

import Configuration
import Encoders
import Issue
import Json.Encode
import Models
import Violations


{-| Converts the parsed module to a list of issues.

  - `model` -- the parsed module code.
  - `config` -- the configuration containing ignored checks and settings.

-}
getIssues : Models.ParsedModule -> Configuration.Model -> List Issue.Issue
getIssues parsed config =
    let
        ignoredChecks =
            config.excludedChecks

        checkAll =
            config.checkAllDefinitions

        topLevelLine =
            parsed.topLevelComment
                |> Maybe.map (\( range, _ ) -> range.start.row)
                |> Maybe.withDefault 1

        topLevelCommentIssues =
            Violations.topLevel parsed.topLevelComment ignoredChecks
                |> (\violated ->
                        Issue.fromViolationsAndTrigger
                            violated
                            (Issue.TopLevel parsed.topLevelComment)
                   )
                |> (\issue -> [ ( topLevelLine, issue ) ])

        otherCommentsIssues =
            parsed.otherComments
                |> List.map
                    (\comment ->
                        ( comment
                        , Violations.dangling comment ignoredChecks
                        )
                    )
                |> List.map
                    (\( comment, violated ) ->
                        ( comment
                        , Issue.fromViolationsAndTrigger
                            violated
                            (Issue.Dangling comment)
                        )
                    )
                |> List.map
                    (\( ( range, _ ), issue ) ->
                        ( range.start.row
                        , issue
                        )
                    )

        entityIssues =
            parsed.entities
                |> List.map
                    (\ent ->
                        ( ent
                        , Violations.entity ent checkAll ignoredChecks
                        )
                    )
                |> List.map
                    (\( ent, violated ) ->
                        ( ent.range.start.row
                        , Issue.fromViolationsAndTrigger
                            violated
                            (Issue.Entity ent)
                        )
                    )
    in
    List.concat [ topLevelCommentIssues, otherCommentsIssues, entityIssues ]
        |> List.sortBy (\( row, _ ) -> row)
        |> List.map (\( _, iss ) -> iss)
        |> List.filterMap identity


{-| Represents the failed checks as strings.
-}
getIssuesString : Models.ParsedModule -> Configuration.Model -> String
getIssuesString parsed config =
    getIssues parsed config
        |> List.map (Issue.issueToString config.verbose)
        |> List.map (\str -> parsed.moduleName ++ ": " ++ str)
        |> String.join "\n"


{-| Represents the failed checks as a JSON object.
-}
getIssuesJSON : Models.ParsedModule -> Configuration.Model -> Json.Encode.Value
getIssuesJSON parsed config =
    getIssues parsed config
        |> (\issues -> Json.Encode.list (List.map Encoders.encodeIssue issues))
