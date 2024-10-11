defmodule Cen.Publications.Enums do
  @moduledoc false

  use Cen.Utils.GettextEnums

  def_translation_enum(:employment_types, ~w[main secondary_job practice internship]a)
  def_translation_enum(:work_schedules, ~w[full_time part_time remote_working hybrid_working flexible_schedule]a)

  @doc """
  Educations enum.

  This is a comparable enumeration, the entities are arranged in ascending order.
  """
  def_translation_enum(:educations, ~w[none secondary secondary_vocational bachelor master doctor]a)

  def_translation_enum(:resume_educations, ~w[secondary secondary_vocational bachelor master doctor]a)

  def_translation_enum(:field_of_arts, ~w[music visual performing choreography folklore other]a)
end
