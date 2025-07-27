defmodule CenWeb.PrivacyLive do
  @moduledoc false
  use CenWeb, :live_view

  defp admin_email(assigns) do
    ~H"""
    <a href="mailto:ton.ekb@ya.ru" target="_blank" class="text-accent">ton.ekb@ya.ru</a>
    """
  end

  defp site_link(assigns) do
    domain =
      ~p"/"
      |> url()
      |> String.trim_trailing("/")

    assigns = assign(assigns, domain: domain)

    ~H"""
    <.link navigate={~p"/"} class="text-accent">{@domain}</.link>
    """
  end

  defp privacy_link(assigns) do
    ~H"""
    <.link navigate={~p"/privacy"} class="text-accent">{url(~p"/privacy")}</.link>
    """
  end
end
