# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule CenWeb.VKIDComponent do
  @moduledoc false
  use Phoenix.Component
  use CenWeb, :verified_routes

  alias Cen.Accounts.VKIDAuthProvider

  attr :state, :string
  attr :code, :string

  def one_tap(assigns) do
    ~H"""
    <div
      id="vkid-one-tap"
      phx-hook="VKIDOneTap"
      phx-update="ignore"
      data-state={@state}
      data-client-id={client_id()}
      data-code-verifier={@code}
      data-redirect-url={redirect_url()}
    >
    </div>
    """
  end

  defp client_id do
    VKIDAuthProvider.client_id()
  end

  defp redirect_url do
    url(~p"/users/auth/vkid")
  end
end
