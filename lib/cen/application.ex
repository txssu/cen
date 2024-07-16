defmodule Cen.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      CenWeb.Telemetry,
      Cen.Repo,
      {DNSCluster, query: Application.get_env(:cen, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cen.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Cen.Finch},
      # Start a worker by calling: Cen.Worker.start_link(arg)
      # {Cen.Worker, arg},
      # Start to serve requests, typically the last entry
      CenWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    CenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
