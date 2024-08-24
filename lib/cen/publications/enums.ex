defmodule Cen.Publications.Enums do
  @moduledoc false

  @type enums_list :: [atom(), ...]

  @spec employment_types() :: enums_list()
  def employment_types, do: ~w[main secondary practice internship]a

  @spec work_schedules() :: enums_list()
  def work_schedules, do: ~w[full_time part_time remote_working hybrid_working flexible_schedule]a

  @doc """
  Educations enum.

  This is a comparable enumeration, the entities are arranged in ascending order.
  """
  @spec educations() :: enums_list()
  def educations, do: ~w[none secondary secondary_vocational bachelor master doctor]a

  @spec field_of_arts() :: enums_list()
  def field_of_arts, do: ~w[music visual performing choreography folklore other]a
end
