defmodule Cen.Publications.Resume do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Cen.Accounts.User
  alias Cen.Publications.Enums
  alias Cen.Publications.Resume.Education
  alias Cen.Publications.Resume.Job

  @type t :: %__MODULE__{}

  schema "resumes" do
    field :description, :string
    field :job_title, :string
    field :field_of_art, Ecto.Enum, values: Enums.field_of_arts()

    field :employment_types, {:array, Ecto.Enum}, values: Enums.employment_types()
    field :work_schedules, {:array, Ecto.Enum}, values: Enums.work_schedules()

    field :reviewed_at, :utc_datetime

    embeds_many :educations, Education, on_replace: :delete
    embeds_many :jobs, Job, on_replace: :delete

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(resume, attrs) do
    resume
    |> cast(attrs, [:job_title, :field_of_art, :description, :employment_types, :work_schedules])
    |> validate_job_title()
    |> validate_field_of_art()
    |> validate_description()
    |> validate_employment_types()
    |> validate_work_schedules()
    |> validate_educations()
    |> validate_jobs()
  end

  @spec set_reviewed_at(t(), DateTime.t() | nil) :: Ecto.Changeset.t()
  def set_reviewed_at(resume, reviewed_at) do
    change(resume, %{reviewed_at: reviewed_at})
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
    |> validate_length(:description, max: 1000)
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

  defp validate_educations(changeset) do
    cast_embed(changeset, :educations,
      required: true,
      sort_param: :educations_order,
      drop_param: :educations_drop
    )
  end

  defp validate_jobs(changeset) do
    cast_embed(changeset, :jobs,
      sort_param: :jobs_order,
      drop_param: :jobs_drop
    )
  end
end
