defmodule Director.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @impl true
  def start(_type, _args) do
    consumer_group_opts = []
    finished_consumer = Director.FinishedTaskConsumer
    topic_names = ["finished-tasks"]

    children = [
      {Director.Repo, []},
      supervisor(
        KafkaEx.ConsumerGroup,
        [finished_consumer, "finished-tasks-consumer-group", topic_names, consumer_group_opts]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Director.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
