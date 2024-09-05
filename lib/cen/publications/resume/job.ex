defmodule Cen.Publications.Resume.Job do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  embedded_schema do
    field :organization_name, :string
    field :job_title, :string
    field :description, :string
    field :start_date, :date
    field :end_date, :date
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:organization_name, :job_title, :description, :start_date, :end_date])
    |> validate_organization_name()
    |> validate_job_title()
    |> validate_description()
    |> validate_start_date()
    |> validate_end_date()
  end

  defp validate_organization_name(changeset) do
    validate_length(changeset, :organization_name, max: 255)
  end

  defp validate_job_title(changeset) do
    changeset
    |> validate_required(:job_title)
    |> validate_length(:job_title, max: 100)
  end

  defp validate_description(changeset) do
    validate_length(changeset, :description, max: 255)
  end

  defp validate_start_date(changeset) do
    changeset
    |> validate_required(:start_date)
    |> validate_length(:start_date, max: 255)
  end

  defp validate_end_date(changeset) do
    changeset
    |> validate_required(:end_date)
    |> validate_length(:end_date, max: 255)
  end
end
