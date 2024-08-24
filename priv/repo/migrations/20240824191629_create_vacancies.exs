defmodule Cen.Repo.Migrations.CreateVacancies do
  use Ecto.Migration

  def change do
    create table(:vacancies) do
      add :job_title, :string, null: false
      add :field_of_art, :string, null: false

      add :description, :text, null: false

      add :employment_types, {:array, :string}, default: [], null: false
      add :work_schedules, {:array, :string}, default: [], null: false

      add :education, :string, null: false

      add :min_years_of_work_experience, :integer, default: 0, null: false
      add :proposed_salary, :integer

      add :user_id, references(:organizations), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:vacancies, [:user_id])
    create index(:vacancies, [:organization_id])
  end
end
