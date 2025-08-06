defmodule CenWeb.CookiesConsentComponent do
  @moduledoc false
  use CenWeb, :live_component

  alias Phoenix.LiveView.ColocatedHook

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div id="cookies-consent-form" class="absolute top-4 right-4" phx-hook=".CookiesConsent">
        <div class="shadow-default-1 w-[300px] rounded-lg bg-white p-5">
          <p>
            Мы используем <.link navigate={~p"/privacy"}>куки</.link> — без них ТОН: Вакансии просто не сможет нормально работать
          </p>
          <div class="mt-4">
            <.regular_button id="accept-cookies-consent">Понятно</.regular_button>
          </div>
        </div>
      </div>
      <script :type={ColocatedHook} name=".CookiesConsent">
        export default {
          mounted() {
            this.el
              .querySelector("#accept-cookies-consent")
              .addEventListener("click", () => {
                document.cookie =
                  "cookies_consent=accepted; max-age=31536000; path=/; SameSite=Lax";
                this.el.remove();
              });
          },
        };
      </script>
    </div>
    """
  end
end
