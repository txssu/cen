defmodule CenWeb.UserLive.ChooseRole do
  @moduledoc false
  use CenWeb, :live_view
  use Gettext, backend: CenWeb.Gettext

  import CenWeb.ExtraFormsComponents

  alias Cen.Accounts
  alias Cen.Accounts.User

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        {dgettext("users", "Выберите роль")}
      </.header>
      <div class="mt-[2.1875rem]">
        <.simple_form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.error :if={@check_errors}>
            {dgettext("forms", "Oops, something went wrong! Please check the errors below.")}
          </.error>

          <div class="mb-[2.8125rem]">
            <.radio
              legend={dgettext("users", "Роль")}
              field={@form[:role]}
              options={[
                {dgettext("users", "Соискатель"), "applicant"},
                {dgettext("users", "Работодатель"), "employer"}
              ]}
            />
          </div>

          <:actions>
            <.arrow_button class="mx-auto">
              {dgettext("users", "Подтвердить")}
            </.arrow_button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_role(%User{})

    socket =
      socket
      |> assign(check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_role(user, user_params) do
      {:ok, _user} ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_role(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
