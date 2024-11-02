defmodule CenWeb.RootComponents do
  @moduledoc false
  use CenWeb, :html

  attr :current_user, :any, required: true
  attr :horizontal, :boolean, default: false

  @spec menu_items(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def menu_items(assigns) do
    ~H"""
    <%= if @current_user do %>
      <%= if @current_user.role == :employer do %>
        <.navbar_link navigate={~p"/cvs/search"} horizontal={@horizontal}><%= dgettext("users", "Искать резюме") %></.navbar_link>
        <.navbar_link navigate={~p"/me/orgs"} horizontal={@horizontal}><%= dgettext("users", "Организации") %></.navbar_link>
        <.navbar_link navigate={~p"/me/jobs"} horizontal={@horizontal}><%= dgettext("users", "Вакансии") %></.navbar_link>
        <.navbar_link navigate={~p"/me/res"} horizontal={@horizontal}><%= dgettext("users", "Отклики") %></.navbar_link>
        <.navbar_link navigate={~p"/me/invs"} horizontal={@horizontal}><%= dgettext("users", "Приглашения") %></.navbar_link>
      <% end %>
      <%= if @current_user.role == :applicant do %>
        <.navbar_link navigate={~p"/jobs/search"} horizontal={@horizontal}><%= dgettext("users", "Искать вакансии") %></.navbar_link>
        <.navbar_link navigate={~p"/me/cvs"} horizontal={@horizontal}><%= dgettext("users", "Резюме") %></.navbar_link>
        <.navbar_link navigate={~p"/me/res"} horizontal={@horizontal}><%= dgettext("users", "Отклики") %></.navbar_link>
        <.navbar_link navigate={~p"/me/invs"} horizontal={@horizontal}><%= dgettext("users", "Приглашения") %></.navbar_link>
      <% end %>
      <.navbar_link navigate={~p"/users/settings/personal"} horizontal={@horizontal} to_right>
        <%= if @horizontal do %>
          <div class="bg-accent inline-block h-11 w-11 rounded-full"></div>
        <% else %>
          <%= dgettext("users", "Профиль") %>
        <% end %>
      </.navbar_link>
    <% else %>
      <.navbar_link navigate={~p"/users/register"} horizontal={@horizontal} to_right><%= dgettext("users", "Регистрация") %></.navbar_link>
      <.navbar_link navigate={~p"/users/log_in"} horizontal={@horizontal}><%= dgettext("users", "Вход") %></.navbar_link>
    <% end %>
    """
  end

  @spec toggle_menu() :: JS.t()
  def toggle_menu do
    base = "overflow-hidden [&_li]:transition-all [&_li]:duration-200"
    hidden = "[&_li]:h-0 [&_li]:opacity-0"
    visible = "[&_li]:h-12 [&_li]:opacity-100"

    JS.toggle(
      to: "#navbar-menu",
      display: "flex",
      in: {base, hidden, visible},
      out: {base, visible, hidden},
      time: 200
    )
  end

  @spec hide_menu() :: JS.t()
  def hide_menu do
    JS.hide(to: "#navbar-menu")
  end

  attr :horizontal, :boolean, default: false
  attr :to_right, :boolean, default: false
  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  slot :inner_block, required: true

  defp navbar_link(assigns) do
    height = if not assigns.horizontal, do: "h-12"
    to_right = if assigns.to_right and assigns.horizontal, do: "ml-auto"

    class = [height, to_right] |> Enum.filter(& &1) |> Enum.join(" ")

    assigns = assign(assigns, :class, class)

    ~H"""
    <li class={@class}>
      <.link class="text-navbargray no-underline text-xl leading-[1.35] font-light hover:text-accent w-full h-full block" phx-click={hide_menu()} {@rest}>
        <div class="flex h-full items-center">
          <%= render_slot(@inner_block) %>
        </div>
      </.link>
    </li>
    """
  end
end
