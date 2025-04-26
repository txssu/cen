defmodule Cen.Repo.Migrations.UpdateNotification do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      remove :title, :string, null: false
      modify :message, :text, from: :string
    end
  end
end
