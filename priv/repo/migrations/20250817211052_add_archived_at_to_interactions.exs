defmodule Cen.Repo.Migrations.AddArchivedAtToInteractions do
  use Ecto.Migration

  def change do
    alter table(:interactions) do
      add :archived_at, :utc_datetime
    end
  end
end
