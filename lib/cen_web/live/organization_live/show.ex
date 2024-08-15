defmodule CenWeb.OrganizationLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Employers

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 lg:col-span-12">
      <div class="space-y-6 lg:grid lg:grid-flow-dense lg:grid-cols-12 lg:gap-10 lg:space-y-0">
        <.header class="lg:col-span-12" header_kind="black_left">
          <%= @organization.name %>
        </.header>

        <.basic_card
          class="lg:order-1 lg:col-span-3 lg:col-start-10 w-full px-6 py-14"
          header={dgettext("orgs", "Контакты")}
        >
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

        <div class="flex gap-2.5 lg:col-span-12">
          <.regular_button class="bg-accent-hover">Редактировать</.regular_button>
          <.button class="p-4"><.icon name="cen-bin" /></.button>
        </div>

        <.basic_card class="w-full px-6 py-14 lg:col-span-9" header={dgettext("orgs", "Описание")}>
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
          <.arrow_button arrow_direction="left">
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

  defp contacts_list(organization) do
    [
      {organization.phone_number, "cen-phone"},
      {organization.email, "cen-message"},
      {organization.address, "cen-globe"}
    ]
  end
end
