defmodule ClonerWorker.Worker do
  use GenServer
  @me __MODULE__

  def start_link(name: n) do
    GenServer.start_link(@me, n, name: n)
  end

  def init(name) do
    {:ok, %{}}
  end
end
