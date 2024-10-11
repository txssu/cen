defmodule Cen.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :cen

  @spec migrate() :: term()
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _a1, _a2} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @spec rollback(Ecto.Repo.t(), term()) :: term()
  def rollback(repo, version) do
    load_app()
    {:ok, _a1, _a2} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
