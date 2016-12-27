defmodule Perudox do
  @moduledoc """
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []
    opts = [strategy: :one_for_one, name: Perudox.Supervisor]
    Supervisor.start_link children, opts
  end
end
