defmodule Cen.Repo.Migrations.CreateInteractions do
  use Ecto.Migration

  def change do
    create table(:interactions) do
      add :initiator, :string, null: false

      add :resume_id, references(:resumes, on_delete: :delete_all), null: false
      add :vacancy_id, references(:vacancies, on_delete: :delete_all), null: false

      add :status, :string, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:interactions, [:resume_id])
    create index(:interactions, [:vacancy_id])

    create unique_index(
             :interactions,
             [:resume_id, :vacancy_id, :initiator],
             where: "status = 'pending'"
           )
  end
end
