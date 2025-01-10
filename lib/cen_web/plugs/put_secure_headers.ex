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
    self = %{
      "default-src" => ["'self'"],
      "script-src-elem" => ["'self'"],
      "connect-src" => ["'self'", csp_s3()],
      "img-src" => ["'self'", "data:", "blob:", csp_s3()],
      "frame-src" => ["'self'"],
      "style-src-elem" => ["'self'"],
      "script-src-attr" => ["'unsafe-inline'"]
    }

    Map.merge(self, vkid_options(), fn _key, l1, l2 -> l2 ++ l1 end)
  end

  defp vkid_options do
    %{
      "script-src-elem" => ["https://unpkg.com"],
      "connect-src" => ["https://id.vk.com"],
      "style-src-elem" => ["'unsafe-inline'"],
      "frame-src" => ["https://id.vk.com https://login.vk.com"]
    }
  end

  defp csp_string do
    Enum.map_join(csp_options(), "; ", fn {key, values} -> "#{key} #{Enum.join(values, " ")}" end)
  end

  defp csp_s3 do
    Application.get_env(:cen, :csp)[:s3]
  end
end
