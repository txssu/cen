defmodule CenWeb.InteractionLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias Cen.Communications
  alias Cen.Publications

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <.header header_kind="black_left">
        <%= header_text(@initiator) %>
      </.header>
      <ul class="mt-7 space-y-6">
        <%= for interaction <- @interactions do %>
          <.interest_list_item interaction={interaction} initiator={@initiator} rendered_entity={@rendered_entity} />
        <% end %>
        <%= if @interactions == [] do %>
          <%= gettext("Тут пока пусто") %>
        <% end %>
      </ul>
    </div>
    """
  end

  defp interest_list_item(%{rendered_entity: :resume, initiator: initiator} = assigns) do
    resume = assigns.interaction.resume

    resume_link =
      case initiator do
        :resume -> ~p"/res/cvs/#{resume.id}"
        :vacancy -> ~p"/invs/cvs/#{resume.id}"
      end

    assigns = assign(assigns, resume: resume, resume_link: resume_link)

    ~H"""
    <li>
      <.basic_card class="w-full py-7 px-6" header={@resume.job_title}>
        <p class="text-title-text mt-2.5">
          <%= @resume.user.fullname %>, <%= Accounts.calculate_user_age(@resume.user) %>
        </p>
        <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(@resume_link)}>
          <%= gettext("Открыть") %>
        </.regular_button>
      </.basic_card>
    </li>
    """
  end

  defp interest_list_item(%{rendered_entity: :vacancy, initiator: initiator} = assigns) do
    vacancy = assigns.interaction.vacancy

    vacancy_link =
      case initiator do
        :resume -> ~p"/res/jobs/#{vacancy.id}"
        :vacancy -> ~p"/invs/jobs/#{vacancy.id}"
      end

    assigns = assign(assigns, vacancy: vacancy, vacancy_link: vacancy_link)

    ~H"""
    <li>
      <.basic_card class="w-full py-7 px-6" header={@vacancy.job_title}>
        <p :if={@vacancy.proposed_salary} class="text-title-text mt-2.5">
          <%= pgettext("money", "от") %> <%= Publications.format_salary(@vacancy.proposed_salary) %>
        </p>
        <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
          <%= @vacancy.organization.name %>
        </p>
        <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(@vacancy_link)}>
          <%= gettext("Открыть") %>
        </.regular_button>
      </.basic_card>
    </li>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    initiator =
      case socket.assigns.live_action do
        :responses -> :resume
        :invitations -> :vacancy
      end

    interactions = Communications.list_interactions_for(user, initiator)

    rendered_entity =
      case user.role do
        :employer -> :resume
        :applicant -> :vacancy
      end

    {:ok, assign(socket, interactions: interactions, initiator: initiator, rendered_entity: rendered_entity)}
  end

  defp header_text(:resume), do: dgettext("publications", "Отклики")
  defp header_text(:vacancy), do: dgettext("publications", "Приглашения")
end
