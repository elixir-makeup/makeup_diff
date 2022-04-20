# MakeupDiff

A Makeup lexer for diffs and patches.

## Installation

Add `makeup_diff` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:makeup_diff, "~> 0.1.0"}
  ]
end
```

The lexer will automatically register itself with Makeup for `diff` as well as
either `.diff` or `.patch` extensions.
