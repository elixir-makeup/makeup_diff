defmodule Makeup.Lexers.DiffLexer do
  @moduledoc """
  Lexer for diffs to be used with the Makeup package.
  """

  @behaviour Makeup.Lexer

  import NimbleParsec
  import Makeup.Lexers.DiffLexer.Helper

  heading = line_starting_with(["diff", "index"], :generic_heading)
  inserted = line_starting_with(["+", ">"], :generic_inserted)
  deleted = line_starting_with(["-", "<"], :generic_deleted)
  strong = line_starting_with("!", :generic_strong)

  root_element_combinator =
    choice([heading, inserted, deleted, strong, text_line()])
    |> map(:add_meta_diff_language)

  defp add_meta_diff_language({type, meta, value}) do
    {type, Map.put(meta, :language, :diff), value}
  end

  @impl Makeup.Lexer
  defparsec(:root_element, root_element_combinator)

  @impl Makeup.Lexer
  defparsec(
    :root,
    repeat(parsec(:root_element) |> concat(newline()))
    |> choice([ignore(eos()), parsec(:root_element)])
  )

  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []), do: tokens

  @impl Makeup.Lexer
  def match_groups(tokens, _opts \\ []), do: tokens

  @impl Makeup.Lexer
  def lex(text, _opts \\ []) do
    {:ok, tokens, "", _, _, _} = root(text)

    tokens
    |> postprocess()
    |> match_groups()
  end
end
