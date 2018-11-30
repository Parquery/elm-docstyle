module Check exposing (Type(..), commentType, endingPeriod, notAnnotatedArgument, notExistingArgument, startingCapitalized, startingSpace, startingVerb, stringToViolation, todoComment)

{-| Contains the constraints enforced by the checker.
-}


{-| Checks whether the comment's first word is capitalized.
-}
startingCapitalized : String -> Maybe Type
startingCapitalized comment =
    let
        first =
            String.words comment
                |> List.head
                -- if no words, no violation of the rule.
                |> Maybe.withDefault "A"
    in
    if String.toUpper first == first then
        Nothing

    else
        Just NotCapitalized


{-| Checks whether the comment's first character after the delimiter is a space.
-}
startingSpace : String -> Maybe Type
startingSpace comment =
    if
        String.startsWith "{- " comment
            || String.startsWith "-- " comment
            || String.startsWith "{-| " comment
    then
        Nothing

    else
        Just NoStartingSpace


{-| Checks whether the comment's first word is a verb in third person (stem -s).
-}
startingVerb : String -> Maybe Type
startingVerb comment =
    let
        firstWord =
            String.words comment
                -- drop the prefix (--, {- or {-|).
                |> List.drop 1
                |> List.head
                -- if no words, no violation of the rule.
                |> Maybe.withDefault "s"
    in
    if String.endsWith "s" firstWord then
        Nothing

    else
        Just NoStartingVerb


{-| Checks whether the comment's last character is a period.

It ignores the comment delimiter and newlines.

-}
endingPeriod : String -> Maybe Type
endingPeriod comment =
    let
        last =
            if String.endsWith "-}" comment then
                comment
                    |> String.dropRight 2
                    |> String.trim
                    |> String.right 1

            else
                String.right 1 comment
    in
    if last == "." || last == "" then
        Nothing

    else
        Just NoEndingPeriod


{-| Checks whether the comment contains f.i.x.m.e or t.o.d.o (with no dots).
-}
todoComment : String -> Maybe Type
todoComment comment =
    comment
        |> String.toLower
        |> (\str ->
                if
                    String.contains "todo" str
                        || String.contains "fixme" str
                then
                    Just TodoComment

                else
                    Nothing
           )


{-| Checks whether the comment is a documentation comment.
-}
commentType : String -> Maybe Type
commentType comment =
    if String.startsWith "{-|" comment then
        Just WrongCommentType

    else
        Nothing


{-| Checks whether the argument name does not appear in the comment.
-}
notAnnotatedArgument : List String -> String -> Maybe Type
notAnnotatedArgument parsedArguments shouldBeAnnotated =
    if List.member shouldBeAnnotated parsedArguments then
        Nothing

    else
        Just <| NotAnnotatedArgument shouldBeAnnotated


{-| Checks whether non-existing argument names appear in the comment.
-}
notExistingArgument : List String -> List String -> List Type
notExistingArgument parsedArguments allowed =
    parsedArguments
        |> List.filter (\el -> not (List.member el allowed))
        |> List.map NotExistingArgument


{-| Describes a check violation.
-}
type Type
    = -- the first word should be capitalized.
      NotCapitalized
      -- the comment should start with a space.
    | NoStartingSpace
      -- the comment should start with a verb in present tense and third person (stem -s).
    | NoStartingVerb
      -- the comment should end with a period (ignoring one newline).
    | NoEndingPeriod
      -- wrong documentation comment type "{-|-}" for a non-documentation comment.
    | WrongCommentType
      -- the comment should not contain the strings (with no dots) "t.o.d.o" or "f.i.x.m.e".
    | TodoComment
      -- a comment is expected on top of the entity.
    | NoEntityComment
      -- a top level comment is expected.
    | NoTopLevelComment
      -- an argument appearing in the documentation does not exist.
    | NotExistingArgument String
      -- an argument appearing in the function is not documented.
    | NotAnnotatedArgument String


{-| Parses a string to a check.
-}
stringToViolation : String -> Maybe Type
stringToViolation str =
    case str of
        "NoStartingSpace" ->
            Just NoStartingSpace

        "NotCapitalized" ->
            Just NotCapitalized

        "NoStartingVerb" ->
            Just NoStartingVerb

        "NoEndingPeriod" ->
            Just NoEndingPeriod

        "WrongCommentType" ->
            Just WrongCommentType

        "TodoComment" ->
            Just TodoComment

        "NoEntityComment" ->
            Just NoEntityComment

        "NoTopLevelComment" ->
            Just NoTopLevelComment

        "NotExistingArgument" ->
            Just <| NotExistingArgument ""

        "NotAnnotatedArgument" ->
            Just <| NotAnnotatedArgument ""

        _ ->
            Nothing
