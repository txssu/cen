defmodule CenWeb.UserSettings.Components do
  @moduledoc false
  use CenWeb, :html

  @spec navigation(map()) :: Phoenix.LiveView.Rendered.t()
  def navigation(assigns) do
    ~H"""
    <ul>
      <li>
        <.link navigate={~p"/users/settings/personal"}>
          Personal info
        </.link>
      </li>

      <li>
        <.link navigate={~p"/users/settings/credentials"}>
          Edit credentials
        </.link>
      </li>
    </ul>
    """
  end
end
