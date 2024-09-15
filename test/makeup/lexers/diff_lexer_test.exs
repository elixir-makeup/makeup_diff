defmodule Makeup.Lexers.DiffLexerTest do
  use ExUnit.Case, async: true

  use ExUnitProperties

  alias Makeup.Registry
  alias Makeup.Lexers.DiffLexer
  alias Makeup.Lexer.Postprocess

  describe "registration" do
    test "fetching the lexer by name" do
      assert {:ok, {DiffLexer, []}} == Registry.fetch_lexer_by_name("diff")
    end

    test "fetching the lexer by extension" do
      assert {:ok, {DiffLexer, []}} == Registry.fetch_lexer_by_extension("diff")
      assert {:ok, {DiffLexer, []}} == Registry.fetch_lexer_by_extension("patch")
    end
  end

  describe "lex/1" do
    test "lexing an empty string" do
      assert [] == lex("")
    end

    property "lexing a string without any diff markers" do
      check all text <- line() do
        assert [{:text, %{}, ^text}] = lex(text)
      end
    end

    property "lexing a string with an insertion" do
      check all text <- inserted() do
        assert [{:generic_inserted, %{}, ^text} | _] = lex(text)
      end
    end

    property "lexing a string with a deletion" do
      check all text <- deleted() do
        assert [{:generic_deleted, %{}, ^text}] = lex(text)
      end
    end

    property "lexing a string with an emphasis marker" do
      check all text <- strong() do
        assert [{:generic_strong, %{}, ^text}] = lex(text)
      end
    end

    property "lexing full text with all marker types" do
      check all text <- text() do
        for {type, %{}, part} <- lex(text) do
          assert type in [
                   :generic_deleted,
                   :generic_inserted,
                   :generic_strong,
                   :text,
                   :whitespace
                 ]

          assert byte_size(part) > 0
          assert text =~ part
        end
      end
    end

    test "multiple lines of changes" do
      text = """
      diff --git a/setup
      index aaf4004c0f..0287685d2d 100755
      --- a/setup
      +++ b/setup
      @@ -11,16 +11,22 @@ context line
       unchanged
      +inserted
      -deleted
      >inserted
      <deleted
      """

      lexed = lex(text, omit_whitespaces: true)

      assert [
               {:generic_heading, %{}, "diff --git a/setup"},
               {:generic_heading, %{}, "index aaf4004c0f..0287685d2d 100755"},
               {:generic_deleted, %{}, "--- a/setup"},
               {:generic_inserted, %{}, "+++ b/setup"},
               {:text, %{}, "@@ -11,16 +11,22 @@ context line"},
               {:text, %{}, " unchanged"},
               {:generic_inserted, %{}, "+inserted"},
               {:generic_deleted, %{}, "-deleted"},
               {:generic_inserted, %{}, ">inserted"},
               {:generic_deleted, %{}, "<deleted"}
             ] = lexed
    end

    test "marker expected in first position of each line" do
      text = """
       +text
       -text
      +-inserted
      <>deleted
       <text />
      """

      lexed = lex(text, omit_whitespaces: true)

      assert [
               {:text, %{}, " +text"},
               {:text, %{}, " -text"},
               {:generic_inserted, %{}, "+-inserted"},
               {:generic_deleted, %{}, "<>deleted"},
               {:text, %{}, " <text />"}
             ] = lexed
    end
  end

  defp lex(text, opts \\ []) do
    text
    |> DiffLexer.lex(group_prefix: "group")
    |> Postprocess.token_values_to_binaries()
    |> Enum.map(fn {type, meta, value} -> {type, Map.delete(meta, :language), value} end)
    |> then(fn tokens ->
      if Keyword.get(opts, :omit_whitespaces, false) do
        Enum.reject(tokens, fn {type, _, _} -> type == :whitespace end)
      else
        tokens
      end
    end)
  end

  # Properties

  defp line do
    gen all text <- string(:alphanumeric), text != "" do
      text
      |> String.replace_leading(">", "a")
      |> String.replace_leading("+", "b")
      |> String.replace_leading("-", "c")
      |> String.replace_leading("<", "d")
      |> String.replace_leading("!", "e")
    end
  end

  defp inserted do
    gen all text <- string(:alphanumeric),
            text != "",
            marker <- one_of([constant("+"), constant(">")]) do
      marker <> text
    end
  end

  defp deleted do
    gen all text <- string(:alphanumeric),
            text != "",
            marker <- one_of([constant("-"), constant("<")]) do
      marker <> text
    end
  end

  defp strong do
    gen all text <- string(:alphanumeric), text != "" do
      "!" <> text
    end
  end

  defp text do
    gen all lines <- list_of(one_of([line(), inserted(), deleted(), strong()]), min_length: 1),
            lines != [""],
            separator <- string([?\n, ?\r]) do
      lines
      |> Enum.intersperse(separator)
      |> IO.iodata_to_binary()
    end
  end
end
