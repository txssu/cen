defmodule Cen.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :inn, :string, null: false
      add :description, :text, null: false
      add :phone_number, :string, null: false
      add :email, :string
      add :website_link, :string
      add :social_link, :string
      add :address, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:organizations, [:user_id])
  end
end
