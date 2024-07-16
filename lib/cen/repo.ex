defmodule Cen.Repo do
  use Ecto.Repo,
    otp_app: :cen,
    adapter: Ecto.Adapters.Postgres
end
