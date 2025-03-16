defmodule CenWeb.ChatHook do
  @moduledoc false

  import Phoenix.LiveView

  alias Cen.Communications.Message
  alias CenWeb.ChatComponent
  alias Phoenix.LiveView.Socket

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) and current_user != nil do
      Phoenix.PubSub.subscribe(Cen.PubSub, to_string(current_user.id))
    end

    socket = attach_hook(socket, :chat, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  @spec handle_info({:new_message, Message.t()}, Socket.t()) :: {:cont, Socket.t()}
  def handle_info({:new_message, message}, socket) do
    send_update(ChatComponent, id: "chat", new_message: message)

    {:halt, socket}
  end

  def handle_info(_message, socket) do
    {:cont, socket}
  end
end
