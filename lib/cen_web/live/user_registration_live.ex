defmodule CenWeb.UserRegistrationLive do
  @moduledoc false
  use CenWeb, :live_view
  use Gettext, backend: CenWeb.Gettext

  import CenWeb.ExtraFormsComponents

  alias Cen.Accounts
  alias Cen.Accounts.User
  alias Cen.PCKE

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        {dgettext("users", "Регистрация")}
      </.header>
      <div class="mt-[2.1875rem]">
        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
        >
          <input :if={@vk_id} name={@form[:vk_id].name} type="hidden" value={@vk_id} />
          <input :if={@vk_id} name={@form[:vk_access_token].name} type="hidden" value={@form[:vk_access_token].value} />

          <div class="mb-[2.8125rem]">
            <.radio
              legend={dgettext("users", "Роль")}
              field={@form[:role]}
              options={[
                {"Соискатель", "applicant"},
                {"Работодатель", "employer"}
              ]}
            />
          </div>

          <.input field={@form[:fullname]} type="text" placeholder={dgettext("users", "ФИО")} implicit_required />

          <.input
            :if={@form[:role].value == "applicant" or @form[:role].value == :applicant}
            field={@form[:birthdate]}
            type="date"
            title="Дата рождения"
            implicit_required
          />

          <input :if={@form[:role].value not in ["applicant", :applicant]} type="hidden" name={@form[:birthdate].name} value={@form[:birthdate].value} />

          <.input field={@form[:email]} type="email" placeholder={dgettext("users", "Почта")} implicit_required />
          <.input field={@form[:phone_number]} type="text" placeholder={dgettext("users", "Номер телефона")} implicit_required />
          <.input :if={is_nil(@vk_id)} field={@form[:password]} type="password" placeholder={dgettext("users", "Пароль")} implicit_required />

          <div :if={is_nil(@vk_id)} class="mt-6">
            <.input field={@form[:privacy_consent]} type="checkbox">
              <:label_block>
                <span>Даю согласие на <.link navigate={~p"/privacy"} class="text-accent">обработку персональных данных</.link></span>
              </:label_block>
            </.input>
          </div>

          <:actions>
            <.arrow_button class="mx-auto">
              {dgettext("users", "Зарегистрироваться")}
            </.arrow_button>
          </:actions>
        </.simple_form>

        <%= if is_nil(@vk_id) do %>
          <div class="mt-4">
            <p class="text-center text-lg uppercase">{gettext("или")}</p>
          </div>

          <div class="max-w-60 mx-auto mt-4">
            <CenWeb.VKIDComponent.one_tap code={@vkid_code} state={@vkid_state} />
          </div>
        <% end %>

        <div class="mt-[1.125rem] space-y-2.5 text-center">
          <p>
            {dgettext("users", "Уже есть аккаунт?")}
            <.regular_link navigate={~p"/users/log_in"} text={dgettext("users", "Войти")} />
          </p>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {changeset, vk_id} = get_state(params)

    socket =
      socket
      |> assign(trigger_submit: false, vk_id: vk_id)
      |> assign_form(changeset)
      |> assign_vkid_data()

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      if is_nil(socket.assigns.vk_id) do
        Accounts.change_user_registration(%User{}, user_params)
      else
        Accounts.change_vk_user_creation(%User{}, ignore_unused(user_params))
      end

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    if is_nil(socket.assigns.vk_id) do
      register_user(user_params, socket)
    else
      create_vk_user(user_params, socket)
    end
  end

  defp get_state(params) do
    with {:ok, encrypted_vk_id} <- Map.fetch(params, "vk_id"),
         {:ok, vk_id} <- decrypt_vk_id(encrypted_vk_id) do
      {Accounts.get_invalid_params(vk_id), encrypted_vk_id}
    else
      _any_error -> {Accounts.change_user_registration(%User{}), nil}
    end
  end

  defp register_user(user_params, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _email_delivery} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        {:noreply, assign(socket, trigger_submit: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp create_vk_user(user_params, socket) do
    params =
      user_params
      |> ignore_unused()
      |> decrypt_params()

    case Accounts.create_vk_user(params) do
      {:ok, _user} ->
        {:noreply, assign(socket, trigger_submit: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    assign(socket, form: form)
  end

  defp assign_vkid_data(socket) do
    {state, code} = PCKE.start_challenge()
    assign(socket, vkid_state: state, vkid_code: code)
  end

  defp ignore_unused(params) do
    Map.reject(params, fn {k, _v} -> String.starts_with?(k, "_unused_") end)
  end

  defp decrypt_params(params) do
    with %{"vk_id" => vk_id} <- params,
         {:ok, vk_id} <- decrypt_vk_id(vk_id) do
      Map.put(params, "vk_id", vk_id)
    else
      _any_error -> params
    end
  end

  defp decrypt_vk_id(encrypted_vk_id) do
    Phoenix.Token.decrypt(CenWeb.Endpoint, "user vk id", encrypted_vk_id)
  end
end
