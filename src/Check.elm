module Check exposing (Type(..), commentType, emptyComment, endingPeriod, notAnnotatedArgument, notExistingArgument, startingCapitalized, startingSpace, startingVerb, stringToViolation, todoComment)

{-| Contains the constraints enforced by the checker.
-}


{-| Checks whether the comment's first word is capitalized.
-}
startingCapitalized : String -> Maybe Type
startingCapitalized comment =
    let
        first =
            comment
                |> commentText
                |> String.words
                |> List.head
                |> Maybe.map (String.left 1)
                -- if no words, no violation of the rule.
                |> Maybe.withDefault "A"
    in
    if String.toUpper first == first then
        Nothing

    else
        Just NotCapitalized


{-| Checks whether the comment's delimiter is followed by a space.
-}
startingSpace : String -> Maybe Type
startingSpace comment =
    comment
        |> commentText
        |> (\text ->
                if String.trim text == "" || String.startsWith " " text then
                    Nothing

                else
                    Just NoStartingSpace
           )


{-| Checks whether the comment's first word is a verb in third person (stem -s).
-}
startingVerb : String -> Maybe Type
startingVerb comment =
    let
        firstWord =
            comment
                |> commentText
                |> String.words
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
            comment
                |> commentText
                |> String.trim
                |> String.right 1
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


{-| Checks whether the comment contains any text.
-}
emptyComment : String -> Maybe Type
emptyComment comment =
    comment
        |> commentText
        |> String.words
        |> (\words ->
                if List.any (\word -> String.trim word /= "") words then
                    Nothing

                else
                    Just EmptyComment
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


{-| Removes the comment delimiters from the comment.
-}
commentText : String -> String
commentText comment =
    (if String.startsWith "{-|" comment then
        String.dropLeft 3 comment

     else if String.startsWith "{-" comment then
        String.dropLeft 2 comment

     else if String.startsWith "--" comment then
        String.dropLeft 2 comment

     else
        comment
    )
        |> (\com ->
                if String.endsWith "-}" com then
                    String.dropRight 2 com

                else
                    com
           )


{-| Describes a check violation.
-}
type Type
    = -- the first word should be capitalized.
      NotCapitalized
      -- should start with a space.
    | NoStartingSpace
      -- should start with a verb in present tense and third person (stem -s).
    | NoStartingVerb
      -- should end with a period (ignoring one newline).
    | NoEndingPeriod
      -- should contain some text.
    | EmptyComment
      -- wrong documentation comment "{-|-}" for a non-documentation comment.
    | WrongCommentType
      -- should not contain the strings "to-do" or "fix-me" (without dash).
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

        "EmptyComment" ->
            Just EmptyComment

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
