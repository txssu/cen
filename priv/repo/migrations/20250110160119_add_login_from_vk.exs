defmodule Cen.Repo.Migrations.AddLoginFromVk do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :vk_id, :bigint

      modify :hashed_password, :string, null: true, from: {:string, null: false}
      modify :role, :string, null: true, from: {:string, null: false}
    end

    create unique_index(:users, :vk_id)
  end
end
