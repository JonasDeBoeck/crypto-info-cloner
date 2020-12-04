import Config

config :kafka_ex,
  brokers: [{"localhost", 9092}]

config :director,
  ecto_repos: [Director.Repo]

config :director, Director.Repo,
  database: "assignment_crypto",
  username: "jonas",
  password: "t",
  hostname: "localhost"

config :database_interaction, repo: Director.Repo

config :director,
  pairs_to_clone: ["BTC_ETH", "USDT_BTC", "USDC_BTC"],
  from: 1_590_969_600,
  until: 1_591_500_000