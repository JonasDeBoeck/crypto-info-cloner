defmodule ClonerWorker.RateLimiter do
  use GenServer
  @me __MODULE__

  defstruct rate: Application.fetch_env!(:cloner_worker, :default_rate), workers: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    :timer.send_interval(1000, :make_work)
    {:ok, %@me{}}
  end

  def handle_info(:make_work, %@me{} = state) do
    Enum.each(1..state.rate, fn x ->
      worker = Enum.at(state.workers, x - 1)
      if (worker != nil) do
        ClonerWorker.Worker.work(worker)
      end
    end)
    new_workers = Enum.drop(state.workers, state.rate)
    {:noreply, %@me{rate: state.rate, workers: new_workers}}
  end

  def regster(worker) do
    GenServer.cast(@me, {:register_worker, worker})
  end

  def handle_cast({:register_worker, worker}, %@me{} = state) do
    new_workers = state.workers ++ [worker]
    {:noreply, %@me{rate: state.rate, workers: new_workers}}
  end

  def set_rate(rate) do
      GenServer.cast(@me, {:set_rate, rate})
  end

  def handle_cast({:set_rate, rate}, %@me{} = state) do
    {:noreply, %@me{rate: rate, workers: state.workers}}
  end
end
