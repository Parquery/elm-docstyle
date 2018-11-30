module Intermediate exposing (translate)

import Dict
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing
import Elm.Syntax.File
import Elm.Syntax.Module
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Ranged exposing (Ranged)
import Elm.Syntax.TypeAnnotation
import Models


translate : Elm.Syntax.File.File -> Models.ParsedModule
translate file =
    let
        moduleName =
            file.moduleDefinition
                |> Elm.Syntax.Module.moduleName
                |> Maybe.map (String.join ".")
                |> Maybe.withDefault "Unknown module name"

        comments =
            file.comments
                |> List.sortBy (\( range, _ ) -> range.start.row)

        topLevelComment =
            getTopLevelComment file

        entities =
            file.declarations
                |> List.sortBy (\( range, _ ) -> range.start.row)
                |> List.map (\dec -> declarationToEntity dec (isExposed file.moduleDefinition))
                |> List.filterMap identity
                |> List.map
                    (\ent ->
                        if ent.eType == Models.TypeDef then
                            getCommentForType ent comments

                        else
                            ent
                    )

        otherComments =
            comments
                |> (\list ->
                        (Maybe.map (\_ -> List.drop 1 list) topLevelComment
                            |> Maybe.withDefault list
                        )
                            |> List.filter (\com -> not (List.member (Just com) (List.map .comment entities)))
                   )
    in
    { moduleName = moduleName
    , entities = entities
    , topLevelComment = topLevelComment
    , otherComments = otherComments
    }


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


declarationToEntity : Ranged Declaration -> (String -> Bool) -> Maybe Models.Entity
declarationToEntity ( range, declaration ) exp =
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
                    Maybe.map (\docum -> ( docum.range, docum.text )) function.documentation
            in
            Just { entity | name = nm, eType = tp, exposed = exp nm, comment = comment }

        AliasDecl typeAlias ->
            let
                nm =
                    typeAlias.name

                comment =
                    Maybe.map (\docum -> ( docum.range, docum.text )) typeAlias.documentation
            in
            case Tuple.second typeAlias.typeAnnotation of
                Elm.Syntax.TypeAnnotation.Record recordDef ->
                    let
                        fields =
                            List.map Tuple.first recordDef

                        tp =
                            Models.Record fields
                    in
                    Just { entity | name = nm, eType = tp, exposed = exp nm, comment = comment }

                _ ->
                    let
                        tp =
                            Models.TypeAlias

                        nm =
                            typeAlias.name
                    in
                    Just { entity | name = nm, eType = tp, exposed = exp nm, comment = comment }

        TypeDecl tajp ->
            let
                tp =
                    Models.TypeDef

                nm =
                    tajp.name
            in
            Just { entity | name = nm, eType = tp, exposed = exp nm }

        _ ->
            Nothing


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


{-| Deduce the top-level comment, if there's one.
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
                            -- if there are no imports, use the line of the first declaration
                            rowFirstDeclaration
                                |> Maybe.map toFloat
                                -- if there are no declarations, then any docs comment will be the module comment.
                                |> Maybe.withDefault (1 / 0)
            in
            String.startsWith "{-|" comment && toFloat range.start.row < firstRow

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
