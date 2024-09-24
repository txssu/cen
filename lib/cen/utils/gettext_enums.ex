defmodule Cen.Utils.GettextEnums do
  @moduledoc false

  @type enums_list :: [atom(), ...]
  @type translations_list :: [{String.t(), String.t()}, ...]

  defmacro __using__(_options) do
    quote do
      use Gettext, backend: CenWeb.Gettext

      import unquote(__MODULE__)

      require unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :__cen_enums__, accumulate: true)
    end
  end

  defmacro def_translation_enum(name, enum) do
    quote bind_quoted: [enum: enum, name: name] do
      @__cen_enums__ {name, enum}
    end
  end

  defmacro __before_compile__(env) do
    env.module
    |> Module.get_attribute(:__cen_enums__)
    |> Enum.map(fn {name, enum} -> define_enum(name, enum) end)
  end

  defp define_enum(name, enum) do
    enum_translations = get_translations(enum)

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    translation_name = String.to_atom("#{name}_translations")

    fun = {name, [], []}
    translation_fun = {translation_name, [], []}

    quote do
      @spec unquote(fun) :: unquote(__MODULE__).enums_list()
      def unquote(fun), do: unquote(enum)
      @spec unquote(translation_fun) :: unquote(__MODULE__).translations_list()
      def unquote(translation_fun), do: unquote(enum_translations)
    end
  end

  defp get_translations(enum) do
    Enum.map(enum, fn value ->
      value = to_string(value)
      text = value |> String.capitalize() |> String.replace("_", " ")
      quote(do: {dgettext("enums", unquote(text)), unquote(value)})
    end)
  end

  @spec enums_to_translation(enums_list(), translations_list()) :: String.t()
  def enums_to_translation(values, translations) do
    values
    |> Enum.map_join(", ", &enum_to_translation(&1, translations))
    |> String.capitalize()
  end

  @spec enum_to_translation(String.t(), translations_list()) :: String.t()
  def enum_to_translation(value, translations) do
    value = to_string(value)

    translations
    |> Enum.find(fn {_ts, enum} -> enum == value end)
    |> elem(0)
  end
end
