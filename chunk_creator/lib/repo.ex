defmodule ChunkCreator.Repo do
  use Ecto.Repo,
    otp_app: :chunk_creator,
    adapter: Ecto.Adapters.MyXQL
end
