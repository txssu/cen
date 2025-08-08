defmodule Cen.Repo.Migrations.UpdateUsersVkIdUniqueConstraint do
  use Ecto.Migration

  def up do
    # Remove the old unique constraint on vk_id
    drop_if_exists unique_index(:users, [:vk_id])

    # Create a partial unique index that only applies to non-deleted users with non-null vk_id
    create unique_index(:users, [:vk_id],
             where: "deleted_at IS NULL AND vk_id IS NOT NULL",
             name: :users_vk_id_unique_when_not_deleted
           )
  end

  def down do
    # Remove the partial unique index
    drop_if_exists unique_index(:users, [:vk_id],
                     where: "deleted_at IS NULL AND vk_id IS NOT NULL",
                     name: :users_vk_id_unique_when_not_deleted
                   )

    # Restore the old unique constraint
    create unique_index(:users, [:vk_id])
  end
end
