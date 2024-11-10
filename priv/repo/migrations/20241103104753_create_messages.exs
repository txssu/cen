defmodule Cen.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :text, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :interaction_id, references(:interactions, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:user_id])
    create index(:messages, [:interaction_id])
  end
end
