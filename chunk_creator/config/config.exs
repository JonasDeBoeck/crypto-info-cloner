import Config

config :kafka_ex,
  brokers: [{"localhost", 9092}]

config :chunk_creator,
  max_window_size_in_sec: 1 * 1 * 60 * 60

config :chunk_creator,
  ecto_repos: [ChunkCreator.Repo]

config :chunk_creator, ChunkCreator.Repo,
  database: "assignment_crypto",
  username: "jonas",
  password: "t",
  hostname: "localhost"

config :database_interaction, repo: ChunkCreator.Repo