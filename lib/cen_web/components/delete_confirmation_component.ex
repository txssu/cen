defmodule CenWeb.DeleteConfirmationComponent do
  @moduledoc """
  Universal delete confirmation modal component.

  ## Usage

      <.delete_confirmation
        show={@show_delete_modal}
        title="Подтвердите удаление резюме"
        message="Это действие нельзя отменить. Резюме будет безвозвратно удалено."
        confirm_event="delete_resume"
        cancel_event="cancel_delete"
      />
  """
  use CenWeb, :html
  use Phoenix.Component

  @doc """
  Delete confirmation modal component.

  ## Attributes

    * `show` (required) - Boolean to control modal visibility
    * `title` (required) - Modal title text
    * `message` (required) - Confirmation message text
    * `confirm_event` (required) - Event name for confirm action
    * `cancel_event` (required) - Event name for cancel action
    * `confirm_text` - Confirm button text (defaults to "Да, удалить")
    * `cancel_text` - Cancel button text (defaults to "Отмена")
  """
  attr :show, :boolean, required: true
  attr :title, :string, required: true
  attr :message, :string, required: true
  attr :confirm_event, :string, required: true
  attr :cancel_event, :string, required: true
  attr :confirm_text, :string, default: "Да, удалить"
  attr :cancel_text, :string, default: "Отмена"

  def delete_confirmation(assigns) do
    ~H"""
    <.modal :if={@show} show id="delete_confirmation_modal" on_cancel={JS.push(@cancel_event)}>
      <div class="text-center">
        <.icon name="cen-trash-xmark" class="mx-auto mb-4 h-12 w-12 text-red-500" />
        <h3 class="mb-4 text-lg font-medium text-gray-900">
          {@title}
        </h3>
        <p class="mb-6 text-sm text-gray-500">
          {@message}
        </p>
        <div class="flex justify-center gap-3">
          <.button class="rounded bg-gray-300 px-4 py-2 text-gray-800 hover:bg-gray-400" phx-click={@cancel_event}>
            {@cancel_text}
          </.button>
          <.button class="rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700" phx-click={@confirm_event}>
            {@confirm_text}
          </.button>
        </div>
      </div>
    </.modal>
    """
  end
end
