defmodule Makeup.Lexers.DiffLexerTest do
  use ExUnit.Case, async: true

  alias Makeup.Registry
  alias Makeup.Lexers.DiffLexer
  alias Makeup.Lexer.Postprocess

  describe "registration" do
    test "fetching the lexer by name" do
      assert {:ok, {DiffLexer, []}} == Registry.fetch_lexer_by_name("diff")
    end

    test "fetching the lexer by extension" do
      assert {:ok, {DiffLexer, []}} == Registry.fetch_lexer_by_extension("diff")
    end
  end

  describe "lex/1" do
    test "lexing an empty string" do
      assert [] == lex("")
    end

    test "lexing a string without any diff markers" do
      assert [{:text, %{}, "no changes here"}] = lex("no changes here")
    end

    test "lexting a string with an insertion" do
      assert [{:generic_inserted, %{}, "+ some changes"}] = lex("+ some changes")
      assert [{:generic_inserted, %{}, "> some changes"}] = lex("> some changes")
    end

    test "lexting a string with a deletion" do
      assert [{:generic_deleted, %{}, "- some changes"}] = lex("- some changes")
      assert [{:generic_deleted, %{}, "< some changes"}] = lex("< some changes")
    end

    test "lexting a string with an emphasis marker" do
      assert [{:generic_strong, %{}, "! major changes"}] = lex("! major changes")
    end

    test "multiple lines of changes" do
      text = """
      +inserted text
      -deleted text
      """

      assert [
               {:generic_inserted, %{}, "+inserted text"},
               {:whitespace, %{}, "\n"},
               {:generic_deleted, %{}, "-deleted text"},
               {:whitespace, %{}, "\n"}
             ] = lex(text)
    end
  end

  defp lex(text) do
    text
    |> DiffLexer.lex(group_prefix: "group")
    |> Postprocess.token_values_to_binaries()
    |> Enum.map(fn {type, meta, value} -> {type, Map.delete(meta, :language), value} end)
  end
end
