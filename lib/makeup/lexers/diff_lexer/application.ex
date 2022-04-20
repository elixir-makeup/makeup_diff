defmodule Makeup.Lexers.DiffLexer.Application do
  @moduledoc false

  use Application

  alias Makeup.Registry
  alias Makeup.Lexers.DiffLexer

  def start(_type, _args) do
    Registry.register_lexer(DiffLexer, options: [], names: ["diff"], extensions: ["diff"])

    Supervisor.start_link([], strategy: :one_for_one)
  end
end
