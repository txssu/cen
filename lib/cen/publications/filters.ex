defmodule Cen.Publications.Filters do
  @moduledoc false

  import Cen.Utils.QueryFilter
  import Ecto.Query

  @spec filter_work_schedules(Ecto.Queryable.t(), list()) :: Ecto.Query.t()
  def filter_work_schedules(query, work_schedules), do: filter_array(query, :work_schedules, work_schedules)

  @spec filter_employment_types(Ecto.Queryable.t(), list()) :: Ecto.Query.t()
  def filter_employment_types(query, work_schedules), do: filter_array(query, :employment_types, work_schedules)

  defp filter_array(query, _field, data) when data in [nil, []], do: query

  defp filter_array(query, field, data) do
    filter(query, field, :intersection, Enum.map(data, &Atom.to_string/1))
  end

  @spec filter_work_experience(Ecto.Queryable.t(), integer() | nil) :: Ecto.Query.t()
  def filter_work_experience(query, nil), do: query

  def filter_work_experience(query, min_years_of_work_experience) do
    from(resume in query,
      where:
        fragment(
          "(SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (COALESCE(TO_DATE(job->>'end_date', 'YYYY-MM-DD'), NOW()) - TO_DATE(job->>'start_date', 'YYYY-MM-DD'))) / (60 * 60 * 24 * 365)), 0) FROM unnest(?) AS job) >= ?",
          resume.jobs,
          ^min_years_of_work_experience
        )
    )
  end

  @spec filter_resume_educations(Ecto.Queryable.t(), atom() | nil) :: Ecto.Query.t()
  def filter_resume_educations(query, nil), do: query

  def filter_resume_educations(query, education) do
    educations =
      education
      |> Atom.to_string()
      |> not_smaller_educations()

    from(resume in query,
      where:
        fragment(
          "EXISTS (SELECT * FROM unnest(?) AS education WHERE education->>'level' = ANY(?))",
          resume.educations,
          ^educations
        )
    )
  end

  @spec filter_vacancy_educations(Ecto.Queryable.t(), atom() | nil) :: Ecto.Query.t()
  def filter_vacancy_educations(query, nil), do: query

  def filter_vacancy_educations(query, education) do
    educations =
      education
      |> Atom.to_string()
      |> not_greater_educations()

    filter(query, :education, :field_in_value, educations)
  end

  @educations Enum.map(Cen.Publications.Enums.educations(), &to_string/1)
  @educations_reverse Enum.reverse(@educations)

  defp not_smaller_educations(education), do: Enum.drop_while(@educations, &(&1 != education))
  defp not_greater_educations(education), do: Enum.drop_while(@educations_reverse, &(&1 != education))
end
