defmodule Cen.PCKE.Storage do
  @moduledoc false
  use Nebulex.Cache,
    otp_app: :cen,
    adapter: Nebulex.Adapters.Local
end
