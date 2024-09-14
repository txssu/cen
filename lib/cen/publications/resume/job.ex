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

    field :start_month, :string, virtual: true
    field :end_month, :string, virtual: true
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:organization_name, :job_title, :description, :start_month, :end_month])
    |> validate_organization_name()
    |> validate_job_title()
    |> validate_description()
    |> validate_start_month()
    |> validate_end_month()
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

  defp validate_start_month(changeset) do
    changeset = validate_required(changeset, :start_month)

    case get_change(changeset, :start_month) do
      nil ->
        changeset

      year_with_month ->
        [year, month] = year_with_month |> String.split("-") |> Enum.map(&String.to_integer/1)
        put_change(changeset, :start_date, Date.new!(year, month, 1))
    end
  end

  defp validate_end_month(changeset) do
    changeset = validate_required(changeset, :end_month)

    case get_change(changeset, :end_month) do
      nil ->
        changeset

      year_with_month ->
        [year, month] = year_with_month |> String.split("-") |> Enum.map(&String.to_integer/1)
        put_change(changeset, :end_date, Date.new!(year, month, 1))
    end
  end
end
