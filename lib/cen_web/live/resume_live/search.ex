defmodule CenWeb.ResumeLive.Search do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias Cen.Permissions
  alias Cen.Publications

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <.simple_form for={@search_params} id="search-form" phx-submit="save">
        <div class="lg:grid lg:grid-cols-12 lg:gap-10">
          <div class="hidden lg:col-span-3 lg:block">
            <%= if not @render_modal do %>
              <.filters search_params={@search_params} />
            <% end %>
          </div>

          <div class="lg:col-span-9 lg:col-start-4">
            <.header header_kind="black_left"><%= dgettext("search", "Кого вы ищете?") %></.header>

            <div class="mt-4 flex items-center gap-4">
              <div class="relative grow">
                <div class="[&_input]:mt-0 [&_input]:pl-10 [&_label]:mt-0">
                  <.input field={@search_params[:query]} type="text" placeholder={dgettext("search", "Должность")} />
                </div>
                <div class="absolute top-1/2 left-4 -translate-y-1/2">
                  <.icon name="cen-search" />
                </div>
              </div>
              <div class="block lg:hidden">
                <.button type="button" class="bg-white p-4" phx-click={show_modal(JS.push("show_modal"), "filters-modal")}>
                  <.icon name="cen-quick-actions" class="w-3.5 h-3.5" alt={dgettext("search", "Фильтры")} />
                </.button>
              </div>
            </div>

            <.filters_modal id="filters-modal">
              <.header header_kind="black_center"><%= dgettext("search", "Фильтры") %></.header>
              <%= if @render_modal do %>
                <.filters search_params={@search_params} />
              <% end %>
            </.filters_modal>

            <div class="lg:col-span-9 lg:col-start-3">
              <ul class="mt-6 space-y-4">
                <li :for={resume <- @search_result}>
                  <.basic_card class="w-full py-7 px-6" header={resume.job_title}>
                    <p class="text-title-text mt-2.5">
                      <%= resume.user.fullname %>, <%= Accounts.calculate_user_age(resume.user) %>
                    </p>
                    <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(~p"/cvs/#{resume}")}>
                      <%= gettext("Открыть") %>
                    </.regular_button>
                  </.basic_card>
                </li>
              </ul>
              <div class="mt-4">
                <.pagination metadata={@search_metadata} path={~p"/cvs/search"} />
              </div>
            </div>
          </div>
        </div>
      </.simple_form>
    </div>
    """
  end

  defp filters(assigns) do
    ~H"""
    <div class="space-y-10">
      <.input
        field={@search_params[:field_of_art]}
        type="select"
        prompt={dgettext("publications", "Все")}
        label={dgettext("publications", "Сфера искусства")}
        options={Publications.Enums.field_of_arts_translations()}
      />
      <.input
        field={@search_params[:employment_types]}
        type="checkbox"
        options={Publications.Enums.employment_types_translations()}
        label={dgettext("publications", "Тип занятости")}
        multiple
      />
      <.input
        field={@search_params[:work_schedules]}
        type="checkbox"
        options={Publications.Enums.work_schedules_translations()}
        label={dgettext("publications", "График работы")}
        multiple
      />
      <.input
        field={@search_params[:education]}
        type="select"
        label={dgettext("publications", "Образование")}
        options={Publications.Enums.educations_translations()}
      />
      <.input
        field={@search_params[:min_years_of_work_experience]}
        type="textcard"
        maxlength="2"
        label={dgettext("publications", "Опыт работы")}
        text_before={dgettext("publications", "от")}
        text_after={dgettext("publications", "лет")}
      />
      <div class="flex gap-2.5">
        <.arrow_button class="grow text-center [&_span]:w-full" phx-click={hide_modal("filters-modal")}>
          <%= gettext("Применить") %>
        </.arrow_button>
        <.regular_button class="bg-accent-hover" type="button" phx-click="reset">
          <%= gettext("Сбросить") %>
        </.regular_button>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    Permissions.verify_has_permission!(socket.assigns.current_user, :resumes, :search)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:ok, {search_result, metadata}} = Publications.search_resumes(params)

    assigns = [
      search_result: search_result,
      search_params: to_form(params, as: "search_params"),
      search_metadata: metadata,
      render_modal: false
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"search_params" => params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/cvs/search?#{params}")}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    params = Map.put(socket.assigns.search_params, "page", page)
    {:noreply, push_patch(socket, to: ~p"/cvs/search?#{params}")}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/cvs/search")}
  end

  def handle_event("show_modal", _params, socket) do
    {:noreply, assign(socket, render_modal: true)}
  end
end
