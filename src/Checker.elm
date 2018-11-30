module Checker exposing (getIssues, getIssuesJSON, getIssuesString)

import Configuration
import Constraints
import Encoders
import Issue
import Json.Encode
import Models


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
            Constraints.getViolationsTopLevel parsed.topLevelComment ignoredChecks
                |> (\violated -> Issue.fromViolationsAndTrigger violated (Issue.TopLevel parsed.topLevelComment))
                |> (\issue -> [ ( topLevelLine, issue ) ])

        otherCommentsIssues =
            parsed.otherComments
                |> List.map (\comment -> ( comment, Constraints.getViolationsDangling comment ignoredChecks ))
                |> List.map (\( comment, violated ) -> ( comment, Issue.fromViolationsAndTrigger violated (Issue.Dangling comment) ))
                |> List.map (\( ( range, _ ), issue ) -> ( range.start.row, issue ))

        entityIssues =
            parsed.entities
                |> List.map (\ent -> ( ent, Constraints.getViolationsEntity ent checkAll ignoredChecks ))
                |> List.map (\( ent, viol ) -> ( ent.range.start.row, Issue.fromViolationsAndTrigger viol (Issue.Entity ent) ))
    in
    List.concat [ topLevelCommentIssues, otherCommentsIssues, entityIssues ]
        |> List.sortBy (\( row, _ ) -> row)
        |> List.map (\( _, iss ) -> iss)
        |> List.filterMap identity


{-| Returns the string representation of the failed checks.
-}
getIssuesString : Models.ParsedModule -> Configuration.Model -> String
getIssuesString parsed config =
    getIssues parsed config
        |> List.map (Issue.issueToString config.verbose)
        |> List.map (\str -> parsed.moduleName ++ ": " ++ str)
        |> String.join "\n"


{-| Returns the JSON representation of the failed checks.
-}
getIssuesJSON : Models.ParsedModule -> Configuration.Model -> Json.Encode.Value
getIssuesJSON parsed config =
    getIssues parsed config
        |> (\issues -> Json.Encode.list (List.map Encoders.encodeIssue issues))
