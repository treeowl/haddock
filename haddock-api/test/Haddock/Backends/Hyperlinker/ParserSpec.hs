module Haddock.Backends.Hyperlinker.ParserSpec (main, spec) where


import Test.Hspec

import Haddock.Backends.Hyperlinker.Parser


main :: IO ()
main = hspec spec


spec :: Spec
spec = do
    describe "parse" parseSpec


parseSpec :: Spec
parseSpec = do

    context "when parsing single-line comments" $ do

        it "should ignore content until the end of line" $
            "-- some very simple comment\nidentifier"
            `shouldParseTo`
            [TkComment, TkSpace, TkIdentifier]

        it "should allow endline escaping" $
            "-- first line\\\nsecond line\\\nand another one"
            `shouldParseTo`
            [TkComment]

    context "when parsing multi-line comments" $ do

        it "should support nested comments" $
            "{- comment {- nested -} still comment -} {- next comment -}"
            `shouldParseTo`
            [TkComment, TkSpace, TkComment]

        it "should distinguish compiler pragma" $
            "{- comment -}{-# LANGUAGE GADTs #-}{- comment -}"
            `shouldParseTo`
            [TkComment, TkPragma, TkComment]

    it "should recognize preprocessor directives" $ do
        "\n#define foo bar" `shouldParseTo` [TkSpace, TkCpp]
        "x # y" `shouldParseTo`
            [TkIdentifier, TkSpace, TkCpp, TkSpace,TkIdentifier]

    it "should distinguish basic language constructs" $ do
        "(* 2) <$> (\"abc\", foo)" `shouldParseTo`
            [ TkSpecial, TkOperator, TkSpace, TkNumber, TkSpecial
            , TkSpace, TkOperator, TkSpace
            , TkSpecial, TkString, TkSpecial, TkSpace, TkIdentifier, TkSpecial
            ]
        "let foo' = foo in foo' + foo'" `shouldParseTo`
            [ TkKeyword, TkSpace, TkIdentifier
            , TkSpace, TkGlyph, TkSpace
            , TkIdentifier, TkSpace, TkKeyword, TkSpace
            , TkIdentifier, TkSpace, TkOperator, TkSpace, TkIdentifier
            ]
        "square x = y^2 where y = x" `shouldParseTo`
            [ TkIdentifier, TkSpace, TkIdentifier
            , TkSpace, TkGlyph, TkSpace
            , TkIdentifier, TkOperator, TkNumber
            , TkSpace, TkKeyword, TkSpace
            , TkIdentifier, TkSpace, TkGlyph, TkSpace, TkIdentifier
            ]


shouldParseTo :: String -> [TokenType] -> Expectation
str `shouldParseTo` tokens = map tkType (parse str) `shouldBe` tokens
