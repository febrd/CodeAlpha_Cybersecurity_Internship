defmodule SecureApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SecureAppWeb.Telemetry,
      SecureApp.Repo,
      {DNSCluster, query: Application.get_env(:secure_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SecureApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SecureApp.Finch},
      # Start a worker by calling: SecureApp.Worker.start_link(arg)
      # {SecureApp.Worker, arg},
      # Start to serve requests, typically the last entry
      SecureAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SecureApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SecureAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
