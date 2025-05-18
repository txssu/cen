defmodule CenWeb.CookiesConsentComponent do
  @moduledoc false
  use CenWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="cookies-consent-form" class="absolute top-4 right-4" phx-hook="CookiesConsent">
      <div class="shadow-default-1 w-[300px] rounded-lg bg-white p-5">
        <p>
          Мы используем <.link navigate={~p"/privacy"}>куки</.link> — без них ТОН: Вакансии просто не сможет нормально работать
        </p>
        <div class="mt-4">
          <.regular_button id="accept-cookies-consent">Понятно</.regular_button>
        </div>
      </div>
    </div>
    """
  end
end
