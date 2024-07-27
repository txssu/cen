defmodule CenWeb.UserSettings.Components do
  @moduledoc false
  use CenWeb, :html

  attr :current_page, :atom, required: true, values: [:personal, :credentials]

  @spec navigation(map()) :: Phoenix.LiveView.Rendered.t()
  def navigation(assigns) do
    ~H"""
    <p class="text-title-text text-2xl uppercase"><%= dgettext("users", "Настройки") %></p>
    <ul class="mt-[0.9375rem] flex gap-5">
      <li>
        <.maybe_link navigate={~p"/users/settings/personal"} is_link={@current_page != :personal}>
          <%= dgettext("users", "Личные данные") %>
        </.maybe_link>
      </li>

      <li>
        <.maybe_link
          navigate={~p"/users/settings/credentials"}
          is_link={@current_page != :credentials}
        >
          <%= dgettext("users", "Данные для входа") %>
        </.maybe_link>
      </li>
    </ul>
    """
  end

  attr :navigate, :string, required: true
  attr :is_link, :boolean, required: true

  slot :inner_block, required: true

  def maybe_link(%{is_link: true} = assigns) do
    ~H"""
    <.link class="link-hover" navigate={@navigate}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def maybe_link(assigns) do
    ~H"""
    <span class="text-accent">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
