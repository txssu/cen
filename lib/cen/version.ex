defmodule Cen.BuildInfo do
  @moduledoc false

  {hash, _exit_code} = System.cmd("git", ["rev-parse", "--short", "HEAD"], env: %{})

  @git_short_hash String.trim(hash)

  @spec git_short_hash() :: String.t()
  def git_short_hash, do: @git_short_hash
end
