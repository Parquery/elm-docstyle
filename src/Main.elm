port module Main exposing (main)

{-| Is the main module of the application.
-}

import Checker
import Configuration
import Elm.Parser
import Elm.Processing
import Intermediate
import Json.Decode as Decode
import Json.Encode as Encode
import Models


type alias Model =
    { humanReadableResult : String
    , config : Configuration.Model
    }


init : Models.Flags -> ( Model, Cmd Msg )
init flags =
    case Configuration.fromFlags flags of
        Ok config ->
            ( { humanReadableResult = ""
              , config = config
              }
            , toPort (Encode.string "")
            )

        Err e ->
            ( { humanReadableResult = e
              , config = Configuration.defaultModel
              }
            , toPort (Encode.string e)
            )


type Msg
    = Process String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Process str ->
            case Elm.Parser.parse str of
                Ok ast ->
                    let
                        file =
                            ast
                                |> Elm.Processing.process Elm.Processing.init

                        innerRepr =
                            Intermediate.translate file

                        issues =
                            if model.config.format == Configuration.HUMAN then
                                Checker.getIssuesString innerRepr model.config
                                    |> Encode.string

                            else
                                Checker.getIssuesJSON innerRepr model.config
                    in
                    ( { model | humanReadableResult = toString issues }
                    , toPort issues
                    )

                Err e ->
                    ( { model
                        | humanReadableResult =
                            "error while parsing your code: " ++ toString e
                      }
                    , toPort <|
                        Encode.string <|
                            "error while parsing your code: "
                                ++ toString e
                    )

        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    incoming msgDecode


msgDecode : Decode.Value -> Msg
msgDecode val =
    Decode.decodeValue Decode.string val
        |> Result.map Process
        |> Result.withDefault NoOp


{-| Sends an encoded value to the JS wrapper of the Elm app.
-}
toPort : Encode.Value -> Cmd Msg
toPort val =
    outgoing val


port outgoing : Encode.Value -> Cmd msg


port incoming : (Encode.Value -> msg) -> Sub msg


{-| Launches the application as a view-less Elm app.
-}
main : Program Models.Flags Model Msg
main =
    Platform.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
