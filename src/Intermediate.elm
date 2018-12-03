module Intermediate exposing (translate)

{-| Contains the logic for parsing an Elm source file into the intermediate representation.
-}

import Dict
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing
import Elm.Syntax.File
import Elm.Syntax.Module
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Ranged exposing (Ranged)
import Elm.Syntax.TypeAnnotation
import Models


{-| Translates a module parsed by elm-syntax to a custom representation.

  - ´moduleDefinition´ -- contains the name and type of the parse module.
  - ´imports´ -- the list of imports.
  - ´declarations´ -- the list of type and function declarations, along
    with their corresponding documentation comment (if it exists).
  - ´comments´ -- all the comments in the module that do not belong to a declaration.

-}
translate : Elm.Syntax.File.File -> Models.ParsedModule
translate ({ moduleDefinition, imports, declarations, comments } as file) =
    let
        moduleName =
            moduleDefinition
                |> Elm.Syntax.Module.moduleName
                |> Maybe.map (String.join ".")
                |> Maybe.withDefault "Unknown module name"

        sortedComments =
            List.sortBy (\( range, _ ) -> range.start.row) comments

        topLevelComment =
            getTopLevelComment file

        entities =
            declarations
                |> List.sortBy (\( range, _ ) -> range.start.row)
                |> List.map
                    (\dec ->
                        declarationToEntity
                            dec
                            (isExposed moduleDefinition)
                    )
                |> List.filterMap identity
                |> List.map
                    (\ent ->
                        if ent.eType == Models.TypeDef then
                            getCommentForType ent sortedComments

                        else
                            ent
                    )

        otherComments =
            sortedComments
                |> (\list ->
                        (Maybe.map (\_ -> List.drop 1 list) topLevelComment
                            |> Maybe.withDefault list
                        )
                            |> List.filter
                                (\com ->
                                    not
                                        (List.member
                                            (Just com)
                                            (List.map .comment entities)
                                        )
                                )
                   )
    in
    { moduleName = moduleName
    , entities = entities
    , topLevelComment = topLevelComment
    , otherComments = otherComments
    }


{-| Determines whether a declaration is exposed by the module.
-}
isExposed : Elm.Syntax.Module.Module -> String -> Bool
isExposed mod entityName =
    case Elm.Syntax.Module.exposingList mod of
        Elm.Syntax.Exposing.All _ ->
            True

        Elm.Syntax.Exposing.Explicit exposureList ->
            exposureList
                |> List.map Tuple.second
                |> List.any
                    (\x ->
                        case x of
                            Elm.Syntax.Exposing.FunctionExpose fun ->
                                fun == entityName

                            Elm.Syntax.Exposing.InfixExpose infx ->
                                infx == entityName

                            Elm.Syntax.Exposing.TypeOrAliasExpose tajp ->
                                tajp == entityName

                            Elm.Syntax.Exposing.TypeExpose tajp ->
                                tajp.name == entityName
                    )


{-| Translates a declaration parsed by the Elm.Syntax library to the intermediate representation.

  - ´exposedFn´ -- partially applied function which determines whether a
    declaration name is exposed by the module.

-}
declarationToEntity :
    Ranged Declaration
    -> (String -> Bool)
    -> Maybe Models.Entity
declarationToEntity ( range, declaration ) exposedFn =
    let
        entity =
            { range = range
            , eType = Models.TypeDef
            , name = ""
            , comment = Nothing
            , exposed = False
            }
    in
    case declaration of
        FuncDecl function ->
            let
                paramNames =
                    function.declaration.arguments
                        |> List.map Tuple.second
                        |> List.map getVarNamesFromPattern
                        |> List.concat

                tp =
                    Models.Function paramNames

                nm =
                    function.declaration.name.value

                comment =
                    function.documentation
                        |> Maybe.map (\docum -> ( docum.range, docum.text ))
            in
            Just
                { entity
                    | name = nm
                    , eType = tp
                    , exposed = exposedFn nm
                    , comment = comment
                }

        AliasDecl typeAlias ->
            let
                nm =
                    typeAlias.name

                comment =
                    typeAlias.documentation
                        |> Maybe.map (\docum -> ( docum.range, docum.text ))
            in
            case Tuple.second typeAlias.typeAnnotation of
                Elm.Syntax.TypeAnnotation.Record recordDef ->
                    let
                        fields =
                            List.map Tuple.first recordDef

                        tp =
                            Models.Record fields
                    in
                    Just
                        { entity
                            | name = nm
                            , eType = tp
                            , exposed = exposedFn nm
                            , comment = comment
                        }

                _ ->
                    let
                        tp =
                            Models.TypeAlias

                        nm =
                            typeAlias.name
                    in
                    Just
                        { entity
                            | name = nm
                            , eType = tp
                            , exposed = exposedFn nm
                            , comment = comment
                        }

        TypeDecl tajp ->
            let
                tp =
                    Models.TypeDef

                nm =
                    tajp.name
            in
            Just
                { entity
                    | name = nm
                    , eType = tp
                    , exposed = exposedFn nm
                }

        _ ->
            Nothing


{-| Deduces all variable names by exploring the variable list recursively.
-}
getVarNamesFromPattern : Pattern -> List String
getVarNamesFromPattern pattern =
    let
        recurseFurther : List (Ranged Pattern) -> List String -> List String
        recurseFurther patterns names =
            patterns
                |> List.map (\( _, p ) -> deduceNames p [])
                |> List.concat
                |> List.append names

        deduceNames : Pattern -> List String -> List String
        deduceNames patt names =
            case patt of
                VarPattern name ->
                    name :: names

                TuplePattern ptrns ->
                    recurseFurther ptrns names

                ListPattern ptrns ->
                    recurseFurther ptrns names

                RecordPattern flds ->
                    flds
                        |> List.map .value
                        |> List.append names

                UnConsPattern ptrn1 ptrn2 ->
                    recurseFurther [ ptrn1, ptrn2 ] names

                ParenthesizedPattern ptrn ->
                    recurseFurther [ ptrn ] names

                NamedPattern _ ptrns ->
                    recurseFurther ptrns names

                AsPattern ptrn _ ->
                    recurseFurther [ ptrn ] names

                _ ->
                    names
    in
    deduceNames pattern []
        |> List.filter (\s -> s /= "_")


{-| Deduces the top-level comment, if there's one.
-}
getTopLevelComment : Elm.Syntax.File.File -> Maybe Models.Comment
getTopLevelComment file =
    let
        rowFirstImport : Maybe Int
        rowFirstImport =
            file.imports
                |> List.map (\imp -> imp.range.start.row)
                |> List.minimum

        rowFirstDeclaration : Maybe Int
        rowFirstDeclaration =
            file.declarations
                |> List.map (\( range, _ ) -> range.start.row)
                |> List.minimum

        isTopLevel : Models.Comment -> Bool
        isTopLevel ( range, comment ) =
            let
                firstRow =
                    case rowFirstImport of
                        Just row ->
                            toFloat row

                        Nothing ->
                            -- if there are no imports, use the line of the first declaration.
                            rowFirstDeclaration
                                |> Maybe.map toFloat
                                -- if there are no declarations, any docs comment will be the module comment.
                                |> Maybe.withDefault (1 / 0)
            in
            String.startsWith "{-|" comment
                && (toFloat range.start.row < firstRow)

        firstComment : Maybe Models.Comment
        firstComment =
            file.comments
                |> List.sortBy (\( range, _ ) -> range.start.row)
                |> List.head
    in
    firstComment
        |> Maybe.andThen
            (\rangedComment ->
                if isTopLevel rangedComment then
                    Just rangedComment

                else
                    Nothing
            )


{-| Assigns a documentation level to Union Types.

This step is necessary since the Elm.Syntax parser doesn't assign documentation
comments to union types.

-}
getCommentForType : Models.Entity -> List Models.Comment -> Models.Entity
getCommentForType entity comments =
    let
        foundComment =
            comments
                |> List.map (\( rng, comm ) -> ( rng.end.row, ( rng, comm ) ))
                |> Dict.fromList
                |> Dict.get (entity.range.start.row - 1)
    in
    { entity | comment = foundComment }
