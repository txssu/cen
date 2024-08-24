defmodule CenWeb.Plugs.PutSecureHeaders do
  @moduledoc false
  @behaviour Plug

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(conn, _opts) do
    Phoenix.Controller.put_secure_browser_headers(conn, %{
      "content-security-policy" => csp_string()
    })
  end

  defp csp_options do
    %{
      "default-src" => ["'self'"],
      "script-src-elem" => ["'self'"],
      "connect-src" => ["'self'", csp_s3()],
      "img-src" => ["'self'", "data:", "blob:", csp_s3()],
      "frame-src" => ["'self'"],
      "script-src-attr" => ["'unsafe-inline'"]
    }
  end

  defp csp_string do
    Enum.map_join(csp_options(), "; ", fn {key, values} -> "#{key} #{Enum.join(values, " ")}" end)
  end

  defp csp_s3 do
    Application.get_env(:cen, :csp)[:s3]
  end
end
