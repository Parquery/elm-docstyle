module Issue exposing (Issue, Trigger(..), fromViolationsAndTrigger, unwrap)

{-| Wraps a comment or declaration with its violated checks.
-}

import Check
import Models


{-| Contains the piece of code violating a check.

It can be an entity, a top-level comment or a dangling comment.

-}
type Trigger
    = Entity Models.Entity
    | Dangling Models.Comment
    | TopLevel (Maybe Models.Comment)


{-| Constructs an Issue, making sure the violations list is not empty.
-}
fromViolationsAndTrigger : List Check.Type -> Trigger -> Maybe Issue
fromViolationsAndTrigger violated underlying =
    case violated of
        [] ->
            Nothing

        _ ->
            Just <| Issue { violated = violated, underlying = underlying }


{-| Encapsulates a trigger and at least one violated check.

To guarantee that at least one constraint is violated, Issue is an opaque type.
The only way to construct an Issue is through the constructor function above.

-}
type Issue
    = Issue
        { violated : List Check.Type
        , underlying : Trigger
        }


{-| Unwraps the opaque issue type, allowing access to its fields.
-}
unwrap : Issue -> ( List Check.Type, Trigger )
unwrap (Issue { violated, underlying }) =
    ( violated, underlying )
