module Issue exposing (Issue, Trigger(..), fromViolationsAndTrigger, issueToString, unwrap)

import Constraints
import Messages
import Models


{-| A piece fo code triggering an Issue in the comment check.

It can be an entity, a top-level comment or a dangling comment.

-}
type Trigger
    = Entity Models.Entity
    | Dangling Models.Comment
    | TopLevel (Maybe Models.Comment)


{-| Constructor for an Issue, making sure the violations list is not empty.
-}
fromViolationsAndTrigger : List Constraints.Type -> Trigger -> Maybe Issue
fromViolationsAndTrigger violated underlying =
    case violated of
        [] ->
            Nothing

        _ ->
            Just <| Issue { violated = violated, underlying = underlying }


issueToString : Bool -> Issue -> String
issueToString verbose (Issue { violated, underlying }) =
    let
        violatedStr =
            violated
                |> List.map Constraints.violationToMessage
                |> String.join ";\n"
                |> (\s -> s ++ ".")
    in
    case underlying of
        Entity entity ->
            Messages.entityToString entity verbose
                ++ ": "
                ++ violatedStr

        Dangling comment ->
            Messages.commentToString comment verbose
                ++ ": "
                ++ violatedStr

        TopLevel mbcomment ->
            case mbcomment of
                Just comment ->
                    "line 2: "
                        ++ Messages.commentToString comment verbose
                        ++ ": "
                        ++ violatedStr

                Nothing ->
                    "line 2: "
                        ++ violatedStr


{-| An entity can be violating a number of different constraints. They are all reported in an Issue.

To guarantee that at least one constraint is violated, Issue is an opaque type.

-}
type Issue
    = Issue
        { violated : List Constraints.Type
        , underlying : Trigger
        }


unwrap : Issue -> ( List Constraints.Type, Trigger )
unwrap (Issue { violated, underlying }) =
    ( violated, underlying )
