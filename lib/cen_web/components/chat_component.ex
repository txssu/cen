defmodule CenWeb.ChatComponent do
  @moduledoc false
  use CenWeb, :live_component

  alias Cen.Communications
  alias Cen.Communications.Message
  alias Phoenix.PubSub

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@current_user} id="chat_modal" phx-remove={hide_modal("chat_modal")} data-cancel={JS.exec("phx-remove")} class="relative z-50 hidden">
        <div id="chat_modal-bg" class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
        <div
          class="fixed inset-0 overflow-y-auto"
          aria-labelledby="chat_modal-title"
          aria-describedby="chat_modal-description"
          role="dialog"
          aria-modal="true"
          tabindex="0"
        >
          <div class="flex min-h-full items-center justify-center">
            <div class="h-dvh w-full max-w-6xl lg:h-[900px] lg:px-4 lg:py-8">
              <.focus_wrap
                id="chat_modal-container"
                phx-window-keydown={JS.exec("data-cancel", to: "#chat_modal")}
                phx-key="escape"
                phx-click-away={JS.exec("data-cancel", to: "#chat_modal")}
                class="lg:shadow-zinc-700/10 lg:ring-zinc-700/10 relative h-full hidden lg:rounded-2xl bg-white lg:shadow-lg lg:ring-1 transition"
              >
                <div class={["absolute top-6 right-5 lg:block", @selected_interaction && "hidden"]}>
                  <button
                    phx-click={JS.exec("data-cancel", to: "#chat_modal")}
                    type="button"
                    class="-m-3 flex-none p-3 hover:opacity-50"
                    aria-label={gettext("close")}
                  >
                    <.icon name="cen-cross" class="h-5 w-5" />
                  </button>
                </div>
                <div id="chat_modal-content" class="h-full">
                  <div class="flex h-full">
                    <div class={["bg-[#F5F5F5] h-full w-full p-7 lg:w-[430px] lg:block", @selected_interaction && "hidden"]}>
                      <.header header_kind="black_left" class="mb-10">
                        <%= dgettext("publications", "Чаты") %>
                      </.header>
                      <ul class="space-y-4 ">
                        <li :for={interaction <- @interactions} phx-click="select_chat" phx-value-id={interaction.id} phx-target={@myself}>
                          <.chat_card interaction={interaction} />
                        </li>
                      </ul>
                    </div>
                    <div class="grow">
                      <%= if @selected_interaction do %>
                        <div class="flex h-full flex-col p-7 lg:p-14 lg:pb-7 lg:pl-7">
                          <.chat_header interaction={@selected_interaction} myself={@myself} />
                          <ul class="my-1 flex grow flex-col-reverse gap-2.5 overflow-y-auto rounded-lg pb-7 [scrollbar-width:_none]">
                            <li :for={message <- @messages}>
                              <.message_card message={message} current_user={@current_user} />
                            </li>
                          </ul>
                          <div>
                            <.message_form interaction={@selected_interaction} current_user={@current_user} message_form={@message_form} myself={@myself} />
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </.focus_wrap>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp chat_card(assigns) do
    last_message = List.first(assigns.interaction.messages)

    assigns =
      assign(assigns,
        title: get_title(assigns.interaction),
        subtitle: get_subtitle(assigns.interaction),
        last_message_text: last_message && last_message.text
      )

    ~H"""
    <div class="shadow-default-1 cursor-pointer rounded-lg bg-white p-5">
      <div class="text-title-text font-medium uppercase">
        <%= @title %>
      </div>
      <div class="text-title-text mt-2 text-sm">
        <%= @subtitle %>
      </div>
      <div class="mt-4 flex gap-2.5">
        <.initiator_text interaction={assigns.interaction} />
        <%= if @last_message_text do %>
          <div>|</div>
          <div class="text-nowrap overflow-hidden text-ellipsis">
            <%= @last_message_text %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp chat_header(assigns) do
    to_user = get_to_resource(assigns.interaction).user

    assigns =
      assign(assigns,
        to_user: to_user
      )

    ~H"""
    <div class="bg-[#F5F5F5] shadow-default-convexity rounded-lg px-4 py-5">
      <div class="flex gap-4">
        <div class="flex items-center justify-center">
          <div class="lg:hidden">
            <.button class="w-11 h-11" phx-click="deselect_chat" phx-target={@myself}>
              <div class="flex h-full w-full items-center justify-center">
                <.icon name="cen-arrow-back" class="w-6 h-6" />
              </div>
            </.button>
          </div>
        </div>

        <div>
          <div class="text-title-text font-medium uppercase">
            <%= @to_user.fullname %>
          </div>

          <div class="mt-5 space-y-1">
            <p><span class="text-accent"><%= dgettext("publications", "Вакансия") %></span>: <%= @interaction.vacancy.job_title %></p>
            <p><span class="text-accent"><%= dgettext("publications", "Резюме") %></span>: <%= @interaction.resume.job_title %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp message_card(assigns) do
    ~H"""
    <div class={["bg-[#F5F5F5] max-w-80 rounded-lg p-5", @current_user.id == @message.user_id && "bg-accent-hover ml-auto"]}>
      <p class="break-words"><%= @message.text %></p>
      <div class="mt-2.5 text-right"><%= Calendar.strftime(@message.inserted_at, "%H:%M") %></div>
    </div>
    """
  end

  defp message_form(assigns) do
    ~H"""
    <div class="shadow-default-1 min-h-14 relative w-full rounded-lg">
      <.simple_form for={@message_form} phx-change="change" phx-submit="save" phx-target={@myself}>
        <button type="submit" class="absolute right-0 h-14 w-14" alt={dgettext("publications", "Отправить")}>
          <div class="flex justify-center">
            <.icon name="cen-send" />
          </div>
        </button>
        <.message_input field={@message_form[:text]} />
      </.simple_form>
    </div>
    """
  end

  defp message_input(assigns) do
    ~H"""
    <input
      class="min-h-14 text-wrap w-full resize-none rounded-lg border-0 pr-14"
      type="text"
      name={@field.name}
      id={@field.id}
      placeholder={dgettext("publications", "Сообщение")}
      required
    />
    """
  end

  defp get_title(interaction) do
    interaction
    |> get_to_resource()
    |> Map.fetch!(:job_title)
  end

  defp get_subtitle(interaction) do
    interaction
    |> get_to_resource()
    |> Map.fetch!(:user)
    |> Map.fetch!(:fullname)
  end

  defp initiator_text(assigns) do
    ~H"""
    <%= case @interaction.initiator do %>
      <% :vacancy -> %>
        <.icon name="cen-invite" />
        <p class="text-accent uppercase"><%= dgettext("publications", "Приглашение") %></p>
      <% :resume -> %>
        <.icon name="cen-application" />
        <p class="text-accent uppercase"><%= dgettext("publications", "Отклик") %></p>
    <% end %>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{current_user: current_user}, socket) do
    if current_user do
      interactions = Communications.list_interactions_for(current_user)

      {:ok,
       assign(socket,
         current_user: current_user,
         interactions: interactions,
         selected_interaction: nil
       )}
    else
      {:ok, assign(socket, current_user: nil)}
    end
  end

  def update(%{new_message: new_message}, socket) do
    selected_interaction = socket.assigns.selected_interaction

    if not is_nil(selected_interaction) and selected_interaction.id == new_message.interaction_id do
      interactions = add_new_message(socket.assigns.interactions, new_message)

      {:ok, assign(socket, interactions: interactions, messages: [new_message | socket.assigns.messages])}
    else
      {:ok, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("select_chat", %{"id" => id}, socket) do
    interaction = Enum.find(socket.assigns.interactions, &(to_string(&1.id) == id))
    {messages, _metadata} = Communications.list_messages(interaction.id, 0)
    {:noreply, socket |> assign(selected_interaction: interaction, messages: messages) |> assign_message_form()}
  end

  def handle_event("deselect_chat", _params, socket) do
    {:noreply, assign(socket, selected_interaction: nil, messages: [])}
  end

  def handle_event("change", %{"message" => message_params}, socket) do
    {:noreply, assign_message_form(socket, message_params)}
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    interaction = socket.assigns.selected_interaction
    user = socket.assigns.current_user

    {:ok, message} = Communications.send_message(interaction.id, user.id, message_params)

    to_user = get_second_user(user, interaction)

    PubSub.broadcast(Cen.PubSub, to_string(to_user.id), {:new_message, message})

    interactions = add_new_message(socket.assigns.interactions, message)
    messages = [message | socket.assigns.messages]

    {:noreply, socket |> assign(interactions: interactions, messages: messages) |> assign_message_form()}
  end

  defp assign_message_form(socket, attrs \\ %{}) do
    form =
      %Message{}
      |> Communications.change_message(attrs)
      |> to_form()

    assign(socket, message_form: form)
  end

  defp get_to_type(interaction) do
    case interaction.initiator do
      :resume -> :vacancy
      :vacancy -> :resume
    end
  end

  defp get_to_resource(interaction) do
    Map.fetch!(interaction, get_to_type(interaction))
  end

  defp get_second_user(current_user, interaction) do
    resource =
      case current_user.role do
        :applicant -> :vacancy
        :employer -> :resume
      end

    interaction
    |> Map.fetch!(resource)
    |> Map.fetch!(:user)
  end

  defp add_new_message(interactions, new_message) do
    {[interaction], others} =
      Enum.split_with(interactions, fn interaction ->
        interaction.id == new_message.interaction_id
      end)

    updated_interaction = %{interaction | messages: [new_message | interaction.messages]}

    [updated_interaction | others]
  end
end
