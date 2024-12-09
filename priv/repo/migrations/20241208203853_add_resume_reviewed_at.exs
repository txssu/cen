defmodule Cen.Repo.Migrations.AddResumeReviewedAt do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :reviewed_at, :utc_datetime
    end
  end
end
