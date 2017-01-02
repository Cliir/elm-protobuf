module Protobuf exposing (..)

{-| Runtime library for Google Protocol Buffers.

This is mostly useless on its own, it is meant to support the code generated by the [Elm Protocol
Buffer compiler](https://github.com/tiziano88/elm-protobuf).

# Decoder Helpers

@docs decode, required, optional, repeated, field

@docs withDefault

# Encoder Helpers

@docs requiredFieldEncoder, optionalEncoder, repeatedFieldEncoder

# Bytes

@docs Bytes, bytesFieldDecoder, bytesFieldEncoder

# Well Known Types

@docs Timestamp, timestampDecoder, timestampEncoder

-}

import Json.Decode as JD
import Json.Encode as JE
import ISO8601


{-| Decodes a message.
-}
decode : a -> JD.Decoder a
decode =
    JD.succeed


{-| Decodes a required field.
-}
required : String -> JD.Decoder a -> a -> JD.Decoder (a -> b) -> JD.Decoder b
required name decoder default d =
    field (withDefault default <| JD.field name decoder) d


{-| Decodes an optional field.
-}
optional : String -> JD.Decoder a -> JD.Decoder (Maybe a -> b) -> JD.Decoder b
optional name decoder d =
    field (JD.maybe <| JD.field name decoder) d


{-| Decodes a repeated field.
-}
repeated : String -> JD.Decoder a -> JD.Decoder (List a -> b) -> JD.Decoder b
repeated name decoder d =
    field (withDefault [] <| JD.list <| JD.field name decoder) d


{-| Decodes a field.
-}
field : JD.Decoder a -> JD.Decoder (a -> b) -> JD.Decoder b
field =
    JD.map2 (|>)


{-| Provides a default value for a field.
-}
withDefault : a -> JD.Decoder a -> JD.Decoder a
withDefault default decoder =
    JD.oneOf
        [ decoder
        , JD.succeed default
        ]


{-| Encodes an optional field.
-}
optionalEncoder : String -> (a -> JE.Value) -> Maybe a -> Maybe ( String, JE.Value )
optionalEncoder name encoder v =
    case v of
        Just x ->
            Just ( name, encoder x )

        Nothing ->
            Nothing


{-| Encodes a required field.
-}
requiredFieldEncoder : String -> (a -> JE.Value) -> a -> a -> Maybe ( String, JE.Value )
requiredFieldEncoder name encoder default v =
    if v == default then
        Nothing
    else
        Just ( name, encoder v )


{-| Encodes a repeated field.
-}
repeatedFieldEncoder : String -> (a -> JE.Value) -> List a -> Maybe ( String, JE.Value )
repeatedFieldEncoder name encoder v =
    case v of
        [] ->
            Nothing

        _ ->
            Just ( name, JE.list <| List.map encoder v )


{-| Bytes field.
-}
type alias Bytes =
    List Int


{-| Decodes a bytes field.
TODO: Implement.
-}
bytesFieldDecoder : JD.Decoder Bytes
bytesFieldDecoder =
    JD.succeed []


{-| Encodes a bytes field.
TODO: Implement.
-}
bytesFieldEncoder : Bytes -> JE.Value
bytesFieldEncoder v =
    JE.list []



-- Well Known Types.


{-| Timestamp.
-}
type alias Timestamp =
    ISO8601.Time


{-| Decodes a Timestamp.
-}
timestampDecoder : JD.Decoder Timestamp
timestampDecoder =
    JD.map ISO8601.fromString JD.string
        |> JD.andThen
            (\v ->
                case v of
                    Ok v ->
                        JD.succeed v

                    Err e ->
                        JD.fail e
            )


{-| Encodes a Timestamp.
-}
timestampEncoder : Timestamp -> JE.Value
timestampEncoder v =
    JE.string <| ISO8601.toString v


intValueDecoder : JD.Decoder Int
intValueDecoder =
    JD.int


intValueEncoder : Int -> JE.Value
intValueEncoder =
    JE.int
