defmodule Cen.Accounts.VKIDAuthProvider do
  @moduledoc false

  require Logger

  @spec auth(map(), String.t()) :: {:ok, integer(), String.t()} | :error
  def auth(params, redirect_uri) do
    state = params["state"]
    code = Cen.PCKE.get_code(state)

    data =
      %{
        "grant_type" => "authorization_code",
        "redirect_uri" => redirect_uri,
        "client_id" => client_id(),
        "code" => params["code"],
        "device_id" => params["device_id"],
        "code_verifier" => code,
        "state" => state
      }

    with {:ok, %{status: 200, body: body}} <- post("https://id.vk.com/oauth2/auth", data),
         {:ok, %{"user_id" => user_id, "access_token" => access_token}} <- Jason.decode(body) do
      {:ok, user_id, access_token}
    else
      _error -> :error
    end
  end

  @spec get_info(String.t()) :: {:ok, map()} | :error
  def get_info(access_token) do
    data =
      %{
        "access_token" => access_token,
        "client_id" => client_id()
      }

    with {:ok, %{status: 200, body: body}} <- post("https://id.vk.com/oauth2/user_info", data),
         {:ok, %{"user" => user_data}} <- Jason.decode(body) do
      {:ok, user_data}
    else
      _error -> :error
    end
  end

  defp post(url, data) do
    :post
    |> Finch.build(url, [{"Content-Type", "application/x-www-form-urlencoded"}], URI.encode_query(data))
    |> Finch.request(Cen.Finch)
  end

  @spec client_id() :: String.t()
  def client_id do
    :cen
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:client_id)
  end
end
