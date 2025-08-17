defmodule Cen.Repo.Migrations.RenameDeletedAtToArchivedAt do
  use Ecto.Migration

  def change do
    rename table(:resumes), :deleted_at, to: :archived_at
    rename table(:vacancies), :deleted_at, to: :archived_at
  end
end
