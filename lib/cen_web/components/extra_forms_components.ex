# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule CenWeb.ExtraFormsComponents do
  @moduledoc false
  use CenWeb, :html

  import CenWeb.CoreComponents

  alias Phoenix.HTML.FormField

  attr :legend, :string, required: true
  attr :field, FormField, required: true
  attr :options, :list, required: true

  def radio(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(field: nil, id: field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:selected_value, to_string(field.value))
      |> assign_new(:name, fn -> field.name end)

    ~H"""
    <fieldset class="flex flex-row flex-wrap justify-between gap-y-2.5 sm:flex-col md:flex-row lg:flex-col xl:flex-row">
      <p class="text-xl uppercase"><%= @legend %></p>
      <div :for={{label, value} <- @options}>
        <label>
          <input
            id={"#{@id}-#{value}"}
            type="radio"
            name={@name}
            value={value}
            checked={@selected_value == value}
          />
          <%= label %>
        </label>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </fieldset>
    """
  end
end
