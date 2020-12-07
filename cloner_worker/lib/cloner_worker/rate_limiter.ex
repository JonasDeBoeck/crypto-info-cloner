defmodule ClonerWorker.RateLimiter do
  use GenServer
  @me __MODULE__

  defstruct workers: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    {:ok, %@me{}}
  end

  def regster(worker) do
    GenServer.cast(@me, {:register_worker, worker})
  end

  def handle_cast({:register_worker, worker}, %@me{} = state) do
    new_workers = state.workers ++ [worker]
    {:noreply, %@me{workers: new_workers}}
  end
end
