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
          <%= @title %>
        </.header>
        <div class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/cvs/new")}>
            <.icon name="cen-plus" alt={gettext("Создать")} />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for resume <- @resumes do %>
          <li>
            <.basic_card class="w-full py-7 px-6" header={resume.job_title}>
              <p class="text-title-text mt-2.5">
                <%= resume.user.fullname %>, <%= Accounts.calculate_user_age(resume.user) %>
              </p>
              <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(resume_path(@live_action, resume))}>
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
    action = socket.assigns.live_action

    verify_has_permission!(socket.assigns.current_user, :resumes, action)

    {:ok, socket |> assign_title(action) |> load_resumes(action)}
  end

  defp assign_title(socket, live_action) do
    case live_action do
      :index_for_user -> assign(socket, :title, dgettext("publications", "Мои резюме"))
      :index_for_review -> assign(socket, :title, dgettext("publications", "Резюме на проверке"))
    end
  end

  defp load_resumes(socket, :index_for_user) do
    resumes = Publications.list_resumes_for(socket.assigns.current_user)

    if resumes == [] do
      push_navigate(socket, to: ~p"/cvs/new")
    else
      assign(socket, resumes: resumes)
    end
  end

  defp load_resumes(socket, :index_for_review) do
    resumes = Publications.list_not_reviewed_resumes()
    assign(socket, resumes: resumes)
  end

  defp resume_path(:index_for_user, resume), do: ~p"/cvs/#{resume}"
  defp resume_path(:index_for_review, resume), do: ~p"/cvs/#{resume}/review"
end
