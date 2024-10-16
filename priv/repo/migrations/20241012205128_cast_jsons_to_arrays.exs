defmodule Cen.Repo.Migrations.CastJsonsToArrays do
  use Ecto.Migration

  def up do
    alter table(:resumes) do
      add :educations_tmp, {:array, :map}, null: false, default: []
      add :jobs_tmp, {:array, :map}, null: false, default: []
    end

    execute("""
    UPDATE resumes
    SET educations_tmp = array(select jsonb_array_elements(educations)::jsonb),
        jobs_tmp = array(select jsonb_array_elements(jobs)::jsonb)
    """)

    alter table(:resumes) do
      remove :educations
      remove :jobs
    end

    rename table(:resumes), :educations_tmp, to: :educations
    rename table(:resumes), :jobs_tmp, to: :jobs
  end

  def down do
    alter table(:resumes) do
      add :educations_tmp, :jsonb, null: false, default: fragment("'{}'")
      add :jobs_tmp, :jsonb
    end

    execute("""
    UPDATE resumes
    SET educations_tmp = coalesce(to_jsonb(educations), '{}'),
        jobs_tmp = coalesce(to_jsonb(jobs), '{}')
    """)

    alter table(:resumes) do
      remove :educations
      remove :jobs
    end

    rename table(:resumes), :educations_tmp, to: :educations
    rename table(:resumes), :jobs_tmp, to: :jobs
  end
end
