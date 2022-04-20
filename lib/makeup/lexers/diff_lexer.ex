defmodule Makeup.Lexers.DiffLexer do
  @moduledoc """
  Lexer for diffs to be used with the Makeup package.
  """

  @behaviour Makeup.Lexer

  import NimbleParsec
  import Makeup.Lexer.Combinators
  # import Makeup.Lexer.Groups

  whitespace =
    [?\r, ?\s, ?\n, ?\f]
    |> ascii_string(min: 1)
    |> token(:whitespace)

  line = utf8_string([{:not, ?\n}, {:not, ?\r}], min: 1)

  inserted =
    [string("+"), string(">")]
    |> choice()
    |> concat(line)
    |> token(:generic_inserted)

  deleted =
    [string("-"), string("<")]
    |> choice()
    |> concat(line)
    |> token(:generic_deleted)

  strong =
    "!"
    |> string()
    |> concat(line)
    |> token(:generic_strong)

  text = token(line, :text)

  root_element_combinator = choice([whitespace, inserted, deleted, strong, text])

  @doc false
  def __as_diff_language__({type, meta, value}) do
    {type, Map.put(meta, :language, :diff), value}
  end

  @impl Makeup.Lexer
  defparsec(:root_element, root_element_combinator |> map({__MODULE__, :__as_diff_language__, []}))

  @impl Makeup.Lexer
  defparsec(:root, repeat(parsec(:root_element)))

  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []) do
    tokens
  end

  @impl Makeup.Lexer
  def match_groups(tokens, _opts \\ []) do
    tokens
  end
  # defgroupmatcher(:match_groups,
  #   added_tag: [
  #     open: [[{:punctuation, _, "+"}]],
  #     close: [[{:punctuation, _, "\n"}]]
  #   ],
  #   removed_tag: [
  #     open: [[{:punctuation, _, "-"}]],
  #     close: []
  #   ]
  # )

  @impl Makeup.Lexer
  def lex(text, _opts \\ []) do
    {:ok, tokens, "", _, _, _} = root(text)

    tokens
    |> postprocess()
    |> match_groups()
  end
end
