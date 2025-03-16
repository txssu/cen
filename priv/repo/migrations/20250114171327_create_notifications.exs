defmodule Cen.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :title, :string, null: false
      add :message, :string, null: false
      add :is_broadcast, :boolean, default: false, null: false
      add :type, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])

    create table(:notification_statuses) do
      add :notification_id, references(:notifications, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:notification_statuses, [:notification_id, :user_id])
  end
end
