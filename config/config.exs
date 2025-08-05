# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cen, Cen.Accounts.InvalidParamsStorage,
  gc_interval: to_timeout(minute: 10),
  max_size: 1_000,
  allocated_memory: 1_000_000,
  gc_cleanup_min_timeout: to_timeout(second: 10),
  gc_cleanup_max_timeout: to_timeout(minute: 5)

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :cen, Cen.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :cen, CenWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CenWeb.ErrorHTML, json: CenWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Cen.PubSub,
  live_view: [signing_salt: "E9Av9SG/"]

config :cen, CenWeb.PCKE.Storage,
  gc_interval: to_timeout(hour: 1),
  max_size: 1_000_000,
  allocated_memory: 200_000_000,
  gc_cleanup_min_timeout: to_timeout(second: 10),
  gc_cleanup_max_timeout: to_timeout(minute: 10)

config :cen, :email_from, "cen@example.com"

config :cen,
  ecto_repos: [Cen.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  cen: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :gettext, :default_locale, "ru"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  cen: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
