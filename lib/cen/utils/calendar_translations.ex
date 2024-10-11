defmodule Cen.Utils.CalendarTranslations do
  @moduledoc false
  use Gettext, backend: CenWeb.Gettext

  @spec month_names(1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12) :: String.t()
  def month_names(1), do: gettext("Январь")
  def month_names(2), do: gettext("Февраль")
  def month_names(3), do: gettext("Март")
  def month_names(4), do: gettext("Апрель")
  def month_names(5), do: gettext("Май")
  def month_names(6), do: gettext("Июнь")
  def month_names(7), do: gettext("Июль")
  def month_names(8), do: gettext("Август")
  def month_names(9), do: gettext("Сентябрь")
  def month_names(10), do: gettext("Октябрь")
  def month_names(11), do: gettext("Ноябрь")
  def month_names(12), do: gettext("Декабрь")
end
