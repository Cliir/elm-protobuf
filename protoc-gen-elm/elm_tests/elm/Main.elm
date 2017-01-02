port module Main exposing (..)

import Json.Decode as JD
import Json.Encode as JE
import Result
import String
import Task
import Test exposing (..)
import Test.Runner.Node exposing (run, TestProgram)
import Expect exposing (..)
import Simple as T
import Recursive as R
import Protobuf exposing (..)
import ISO8601


main : TestProgram
main =
    run emit suite


port emit : ( String, JE.Value ) -> Cmd msg


suite : Test
suite =
    describe "JSON"
        [ test "JSON encode" <| \_ -> equal msgJson (JE.encode 2 (T.simpleEncoder msg))
        , test "JSON decode" <| \_ -> assertDecode T.simpleDecoder msgJson msg
        , test "JSON decode extra field" <| \_ -> assertDecode T.simpleDecoder msgExtraFieldJson msg
        , test "JSON encode empty message" <| \_ -> equal emptyJson (JE.encode 2 (T.fooEncoder fooDefault))
        , test "JSON decode empty JSON" <| \_ -> assertDecode T.simpleDecoder emptyJson msgDefault
        , test "JSON encode message with repeated field" <| \_ -> equal (JE.encode 2 (T.fooEncoder foo)) fooJson
        , describe "oneof"
            [ test "encode" <| \_ -> equal fooJson (JE.encode 2 (T.fooEncoder foo))
            , test "decode empty JSON" <| \_ -> assertDecode T.fooDecoder emptyJson fooDefault
            , test "decode oo1" <| \_ -> assertDecode T.fooDecoder oo1SetJson oo1Set
            , test "decode oo2" <| \_ -> assertDecode T.fooDecoder oo2SetJson oo2Set
            ]
        , describe "recursion"
            [ test "decode empty JSON" <| \_ -> assertDecode R.recDecoder emptyJson recDefault
            , test "decode 1-level JSON" <| \_ -> assertDecode R.recDecoder recJson1 rec1
            , test "decode 2-level JSON" <| \_ -> assertDecode R.recDecoder recJson2 rec2
            ]
        , describe "timestamp"
            [ test "encode" <| \_ -> equal timestampJson (JE.encode 2 (T.fooEncoder timestampFoo))
            , test "decode" <| \_ -> assertDecode T.fooDecoder timestampJson timestampFoo
            ]
        , describe "wrappers"
            -- TODO: Preserve nulls.
            [ test "encodeEmpty" <| \_ -> equal wrappersJsonEmpty (JE.encode 2 (T.wrappersEncoder wrappersEmpty))
            , test "decode" <| \_ -> assertDecode T.wrappersDecoder wrappersJsonEmpty wrappersEmpty
            ]
        ]


assertDecode : JD.Decoder a -> String -> a -> Expectation
assertDecode decoder json msg =
    equal
        (JD.decodeString decoder json)
        (Result.Ok msg)


msg : T.Simple
msg =
    { int32Field = 123
    }


msgDefault : T.Simple
msgDefault =
    { int32Field = 0
    }


fooDefault : T.Foo
fooDefault =
    { s = Nothing
    , ss = []
    , colour = T.ColourUnspecified
    , colours = []
    , singleIntField = 0
    , repeatedIntField = []
    , oo = T.OoUnspecified
    , bytesField = []
    , stringValueField = Nothing
    , otherField = Nothing
    , otherDirField = Nothing
    , timestampField = Nothing
    }


recDefault : R.Rec
recDefault =
    { int32Field = 0
    , r = R.RUnspecified
    , stringField = ""
    }


msgJson : String
msgJson =
    String.trim """
{
  "int32Field": 123
}
"""


msgExtraFieldJson : String
msgExtraFieldJson =
    String.trim """
{
  "int32Field": 123,
  "extraField": "abc"
}
"""


emptyJson =
    String.trim """
{}
"""


foo : T.Foo
foo =
    { s =
        Just
            { int32Field = 11
            }
    , ss =
        [ { int32Field = 111
          }
        , { int32Field = 222
          }
        ]
    , colour = T.Red
    , colours =
        [ T.Red
        , T.Red
        ]
    , singleIntField = 123
    , repeatedIntField =
        [ 111
        , 222
        , 333
        ]
    , oo = T.Oo1 1
    , bytesField = []
    , stringValueField = Nothing
    , otherField =
        Just
            { stringField = "xxx"
            }
    , otherDirField =
        Just
            { stringField = "yyy"
            }
    , timestampField = Nothing
    }


fooJson : String
fooJson =
    String.trim """
{
  "s": {
    "int32Field": 11
  },
  "ss": [
    {
      "int32Field": 111
    },
    {
      "int32Field": 222
    }
  ],
  "colour": "RED",
  "colours": [
    "RED",
    "RED"
  ],
  "singleIntField": 123,
  "repeatedIntField": [
    111,
    222,
    333
  ],
  "otherField": {
    "stringField": "xxx"
  },
  "otherDirField": {
    "stringField": "yyy"
  },
  "oo1": 1
}
"""


oo1Set : T.Foo
oo1Set =
    { fooDefault
        | oo = T.Oo1 123
    }


oo1SetJson : String
oo1SetJson =
    String.trim """
{
  "oo1": 123
}
"""


oo2Set : T.Foo
oo2Set =
    { fooDefault
        | oo = T.Oo2 True
    }


oo2SetJson : String
oo2SetJson =
    String.trim """
{
  "oo2": true
}
"""


recJson1 : String
recJson1 =
    String.trim """
{
  "recField": {}
}
"""


rec1 : R.Rec
rec1 =
    { int32Field = 0
    , r =
        R.RecField
            { int32Field = 0
            , r = R.RUnspecified
            , stringField = ""
            }
    , stringField = ""
    }


recJson2 : String
recJson2 =
    String.trim """
{
  "recField": {
    "recField": {}
  }
}
"""


rec2 : R.Rec
rec2 =
    { int32Field = 0
    , r =
        R.RecField
            { int32Field = 0
            , r =
                R.RecField
                    { int32Field = 0
                    , r = R.RUnspecified
                    , stringField = ""
                    }
            , stringField = ""
            }
    , stringField = ""
    }


timestampJson : String
timestampJson =
    String.trim """
{
  "timestampField": "1988-12-14T01:23:45.678Z"
}
"""


timestampFoo : T.Foo
timestampFoo =
    { fooDefault
        | timestampField =
            Just <| ISO8601.fromTime 598065825678
    }


wrappersJsonEmpty : String
wrappersJsonEmpty =
    String.trim """
{}
"""


wrappersJsonNull : String
wrappersJsonNull =
    String.trim """
{
  "int32ValueField": null,
  "int64ValueField": null,
  "uInt32ValueField": null,
  "uInt64ValueField": null,
  "doubleValueField": null,
  "floatValueField": null,
  "boolValueField": null,
  "stringValueField": null,
  "bytesValueField": null
}
"""


wrappersJsonSet : String
wrappersJsonSet =
    String.trim """
{
  "int32ValueField": "111",
  "int64ValueField": "222",
  "uInt32ValueField": "333",
  "uInt64ValueField": "444"
}
"""


wrappersEmpty : T.Wrappers
wrappersEmpty =
    { int32ValueField = Nothing
    , int64ValueField = Nothing
    , uInt32ValueField = Nothing
    , uInt64ValueField = Nothing
    , doubleValueField = Nothing
    , floatValueField = Nothing
    , boolValueField = Nothing
    , stringValueField = Nothing
    , bytesValueField = Nothing
    }


wrappersSet : T.Wrappers
wrappersSet =
    { int32ValueField = Just 111
    , int64ValueField = Just 222
    , uInt32ValueField = Just 333
    , uInt64ValueField = Just 444
    , doubleValueField = Nothing
    , floatValueField = Nothing
    , boolValueField = Nothing
    , stringValueField = Nothing
    , bytesValueField = Nothing
    }
