# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule CenWeb.VKIDComponent do
  @moduledoc false
  use Phoenix.Component
  use CenWeb, :verified_routes

  alias Cen.Accounts.VKIDAuthProvider
  alias Phoenix.LiveView.ColocatedHook

  attr :state, :string
  attr :code, :string

  def one_tap(assigns) do
    ~H"""
    <div
      id="vkid-one-tap"
      phx-hook=".VKIDOneTap"
      phx-update="ignore"
      data-state={@state}
      data-client-id={client_id()}
      data-code-verifier={@code}
      data-redirect-url={redirect_url()}
    >
    </div>
    <script :type={ColocatedHook} name=".VKIDOneTap">
      export default {
        mounted() {
          const VKID = window.VKIDSDK;
          VKID.Config.init({
            app: this.el.dataset.clientId,
            redirectUrl: this.el.dataset.redirectUrl,
            responseMode: VKID.ConfigResponseMode.Redirect,
            scope: "vkid.personal_info email phone",
            codeVerifier: this.el.dataset.codeVerifier,
            state: this.el.dataset.state
          });

          const oneTap = new VKID.OneTap();

          oneTap.render({
            container: this.el,
            showAlternativeLogin: true,
            // Fast auth ain't work cause of CORS problem (maybe)
            // So I decided to disable loading
            fastAuthEnabled: true,
            styles: {
              borderRadius: 23,
              height: 46
            }
          })
        }
      }
    </script>
    """
  end

  defp client_id do
    VKIDAuthProvider.client_id()
  end

  defp redirect_url do
    url(~p"/users/auth/vkid")
  end
end
