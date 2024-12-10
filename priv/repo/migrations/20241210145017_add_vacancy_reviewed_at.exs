defmodule Cen.Repo.Migrations.AddVacancyReviewedAt do
  use Ecto.Migration

  def change do
    alter table(:vacancies) do
      add :reviewed_at, :utc_datetime
    end
  end
end
