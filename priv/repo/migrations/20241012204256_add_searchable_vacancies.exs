defmodule Cen.Repo.Migrations.AddSearchableVacancies do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :searchable, :tsvector,
        null: false,
        generated: """
        ALWAYS AS (
          to_tsvector('russian', coalesce(job_title, '') || ' ' || coalesce(description, ''))
        ) STORED
        """
    end

    create index(:resumes, [:searchable], using: "gin")
  end
end
