{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Main (main) where

import Data.Foldable (traverse_)
import Data.HashMap.Strict (HashMap)
import Data.JsonSpec (Specification(JsonArray, JsonDateTime, JsonEither,
  JsonInt, JsonLet, JsonNullable, JsonNum, JsonObject, JsonRef, JsonString, JsonTag))
import Data.JsonSpec.Elm (Named, elmDefs)
import Data.Maybe (fromMaybe)
import Data.Proxy (Proxy(Proxy))
import Data.Text (Text)
import Language.Elm.Name (Module)
import Language.Elm.Pretty (modules)
import Prelude (Bool(True), Functor(fmap), Semigroup((<>)), ($), (.),
  FilePath, IO, init)
import Prettyprinter (defaultLayoutOptions, layoutPretty)
import Prettyprinter.Render.Text (renderStrict)
import System.Directory (createDirectoryIfMissing)
import System.IO (stderr)
import System.Process (callCommand)
import Test.Hspec (describe, hspec, it, shouldBe)
import qualified Data.HashMap.Strict as HM
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.IO as TIO

main :: IO ()
main =
  hspec $ do
    describe "Code generation" $ do
      it "works with a complicated schema" $
        let
          actual :: HashMap Module Text
          actual =
            fmap ((<> "\n") . renderStrict . layoutPretty defaultLayoutOptions)
            . modules
            . Set.toList
            $ elmDefs (Proxy @TestSpec)

          expected :: HashMap Module Text
          expected =
            HM.singleton
              ["Api", "Data"]
              ( Text.unlines
                  [ "module Api.Data exposing"
                  , "    ( dashboardDecoder"
                  , "    , dashboardEncoder"
                  , "    , inviteDecoder"
                  , "    , inviteEncoder"
                  , "    , Invite(..)"
                  , "    , Dashboard"
                  , "    )"
                  , ""
                  , "import Iso8601"
                  , "import Json.Decode"
                  , "import Json.Encode"
                  , "import Time"
                  , ""
                  , ""
                  , "dashboardDecoder : Json.Decode.Decoder Dashboard"
                  , "dashboardDecoder ="
                  , "    Json.Decode.succeed (\\a b c -> { proposals = a, credits = b, user = c }) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"proposals\" (Json.Decode.list (Json.Decode.succeed (\\b c -> { key = b"
                  , "    , value = c }) |>"
                  , "    Json.Decode.andThen (\\b -> Json.Decode.map b (Json.Decode.field \"key\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\b -> Json.Decode.map b (Json.Decode.field \"value\" (Json.Decode.succeed (\\c d e f g h i j -> { name = c"
                  , "    , owner = d"
                  , "    , availability = e"
                  , "    , description = f"
                  , "    , venue = g"
                  , "    , invites = h"
                  , "    , created_at = i"
                  , "    , attachments = j }) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"name\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"owner\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"availability\" (Json.Decode.list (Json.Decode.succeed (\\d e -> { interval = d"
                  , "    , users = e }) |>"
                  , "    Json.Decode.andThen (\\d -> Json.Decode.map d (Json.Decode.field \"interval\" (Json.Decode.succeed (\\e f -> { startInclusive = e"
                  , "    , endExclusive = f }) |>"
                  , "    Json.Decode.andThen (\\e -> Json.Decode.map e (Json.Decode.field \"startInclusive\" Iso8601.decoder)) |>"
                  , "    Json.Decode.andThen (\\e -> Json.Decode.map e (Json.Decode.field \"endExclusive\" Iso8601.decoder))))) |>"
                  , "    Json.Decode.andThen (\\d -> Json.Decode.map d (Json.Decode.field \"users\" (Json.Decode.list Json.Decode.string))))))) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"description\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"venue\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"invites\" (Json.Decode.list inviteDecoder))) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"created-at\" Iso8601.decoder)) |>"
                  , "    Json.Decode.andThen (\\c -> Json.Decode.map c (Json.Decode.field \"attachments\" (Json.Decode.list Json.Decode.string)))))))))) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"credits\" Json.Decode.int)) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"user\" Json.Decode.string))"
                  , ""
                  , ""
                  , "dashboardEncoder : Dashboard -> Json.Encode.Value"
                  , "dashboardEncoder a ="
                  , "    Json.Encode.object [ (\"proposals\" , Json.Encode.list (\\b -> Json.Encode.object [ (\"key\" , Json.Encode.string b.key)"
                  , "    , (\"value\" , (\\c -> Json.Encode.object [ (\"name\" , Json.Encode.string c.name)"
                  , "    , (\"owner\" , Json.Encode.string c.owner)"
                  , "    , (\"availability\" , Json.Encode.list (\\d -> Json.Encode.object [ (\"interval\" , (\\e -> Json.Encode.object [ (\"startInclusive\" , Iso8601.encode e.startInclusive)"
                  , "    , (\"endExclusive\" , Iso8601.encode e.endExclusive) ]) d.interval)"
                  , "    , (\"users\" , Json.Encode.list Json.Encode.string d.users) ]) c.availability)"
                  , "    , (\"description\" , Json.Encode.string c.description)"
                  , "    , (\"venue\" , Json.Encode.string c.venue)"
                  , "    , (\"invites\" , Json.Encode.list inviteEncoder c.invites)"
                  , "    , (\"created-at\" , Iso8601.encode c.created_at)"
                  , "    , (\"attachments\" , Json.Encode.list Json.Encode.string c.attachments) ]) b.value) ]) a.proposals)"
                  , "    , (\"credits\" , Json.Encode.int a.credits)"
                  , "    , (\"user\" , Json.Encode.string a.user) ]"
                  , ""
                  , ""
                  , "inviteDecoder : Json.Decode.Decoder Invite"
                  , "inviteDecoder ="
                  , "    Json.Decode.oneOf [ Json.Decode.map InviteUser (Json.Decode.succeed (\\a b -> { type_ = a"
                  , "    , username = b }) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"type\" (Json.Decode.string |>"
                  , "    Json.Decode.andThen (\\b -> if b == \"discord-user\" then"
                  , "        Json.Decode.succeed ()"
                  , ""
                  , "    else"
                  , "        Json.Decode.fail \"Tag mismatch\")))) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"username\" Json.Decode.string)))"
                  , "    , Json.Decode.map InviteGuild (Json.Decode.succeed (\\a b -> { type_ = a"
                  , "    , guild = b }) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"type\" (Json.Decode.string |>"
                  , "    Json.Decode.andThen (\\b -> if b == \"discord-server\" then"
                  , "        Json.Decode.succeed ()"
                  , ""
                  , "    else"
                  , "        Json.Decode.fail \"Tag mismatch\")))) |>"
                  , "    Json.Decode.andThen (\\a -> Json.Decode.map a (Json.Decode.field \"guild\" (Json.Decode.succeed (\\b c -> { id = b"
                  , "    , name = c }) |>"
                  , "    Json.Decode.andThen (\\b -> Json.Decode.map b (Json.Decode.field \"id\" Json.Decode.string)) |>"
                  , "    Json.Decode.andThen (\\b -> Json.Decode.map b (Json.Decode.field \"name\" Json.Decode.string)))))) ]"
                  , ""
                  , ""
                  , "inviteEncoder : Invite -> Json.Encode.Value"
                  , "inviteEncoder a ="
                  , "    case a of"
                  , "        InviteUser b ->"
                  , "            (\\c -> Json.Encode.object [ (\"type\" , always (Json.Encode.string \"discord-user\") c.type_)"
                  , "            , (\"username\" , Json.Encode.string c.username) ]) b"
                  , ""
                  , "        InviteGuild b ->"
                  , "            (\\c -> Json.Encode.object [ (\"type\" , always (Json.Encode.string \"discord-server\") c.type_)"
                  , "            , (\"guild\" , (\\d -> Json.Encode.object [ (\"id\" , Json.Encode.string d.id)"
                  , "            , (\"name\" , Json.Encode.string d.name) ]) c.guild) ]) b"
                  , ""
                  , ""
                  , "type Invite "
                  , "    = InviteUser { type_ : (), username : String }"
                  , "    | InviteGuild { type_ : (), guild : { id : String, name : String } }"
                  , ""
                  , ""
                  , "type alias Dashboard  ="
                  , "    { proposals : List { key : String"
                  , "    , value : { name : String"
                  , "    , owner : String"
                  , "    , availability : List { interval : { startInclusive : Time.Posix"
                  , "    , endExclusive : Time.Posix }"
                  , "    , users : List String }"
                  , "    , description : String"
                  , "    , venue : String"
                  , "    , invites : List Invite"
                  , "    , created_at : Time.Posix"
                  , "    , attachments : List String } }"
                  , "    , credits : Int"
                  , "    , user : String }"
                  ]
              )
        in do
          TIO.hPutStrLn stderr "==========================================\n\n"
          TIO.hPutStrLn stderr (fromMaybe "" (HM.lookup ["Api", "Data"] actual))
          TIO.hPutStrLn stderr "\n\n==========================================\n\n"
          actual `shouldBe` expected
      it "works with the example schema" $
        let
          actual :: HashMap Module Text
          actual =
            fmap ((<> "\n") . renderStrict . layoutPretty defaultLayoutOptions)
            . modules
            . Set.toList
            $ elmDefs (Proxy @ExampleSpec)

        in do
          traverse_ writeModule (HM.toList actual)
          callCommand "(cd elm-test; elm-format src/ --yes)"
          callCommand
            "(\
              \cd elm-test; \
              \yes Y | (\
                \elm init; \
                \elm install rtfeldman/elm-iso8601-date-strings; \
                \elm install elm/json; \
                \elm install elm/url; \
                \elm install elm/time; \
                \elm install elm/http\
              \); \
              \elm make src/Api/Data.elm\
            \)"
          callCommand "rm -rf elm-test"

      it "works with nullable values" $
        let
          actual :: HashMap Module Text
          actual =
            fmap ((<> "\n") . renderStrict . layoutPretty defaultLayoutOptions)
            . modules
            . Set.toList
            $ elmDefs (Proxy @NullableSpec)

          expected :: HashMap Module Text
          expected = 
            HM.singleton
              ["Api", "Data"]
              ( Text.unlines
                  [ "module Api.Data exposing"
                  , "    ( nullableIntDecoder"
                  , "    , nullableIntEncoder"
                  , "    , NullableInt"
                  , "    )"
                  , ""
                  , "import Json.Decode"
                  , "import Json.Encode"
                  , ""
                  , ""
                  , "nullableIntDecoder : Json.Decode.Decoder NullableInt"
                  , "nullableIntDecoder ="
                  , "    Json.Decode.nullable Json.Decode.int"
                  , ""
                  , ""
                  , "nullableIntEncoder : NullableInt -> Json.Encode.Value"
                  , "nullableIntEncoder a ="
                  , "    Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.int a)"
                  , ""
                  , ""
                  , "type alias NullableInt  ="
                  , "    Maybe Int"
                  ]
              )
        in do
          TIO.hPutStrLn stderr "==========================================\n\n"
          TIO.hPutStrLn stderr (fromMaybe "" (HM.lookup ["Api", "Data"] actual))
          TIO.hPutStrLn stderr "\n\n==========================================\n\n"
          actual `shouldBe` expected


{-
  This spec is copied from an as-yet uncompleted personal project. I
  just used it because it is fairly complex. Probably something known
  to be exhaustive is in order.
-}
type TestSpec =
  JsonLet
    '[
      '("Dashboard", JsonObject '[
        '("proposals", JsonArray (
          JsonObject '[
            '("key", JsonString),
            '("value", JsonObject '[
              '("name", JsonString),
              '("owner", JsonString),
              '("availability", JsonArray (
                JsonObject '[
                  '("interval", JsonObject '[
                    '("startInclusive", JsonDateTime),
                    '("endExclusive", JsonDateTime)
                  ]),
                  '("users", JsonArray JsonString)
                ]
              )),
              '("description", JsonString),
              '("venue", JsonString),
              '("invites", (
                JsonLet '[
                  '("Invite",
                    JsonEither
                      (Named "InviteUser" (JsonObject '[
                        '("type", JsonTag "discord-user"),
                        '("username", JsonString)
                      ]))
                      (Named "InviteGuild" (JsonObject '[
                        '("type", JsonTag "discord-server"),
                        '("guild", JsonObject '[
                          '("id", JsonString),
                          '("name", JsonString)
                         ])
                      ]))
                  )
                ]
                (JsonArray (JsonRef "Invite")))),
              '("created-at", JsonDateTime),
              '("attachments", JsonArray JsonString)
            ])
          ]
        )),
        '("credits", JsonInt),
        '("user", JsonString)
       ])
    ] ( JsonRef "Dashboard")


type ExampleSpec =
  Named "ExampleType"
    ( JsonObject
        '[ '("stringField", JsonString)
         , '( "anonymousObject"
            , JsonObject
                '[ '("floatField", JsonNum)
                 , '("dateField", JsonDateTime)
                 , '( "sumType1"
                    , Named "SumTypeWithCustomConstructorNames"
                        ( JsonEither
                            ( JsonEither
                                (Named "IntConstructor" JsonInt)
                                (Named "StringConstructor" JsonString)
                            )
                            (Named "FloatConstructor" JsonNum)
                        )
                    )
                 , '( "sumType2"
                    , Named "SumTypeWithAutomaticConstructorNames"
                        ( JsonEither
                            ( JsonEither
                                JsonInt
                                JsonString
                            )
                            JsonNum
                        )
                    )
                 ]
            )
         , '( "namedObject"
            , Named "NamedElmRecord"
                ( JsonObject
                    '[ '("stringField", JsonString)
                     , '( "listOfStrings"
                        , JsonArray JsonString
                        )
                     ]
                )
            )
         , '( "newtypedObject"
            , Named "NewtypedElmRecord"
                ( Named "Cons"
                    ( JsonObject
                        '[ '("stringField", JsonString)
                         , '( "listOfStrings"
                            , JsonArray JsonString
                            )
                         ]
                    )
                )
            )
         ]
    )

type NullableSpec =
  Named "NullableInt"
    (JsonNullable JsonInt)

writeModule :: (Module, Text) -> IO ()
writeModule (module_, content) = do
    createDirectoryIfMissing True dirname
    TIO.writeFile filename content
  where
    pathName :: [Text] -> FilePath
    pathName = ("elm-test/src/" <>) . Text.unpack . Text.intercalate "/"

    filename :: FilePath
    filename = pathName module_ <> ".elm"

    dirname :: FilePath
    dirname = pathName (init module_)


