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
      add :work_experience, :jsonb, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
