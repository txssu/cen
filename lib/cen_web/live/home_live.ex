defmodule CenWeb.HomeLive do
  @moduledoc false
  use CenWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-6 lg:pl-16">
      <.header header_kind="blue_left" class="mt-14">
        <span class="lg:text-7xl">
          <%= dgettext("home", "Творческий образовательный навигатор: Вакансии") %>
        </span>
      </.header>

      <div :if={is_nil(@current_user)} class="mt-10 flex gap-2.5 lg:gap-8">
        <.arrow_button phx-click={JS.navigate(~p"/users/register")}>
          <%= dgettext("home", "Зарегистрироваться") %>
        </.arrow_button>

        <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/users/log_in")}>
          <%= dgettext("home", "Войти") %>
        </.regular_button>
      </div>
    </div>

    <div class="text-title-text mt-10 flex flex-col gap-2.5 lg:col-span-3 lg:col-start-8 lg:gap-9">
      <section class="shadow-home-card bg-[#F8F8F8] rounded-lg p-8">
        <h2 class="text-lg uppercase"><%= dgettext("home", "Для соискателей") %></h2>
        <ul class="mt-2.5">
          <li><%= dgettext("home", "Удобный поиск работы и практики") %></li>
          <li><%= dgettext("home", "Актуальные вакансии") %></li>
          <li><%= dgettext("home", "Создание резюме") %></li>
          <li><%= dgettext("home", "Связь с работодателем") %></li>
        </ul>
      </section>

      <section class="shadow-home-card bg-[#F8F8F8] rounded-lg p-8">
        <h2 class="text-lg uppercase"><%= dgettext("home", "Для работодателей") %></h2>
        <ul class="mt-2.5">
          <li><%= dgettext("home", "Бесплатное размещение вакансий") %></li>
          <li><%= dgettext("home", "Удобный поиск соискателей и практикантов") %></li>
          <li><%= dgettext("home", "Связь с соискателем") %></li>
        </ul>
      </section>
    </div>
    """
  end
end
