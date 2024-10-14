defmodule Cen.Publications.VacancySearchOptions do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Publications.Enums

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :query, :string

    field :field_of_art, Ecto.Enum, values: Enums.field_of_arts()

    field :employment_types, {:array, Ecto.Enum}, values: Enums.employment_types(), default: []
    field :work_schedules, {:array, Ecto.Enum}, values: Enums.work_schedules(), default: []

    field :education, Ecto.Enum, values: Enums.educations()

    field :min_years_of_work_experience, :integer
    field :proposed_salary, :integer
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vacancy, attrs) do
    cast(vacancy, attrs, [:query, :field_of_art, :employment_types, :work_schedules, :education, :min_years_of_work_experience, :proposed_salary])
  end
end
