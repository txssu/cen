defmodule CenWeb.OrganizationLive.Form do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Employers
  alias Cen.Employers.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9 lg:col-start-2">
      <.simple_form for={@form} id="organization-form" phx-submit="save" phx-change="validate">
        <div class="space-y-9">
          <div class="lg:grid lg:grid-cols-9 lg:gap-x-10 lg:space-y-0">
            <div class="lg:col-span-4">
              <.fieldset legend={dgettext("orgs", "Организация")} subtitle={dgettext("orgs", "Общая информация")}>
                <.input field={@form[:name]} type="text" label={dgettext("orgs", "Название организации")} required />
                <.input field={@form[:inn]} type="text" label={dgettext("orgs", "ИНН")} required />
                <.input field={@form[:description]} type="textarea" label={dgettext("orgs", "Описание")} required maxlength="1000" />
              </.fieldset>
            </div>

            <div class="pt-28 lg:col-span-4 lg:col-start-6">
              <.basic_card class="relative bg-white pt-24">
                <.render_preview entries={@uploads.image.entries} />
                <div
                  id="croppr"
                  class="croppr-wrapper flex flex-col px-4 pb-4 lg:px-10"
                  phx-hook="Croppr"
                  phx-update="ignore"
                  data-upload-name="image"
                  data-upload-ref={List.first(@uploads.image.entries, %{ref: nil}).ref}
                  data-uploaded-image={image(@organization)}
                >
                  <div class="croppr-clickable-area text-center">
                    <p>
                      <.icon name="cen-upload" class="inline" />
                    </p>
                    <p class="mt-6">
                      {gettext("Нажмите, чтобы загрузить изображение или перетащите его")}
                    </p>
                    <p class="mt-4">
                      {gettext("JPG или PNG до 10МБ")}
                    </p>
                  </div>
                  <div class="order-last mt-4 flex justify-center gap-4">
                    <.regular_button type="button" class="croppr-delete-button hidden">
                      {gettext("Удалить")}
                    </.regular_button>
                  </div>
                </div>
              </.basic_card>
              <.live_file_input upload={@uploads.image} class="hidden" />
            </div>
          </div>

          <.fieldset legend={dgettext("orgs", "Контакты")}>
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input field={@form[:phone_number]} type="text" label={dgettext("orgs", "Номер телефона")} required />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input field={@form[:email]} type="email" label={dgettext("orgs", "Почта")} />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input field={@form[:address]} type="text" label={dgettext("orgs", "Адрес")} />
              </div>
            </div>
          </.fieldset>

          <.fieldset legend={dgettext("orgs", "Ссылки")}>
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input field={@form[:website_link]} type="text" label={dgettext("orgs", "Сайт организации")} />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input field={@form[:social_link]} type="text" label={dgettext("orgs", "Соцсеть")} />
              </div>
            </div>
          </.fieldset>
        </div>

        <:actions>
          <.arrow_button>
            {dgettext("forms", "Сохранить")}
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp render_preview(assigns) do
    assigns = assign(assigns, :entry, List.first(assigns.entries))

    ~H"""
    <%= if is_nil(@entry) do %>
      <div class="outline-[1rem] bg-accent absolute top-0 left-1/2 h-32 w-32 -translate-x-1/2 -translate-y-1/2 rounded-full outline outline-white lg:-translate-y-1/2">
      </div>
    <% else %>
      <.live_img_preview
        entry={@entry}
        class="outline-[1rem] absolute top-0 left-1/2 z-20 h-32 w-32 -translate-x-1/2 -translate-y-1/2 rounded-full outline outline-white lg:-translate-y-1/2"
      />
    <% end %>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    action = socket.assigns.live_action

    organization =
      case action do
        :create -> %Organization{}
        :update -> Employers.get_organization!(params["id"])
      end

    verify_has_permission!(socket.assigns.current_user, organization, action)

    {:ok,
     socket
     |> assign_form(organization)
     |> allow_upload(:image, accept: ~w(image/*), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_image", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:image, ref) |> assign(delete_image: true)}
  end

  def handle_event("delete_image", _params, socket) do
    {:noreply, assign(socket, delete_image: true)}
  end

  def handle_event("validate", %{"organization" => organization_params}, socket) do
    form =
      %Organization{}
      |> Employers.change_organization(organization_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    params = maybe_put_image(organization_params, socket)

    save_organization(socket, socket.assigns.live_action, params)
  end

  defp maybe_put_image(params, socket) do
    files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        path_with_extension = path <> String.replace(entry.client_type, "image/", ".")
        File.cp!(path, path_with_extension)
        {:ok, path_with_extension}
      end)

    delete_image? = socket.assigns[:delete_image]

    case files do
      [] when delete_image? -> Map.put(params, "image", nil)
      [] -> params
      [file_path] -> Map.put(params, "image", file_path)
    end
  end

  defp save_organization(socket, :create, organization_params) do
    current_user = socket.assigns.current_user

    case Employers.create_organization_for(current_user, organization_params) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/orgs/#{organization}")
         |> put_flash(:info, dgettext("orgs", "Организация успешно создана."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_organization(socket, :update, organization_params) do
    organization = socket.assigns.organization

    case Employers.update_organization(organization, organization_params) do
      {:ok, _organization} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/orgs/#{organization}")
         |> put_flash(:info, dgettext("orgs", "Организация успешно обновлена."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket, organization) do
    form = organization |> Employers.change_organization() |> to_form()
    assign(socket, organization: organization, form: form)
  end

  defp image(organization) do
    Cen.ImageUploader.url({organization.image, organization})
  end
end
