defmodule CenWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use CenWeb, :html

  @spec render(String.t(), map()) :: Phoenix.LiveView.Rendered.t()
  def render(_template, assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
      </head>
      <body class="bg-background flex h-screen flex-col justify-between">
        <div class="h-dvh flex items-center justify-center">
          <main class="text-center">
            <p class="text-xl">
              Ой! Произошла ошибочка...
            </p>
            <p class="text-accent text-[12rem]">
              {@status}
            </p>
            <p></p>
            <p class="text-xl">
              {status_code_message(@status)}
            </p>
          </main>
        </div>
      </body>
    </html>
    """
  end

  defp status_code_message(404), do: dgettext("errors", "Запрашиваемый ресурс не найден")
  defp status_code_message(_status), do: dgettext("errors", "Ошибка сервера")
end
