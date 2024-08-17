defmodule Cen.Repo.Migrations.AddOrganizationImage do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :image, :string
    end
  end
end
