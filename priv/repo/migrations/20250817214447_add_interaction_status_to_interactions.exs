defmodule Cen.Repo.Migrations.AddInteractionStatusToInteractions do
  use Ecto.Migration

  def change do
    alter table(:interactions) do
      add :interaction_status, :string
    end
  end
end
