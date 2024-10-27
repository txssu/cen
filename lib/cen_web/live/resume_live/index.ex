defmodule CenWeb.ResumeLive.Index do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Accounts
  alias Cen.Publications

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <div class="flex items-center">
        <.header header_kind="black_left">
          <%= dgettext("publications", "Мои резюме") %>
        </.header>
        <div class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/me/cvs/new")}>
            <.icon name="cen-plus" alt={gettext("Создать")} />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for resume <- @resumes do %>
          <li>
            <.basic_card class="w-full py-7 px-6" header={resume.job_title}>
              <p class="text-title-text mt-2.5">
                <%= @current_user.fullname %>, <%= Accounts.calculate_user_age(@current_user) %>
              </p>
              <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(~p"/me/cvs/#{resume}")}>
                <%= gettext("Открыть") %>
              </.regular_button>
            </.basic_card>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    verify_has_permission!(user, :resumes, :index)
    resumes = Publications.list_resumes_for(user)

    if resumes == [] do
      {:ok, push_navigate(socket, to: ~p"/me/cvs/new")}
    else
      {:ok, assign(socket, resumes: resumes)}
    end
  end
end
