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
    |> put_start_month()
    |> put_start_date()
    |> put_end_month()
    |> put_end_date()
    |> validate_start_month()
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
    validate_required(changeset, :start_month)
  end

  defp put_start_date(changeset) do
    put_date(changeset, :start_month, :start_date)
  end

  defp put_end_date(changeset) do
    put_date(changeset, :end_month, :end_date)
  end

  defp put_date(changeset, src_field, dest_field) do
    if val = get_change(changeset, src_field) do
      case Regex.named_captures(~r/^(?<year>\d{4})-(?<month>0[1-9]|1[0-2])$/, to_string(val)) do
        %{"year" => y, "month" => m} ->
          {:ok, date} =
            y
            |> String.to_integer()
            |> Date.new(String.to_integer(m), 1)

          put_change(changeset, dest_field, date)

        _otherwise ->
          add_error(changeset, src_field, "Должно быть в формате ГГГГ-ММ (пример 2025-04)")
      end
    else
      changeset
    end
  end

  defp put_start_month(changeset) do
    put_month(changeset, :start_date, :start_month)
  end

  defp put_end_month(changeset) do
    put_month(changeset, :end_date, :end_month)
  end

  defp put_month(changeset, src_field, dest_field) do
    if val = get_field(changeset, src_field) do
      month =
        val.month
        |> to_string()
        |> String.pad_leading(2, "0")

      result = "#{val.year}-#{month}"
      put_change(changeset, dest_field, result)
    else
      changeset
    end
  end
end
