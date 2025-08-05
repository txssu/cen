defmodule Cen.Repo.Migrations.UpdateUsersEmailUniqueConstraint do
  use Ecto.Migration

  def up do
    # Remove the old unique constraint
    drop_if_exists unique_index(:users, [:email])

    # Create a partial unique index that only applies to non-deleted users
    create unique_index(:users, [:email],
             where: "deleted_at IS NULL",
             name: :users_email_unique_when_not_deleted
           )
  end

  def down do
    # Remove the partial unique index
    drop_if_exists unique_index(:users, [:email],
                     where: "deleted_at IS NULL",
                     name: :users_email_unique_when_not_deleted
                   )

    # Restore the old unique constraint
    create unique_index(:users, [:email])
  end
end
