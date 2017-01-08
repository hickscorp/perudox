# Perudox

An implementation of the game Perudo, also known as Dudo.

## Statuses [![CircleCI Tests](https://circleci.com/gh/AltoLabs/snappic.svg?style=svg&circle-token=744207ef5496f34d6bc9fb1f7904f86fb17414fd)](https://circleci.com/gh/AltoLabs/snappic) [![Coverage Status](https://coveralls.io/repos/github/hickscorp/perudox/badge.svg?branch=master)](https://coveralls.io/github/hickscorp/perudox?branch=master)

If you want to contribute, don't issue a PR until:

- All tests must be passing.
- Coverage percentage must never fall behind.

Also, please make sure your code is linted (Use `credo`) and dialized. To check everything at once locally, you can run:

```
mix do credo, dialyzer, coveralls.html
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `perudo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:perudo, "~> 0.1.0"}]
end
```

2. Ensure `perudo` is started before your application:

```elixir
def application do
  [applications: [:perudo]]
end
```

## Rules

Perudox aims at following the rules as [described by wikipedia](https://en.wikipedia.org/wiki/Dudo).
