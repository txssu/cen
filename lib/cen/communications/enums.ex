defmodule Cen.Communications.Enums do
  @moduledoc false

  use Cen.Utils.GettextEnums

  def_translation_enum(:notification_types, ~w[success warning]a)
end
