defmodule ClonerWorker.WorkerManager do
  use GenServer
  @me __MODULE__
  defstruct workers: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    {:ok, %@me{}}
  end

  def add_task(task) do
    ClonerWorker.Queue.add_to_queue(task)
  end

  def add_worker(worker) do
    GenServer.cast(@me, {:add_worker, worker})
  end

  def handle_cast({:add_worker, worker}, %@me{} = state) do
    new_workers = state.workers ++ [worker]
    {:noreply, %@me{workers: new_workers}}
  end

  def start_workers() do
    amount_of_workers = Application.get_env(:cloner_worker, :n_workers)
    Enum.each(1..amount_of_workers, fn worker ->
      childspec = {ClonerWorker.Worker, [name: worker |> Integer.to_string |> String.to_atom]}
      DynamicSupervisor.start_child(WorkerDynamicSupervisor, childspec)
    end)
    for {_, pid, _, _} <- DynamicSupervisor.which_children(WorkerDynamicSupervisor) do
      ClonerWorker.WorkerManager.add_worker(%{pid: pid, available: true})
    end
  end
end
