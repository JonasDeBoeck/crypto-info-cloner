defmodule ClonerWorker.WorkerManager do
  require Logger
  use GenServer
  @me __MODULE__
  defstruct workers: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    :timer.send_interval(1000, :assign_work)
    {:ok, %@me{}}
  end

  def handle_info(:assign_work, %@me{} = state) do
    first_available_worker_index = Enum.find_index(state.workers, fn worker -> worker.available == true end)
    if (first_available_worker_index != nil) do
      first_available_worker = Enum.at(state.workers, first_available_worker_index)
      task = ClonerWorker.Queue.get_first_element
      if (task != nil) do
        GenServer.cast(first_available_worker.pid, {:add_task, task})
        updated_workers = List.replace_at(state.workers, first_available_worker_index, %{pid: first_available_worker.pid, available: false})
        {:noreply, %@me{workers: updated_workers}}
      else
        Logger.info("There are no tasks in the queue at the moment")
        {:noreply, %@me{workers: state.workers}}
      end
    else
      Logger.info("There are no available workers at this moment")
      {:noreply, %@me{workers: state.workers}}
    end
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

  def change_worker_status(worker_pid) do
      GenServer.cast(@me, {:change_worker_status, worker_pid})
  end

  def handle_cast({:change_worker_status, worker_pid}, %@me{} = state) do
    worker_index = Enum.find_index(state.workers, fn worker -> worker.pid == worker_pid end)
    updated_workers = List.replace_at(state.workers, worker_index, %{pid: worker_pid, available: true})
    {:noreply, %@me{workers: updated_workers}}
  end
end
