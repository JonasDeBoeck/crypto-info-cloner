import Config

config :kafka_ex,
  brokers: [{"localhost", 9092}]

config :cloner_worker,
  n_workers: 4,
  default_rate: 2
