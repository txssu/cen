defmodule Cen.Repo.Migrations.AddSearchableVacancies do
  use Ecto.Migration

  def change do
    alter table(:vacancies) do
      add :searchable, :tsvector,
        null: false,
        generated: """
        ALWAYS AS (
          to_tsvector('russian', coalesce(job_title, '') || ' ' || coalesce(description, ''))
        ) STORED
        """
    end

    create index(:vacancies, [:searchable], using: "gin")
  end
end
