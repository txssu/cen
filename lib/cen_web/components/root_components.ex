defmodule CenWeb.RootComponents do
  @moduledoc false
  use CenWeb, :html

  attr :current_user, :any, required: true
  attr :horizontal, :boolean, default: false

  @spec menu_items(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def menu_items(assigns) do
    ~H"""
    <%= if @current_user do %>
      <%= if @current_user.role == nil do %>
        <.navbar_link navigate={~p"/users/choose_role"} horizontal={@horizontal}><%= dgettext("users", "Выбрать роль") %></.navbar_link>
      <% end %>
      <%= if @current_user.role == :employer do %>
        <.navbar_link navigate={~p"/cvs/search"} horizontal={@horizontal}><%= dgettext("users", "Искать резюме") %></.navbar_link>
        <.navbar_link navigate={~p"/orgs"} horizontal={@horizontal}><%= dgettext("users", "Организации") %></.navbar_link>
        <.navbar_link navigate={~p"/jobs"} horizontal={@horizontal}><%= dgettext("users", "Вакансии") %></.navbar_link>
        <.navbar_link navigate={~p"/res"} horizontal={@horizontal}><%= dgettext("users", "Отклики") %></.navbar_link>
        <.navbar_link navigate={~p"/invs"} horizontal={@horizontal}><%= dgettext("users", "Приглашения") %></.navbar_link>
      <% end %>
      <%= if @current_user.role == :applicant do %>
        <.navbar_link navigate={~p"/jobs/search"} horizontal={@horizontal}><%= dgettext("users", "Искать вакансии") %></.navbar_link>
        <.navbar_link navigate={~p"/cvs"} horizontal={@horizontal}><%= dgettext("users", "Резюме") %></.navbar_link>
        <.navbar_link navigate={~p"/res"} horizontal={@horizontal}><%= dgettext("users", "Отклики") %></.navbar_link>
        <.navbar_link navigate={~p"/invs"} horizontal={@horizontal}><%= dgettext("users", "Приглашения") %></.navbar_link>
      <% end %>
      <%= if @current_user.role == :admin do %>
        <.navbar_link navigate={~p"/cvs/search"} horizontal={@horizontal}><%= dgettext("users", "Резюме") %></.navbar_link>
        <.navbar_link navigate={~p"/jobs/search"} horizontal={@horizontal}><%= dgettext("users", "Вакансии") %></.navbar_link>
        <.navbar_link navigate={~p"/orgs"} horizontal={@horizontal}><%= dgettext("users", "Организации") %></.navbar_link>
        <.navbar_link navigate={~p"/cvs/review"} horizontal={@horizontal}><%= dgettext("users", "Резюме на проверке") %></.navbar_link>
        <.navbar_link navigate={~p"/jobs/review"} horizontal={@horizontal}><%= dgettext("users", "Вакансии на проверке") %></.navbar_link>
        <.navbar_link navigate={~p"/users"} horizontal={@horizontal}><%= dgettext("users", "Пользователи") %></.navbar_link>
      <% end %>
      <.navbar_list_item horizontal={@horizontal} to_right>
        <div class="flex gap-10">
          <button
            type="button"
            class="text-navbargray leading-[1.35] block h-full w-full text-left text-xl font-light no-underline hover:text-accent"
            phx-click={toggle_notifications()}
          >
            <%= if @horizontal do %>
              <div class="h-6 w-6">
                <.icon name="cen-notification" />
              </div>
            <% else %>
              <%= dgettext("users", "Уведомления") %>
            <% end %>
          </button>
          <button
            type="button"
            class="text-navbargray leading-[1.35] block h-full w-full text-left text-xl font-light no-underline hover:text-accent"
            phx-click={show_modal("chat_modal")}
          >
            <%= if @horizontal do %>
              <div class="h-6 w-6">
                <.icon name="cen-chat" />
              </div>
            <% else %>
              <%= dgettext("users", "Сообщения") %>
            <% end %>
          </button>
        </div>
      </.navbar_list_item>
      <.navbar_link navigate={~p"/users/settings/personal"} horizontal={@horizontal}>
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

  @spec toggle_notifications() :: JS.t()
  def toggle_notifications do
    base = "duration-100"
    hidden = "opacity-0"
    visible = "opacity-100"

    JS.toggle(
      to: "#notifications_wrapper",
      in: {base, hidden, visible},
      out: {base, visible, hidden},
      time: 100
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
    <.navbar_list_item horizontal={@horizontal} to_right={@to_right}>
      <.link class="text-navbargray no-underline text-xl leading-[1.35] font-light hover:text-accent w-full h-full block" phx-click={hide_menu()} {@rest}>
        <div class="flex h-full items-center">
          <%= render_slot(@inner_block) %>
        </div>
      </.link>
    </.navbar_list_item>
    """
  end

  attr :horizontal, :boolean, default: false
  attr :to_right, :boolean, default: false

  slot :inner_block, required: true

  defp navbar_list_item(assigns) do
    height = if not assigns.horizontal, do: "h-12"
    to_right = if assigns.to_right and assigns.horizontal, do: "ml-auto"

    class = [height, to_right] |> Enum.filter(& &1) |> Enum.join(" ")

    assigns = assign(assigns, :class, class)

    ~H"""
    <li class={@class}>
      <%= render_slot(@inner_block) %>
    </li>
    """
  end
end
