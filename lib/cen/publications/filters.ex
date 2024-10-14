defmodule Cen.Publications.Filters do
  @moduledoc false

  import Cen.Utils.QueryFilter
  import Ecto.Query

  def filter_work_schedules(query, work_schedules), do: filter_array(query, :work_schedules, work_schedules)
  def filter_employment_types(query, work_schedules), do: filter_array(query, :employment_types, work_schedules)

  defp filter_array(query, _field, data) when data in [nil, []], do: query

  defp filter_array(query, field, data) do
    filter(query, field, :intersection, Enum.map(data, &Atom.to_string/1))
  end

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

  def filter_education(query, nil), do: query

  def filter_education(query, education) do
    educations = education |> Atom.to_string() |> smaller_educations()

    from(resume in query,
      where:
        fragment(
          "EXISTS (SELECT * FROM unnest(?) AS education WHERE education->>'level' = ANY(?))",
          resume.educations,
          ^educations
        )
    )
  end

  @educations Enum.map(Cen.Publications.Enums.educations(), &to_string/1)

  defp smaller_educations(education), do: Enum.drop_while(@educations, &(&1 != education))
end
