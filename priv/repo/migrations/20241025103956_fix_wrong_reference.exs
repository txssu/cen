defmodule Cen.Repo.Migrations.FixWrongReference do
  use Ecto.Migration

  def up do
    alter table(:vacancies) do
      add :user_id_tmp, references(:users, on_delete: :delete_all)
    end

    execute("""
    UPDATE vacancies
    SET user_id_tmp = user_id
    """)

    alter table(:vacancies) do
      remove :user_id
    end

    rename table(:vacancies), :user_id_tmp, to: :user_id

    alter table(:vacancies) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end

    drop constraint("vacancies", "vacancies_user_id_tmp_fkey")
  end

  def down do
    alter table(:vacancies) do
      add :user_id_tmp, references(:organizations)
    end

    execute("""
    UPDATE vacancies
    SET user_id_tmp = user_id
    """)

    alter table(:vacancies) do
      remove :user_id
    end

    rename table(:vacancies), :user_id_tmp, to: :user_id

    alter table(:vacancies) do
      modify :user_id, references(:organizations), null: false
    end

    drop constraint("vacancies", "vacancies_user_id_tmp_fkey")
  end
end
