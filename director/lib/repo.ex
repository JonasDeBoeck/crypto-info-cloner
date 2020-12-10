defmodule Director.Repo do
  use Ecto.Repo,
    otp_app: :director,
    adapter: Ecto.Adapters.MyXQL
end
