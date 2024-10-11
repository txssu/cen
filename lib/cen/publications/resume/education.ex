defmodule Cen.Publications.Resume.Education do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Publications.Enums

  @type t :: %__MODULE__{}

  embedded_schema do
    field :level, Ecto.Enum, values: Enums.resume_educations()
    field :educational_institution, :string
    field :department, :string
    field :specialization, :string
    field :year_of_graduation, :integer
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(education, attrs) do
    education
    |> cast(attrs, [:level, :educational_institution, :department, :specialization, :year_of_graduation])
    |> validate_level()
    |> validate_educational_institution()
    |> validate_department()
    |> validate_specialization()
    |> validate_year_of_graduation()
  end

  defp validate_level(changeset) do
    validate_required(changeset, :level)
  end

  defp validate_educational_institution(changeset) do
    changeset
    |> validate_required(:educational_institution)
    |> validate_length(:educational_institution, max: 255)
  end

  defp validate_department(changeset) do
    changeset
  end

  defp validate_specialization(changeset) do
    changeset
    |> validate_required(:specialization)
    |> validate_length(:specialization, max: 255)
  end

  defp validate_year_of_graduation(changeset) do
    validate_required(changeset, :year_of_graduation)
  end
end
