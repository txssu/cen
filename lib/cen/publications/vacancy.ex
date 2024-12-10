defmodule Cen.Publications.Vacancy do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Accounts.User
  alias Cen.Employers.Organization
  alias Cen.Publications.Enums

  @type t :: %__MODULE__{}

  schema "vacancies" do
    field :job_title, :string
    field :description, :string

    field :employment_types, {:array, Ecto.Enum}, values: Enums.employment_types()
    field :work_schedules, {:array, Ecto.Enum}, values: Enums.work_schedules()

    field :field_of_art, Ecto.Enum, values: Enums.field_of_arts()
    field :education, Ecto.Enum, values: Enums.educations()

    field :min_years_of_work_experience, :integer
    field :proposed_salary, :integer

    field :reviewed_at, :utc_datetime

    belongs_to :user, User
    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  @fields [
    :job_title,
    :field_of_art,
    :description,
    :employment_types,
    :work_schedules,
    :education,
    :min_years_of_work_experience,
    :proposed_salary
  ]

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vacancy, attrs) do
    vacancy
    |> cast(attrs, @fields)
    |> validate_job_title()
    |> validate_field_of_art()
    |> validate_description()
    |> validate_employment_types()
    |> validate_work_schedules()
    |> validate_education()
    |> validate_min_years_of_work_experience()
    |> validate_proposed_salary()
  end

  defp validate_job_title(changeset) do
    changeset
    |> validate_required(:job_title)
    |> validate_length(:job_title, max: 100)
  end

  defp validate_field_of_art(changeset) do
    validate_required(changeset, :field_of_art)
  end

  defp validate_description(changeset) do
    changeset
    |> validate_required(:description)
    |> validate_length(:description, max: 2000)
  end

  defp validate_employment_types(changeset) do
    changeset
    |> validate_required(:employment_types)
    |> validate_length(:employment_types, min: 1)
  end

  defp validate_work_schedules(changeset) do
    changeset
    |> validate_required(:work_schedules)
    |> validate_length(:work_schedules, min: 1)
  end

  defp validate_education(changeset) do
    validate_required(changeset, :education)
  end

  defp validate_min_years_of_work_experience(changeset) do
    changeset
  end

  defp validate_proposed_salary(changeset) do
    changeset
  end
end
