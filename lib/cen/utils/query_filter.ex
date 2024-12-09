defmodule Cen.Utils.QueryFilter do
  @moduledoc false
  import Ecto.Query, warn: false

  @type operator :: :eq | :value_in_field | :field_in_value | :intersection | :not_gt | :not_lt | :search

  @spec filter(Ecto.Queryable.t(), term(), operator, term()) :: Ecto.Query.t()
  def filter(query, field_name, operator, value)

  def filter(query, _field_name, _operator, nil), do: query

  def filter(query, field_name, :eq, value) do
    where(query, [record], field(record, ^field_name) == ^value)
  end

  def filter(query, field_name, :value_in_field, value) do
    where(query, [record], ^value in field(record, ^field_name))
  end

  def filter(query, field_name, :field_in_value, value) do
    where(query, [record], field(record, ^field_name) in ^value)
  end

  def filter(query, field_name, :intersection, values) do
    where(query, [record], fragment("? && ?", field(record, ^field_name), ^values))
  end

  def filter(query, field_name, :not_lt, value) do
    where(query, [record], field(record, ^field_name) >= ^value or is_nil(field(record, ^field_name)))
  end

  def filter(query, field_name, :not_gt, value) do
    where(query, [record], field(record, ^field_name) <= ^value or is_nil(field(record, ^field_name)))
  end

  def filter(query, field_name, :search, value) do
    from(
      from record in query,
        where:
          fragment(
            "? @@ websearch_to_tsquery('russian', ?)",
            field(record, ^field_name),
            ^value
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(?, websearch_to_tsquery('russian', ?))",
            field(record, ^field_name),
            ^value
          )
        }
    )
  end

  @type is_nil_operator :: :is_not_nil

  @spec filter(Ecto.Queryable.t(), term(), is_nil_operator) :: Ecto.Query.t()
  def filter(query, field_name, :is_not_nil) do
    where(query, [record], not is_nil(field(record, ^field_name)))
  end
end
