defmodule CenWeb.OrganizationLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Employers

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <div class="space-y-6 lg:grid lg:grid-flow-dense lg:grid-cols-12 lg:gap-10 lg:space-y-0">
        <.header class="lg:col-span-12" header_kind="black_left">
          <%= @organization.name %>
        </.header>

        <div class="relative pt-16 lg:order-1 lg:col-span-3 lg:col-start-10 lg:pt-0">
          <.basic_card class="px-6 pt-24 pb-14" header={dgettext("orgs", "Контакты")}>
            <img
              src={image(@organization)}
              class="outline-[1rem] absolute top-0 left-1/2 h-32 w-32 -translate-x-1/2 rounded-full outline outline-white lg:-translate-y-1/2"
            />
            <ul class="mt-7 space-y-4">
              <%= for {value, icon} <- contacts_list(@organization) do %>
                <.render_not_nil value={value}>
                  <li class="flex items-center gap-2.5">
                    <.icon name={icon} class="w-4 h-4" />
                    <div class="leading-[1.2] text-sm font-light text-black">
                      <%= value %>
                    </div>
                  </li>
                </.render_not_nil>
              <% end %>
            </ul>
          </.basic_card>
        </div>

        <div class="flex gap-2.5 lg:col-span-12">
          <.regular_button
            class="bg-accent-hover"
            phx-click={JS.navigate(~p"/organizations/#{@organization}/edit")}
          >
            <%= gettext("Редактировать") %>
          </.regular_button>
          <.button class="p-4" phx-click="delete_organization">
            <.icon name="cen-bin" alt={dgettext("orgs", "Удалить")} />
          </.button>
        </div>

        <.basic_card
          class="w-full px-6 py-10 lg:py-12 lg:col-span-9"
          header={dgettext("orgs", "Описание")}
        >
          <p class="mt-6">
            <%= @organization.description %>
          </p>
        </.basic_card>

        <section class="space-y-6 lg:col-span-9">
          <.header header_level="h2" header_kind="black_left">
            <%= dgettext("orgs", "Вакансии") %>
          </.header>
          <%!-- TODO: Add vacancies list --%>
        </section>

        <div class="col-span-12">
          <.arrow_button arrow_direction="left" phx-click={JS.navigate(~p"/organizations")}>
            <%= dgettext("orgs", "Вернуться к организациям") %>
          </.arrow_button>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    case Employers.get_organization(id) do
      organization ->
        {:ok, assign(socket, organization: organization)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_organization", _params, socket) do
    Employers.delete_organization(socket.assigns.organization)
    {:noreply, push_navigate(socket, to: ~p"/organizations")}
  end

  defp contacts_list(organization) do
    [
      {organization.phone_number, "cen-phone"},
      {organization.email, "cen-message"},
      {organization.address, "cen-globe"}
    ]
  end

  defp image(organization) do
    Cen.ImageUploader.url({organization.image, organization})
  end
end
