defmodule Makeup.Lexers.DiffLexer.Helper do
  @moduledoc false

  import NimbleParsec
  import Makeup.Lexer.Combinators

  def line_starting_with(start, token_type) when is_binary(start) do
    string(start)
    |> rest_of_line()
    |> token(token_type)
  end

  def line_starting_with([_, _ | _] = start, token_type) do
    List.wrap(start)
    |> Enum.map(&string/1)
    |> choice()
    |> rest_of_line()
    |> token(token_type)
  end

  def text_line() do
    rest_of_line() |> token(:text)
  end

  defp rest_of_line(combinator \\ empty()) do
    repeat(combinator, utf8_char([{:not, ?\n}, {:not, ?\r}]))
  end

  def newline() do
    times(utf8_char([?\n, ?\r]), min: 1)
    |> token(:whitespace)
  end
end
