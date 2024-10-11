defmodule Cen.Repo.Migrations.CreateResumes do
  use Ecto.Migration

  def change do
    create table(:resumes) do
      add :job_title, :string, null: false
      add :field_of_art, :string, null: false

      add :description, :text, null: false

      add :employment_types, {:array, :string}, default: [], null: false
      add :work_schedules, {:array, :string}, default: [], null: false

      add :educations, :jsonb, null: false
      add :jobs, :jsonb

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:resumes, [:user_id])
  end
end
