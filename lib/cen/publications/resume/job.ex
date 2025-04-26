defmodule Cen.Publications.Resume.Job do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @year_month_regex ~r/^(?<year>\d{4})-(?<month>0[1-9]|1[0-2])$/

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

  defp validate_start_month(changeset), do: put_year_month_date(changeset, :start_month, :start_date)

  defp validate_end_month(changeset), do: put_year_month_date(changeset, :end_month, :end_date)

  defp put_year_month_date(changeset, src_field, dest_field) do
    changeset
    |> validate_required(src_field)
    |> validate_change(src_field, fn ^src_field, val ->
      case Regex.named_captures(@year_month_regex, to_string(val)) do
        %{"year" => y, "month" => m} ->
          {:ok, date} = Date.new(String.to_integer(y), String.to_integer(m), 1)
          put_change(changeset, dest_field, date)
          []

        _ ->
          [{src_field, "Должно быть в формате ГГГГ-ММ (пример 2025-04)"}]
      end
    end)
  end
end
