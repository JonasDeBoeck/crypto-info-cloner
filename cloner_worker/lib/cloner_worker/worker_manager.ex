defmodule ClonerWorker.WorkerManager do
  require Logger
  use GenServer
  @me __MODULE__
  defstruct workers: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    # Elke seconden nieuwe tasks assigen aan de available workers
    :timer.send_interval(1000, :assign_work)
    {:ok, %@me{}}
  end

  def handle_info(:assign_work, %@me{} = state) do
    # Pakt de index van de eerste beschikbare worker uit de lijst
    first_available_worker_index =
      Enum.find_index(state.workers, fn worker -> worker.available == true end)

    if first_available_worker_index != nil do
      # Get de worker en de eerste taak
      first_available_worker = Enum.at(state.workers, first_available_worker_index)
      task = ClonerWorker.Queue.get_first_element()

      if task != nil do
        # Stuur een cast naar de worker
        GenServer.cast(first_available_worker.pid, {:add_task, task})
        # Zet de worker op unavailable
        updated_workers =
          List.replace_at(state.workers, first_available_worker_index, %{
            pid: first_available_worker.pid,
            available: false
          })

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
    # Add de task aan de queue
    ClonerWorker.Queue.add_to_queue(task)
  end

  def add_worker(worker) do
    GenServer.cast(@me, {:add_worker, worker})
  end

  def handle_cast({:add_worker, worker}, %@me{} = state) do
    # Voeg een worker toe aan de workers
    new_workers = state.workers ++ [worker]
    {:noreply, %@me{workers: new_workers}}
  end

  def change_worker_status(worker_pid) do
    GenServer.cast(@me, {:change_worker_status, worker_pid})
  end

  def handle_cast({:change_worker_status, worker_pid}, %@me{} = state) do
    # Zet een worker die klaar is met zijn chunk terug op available
    worker_index = Enum.find_index(state.workers, fn worker -> worker.pid == worker_pid end)

    updated_workers =
      List.replace_at(state.workers, worker_index, %{pid: worker_pid, available: true})

    {:noreply, %@me{workers: updated_workers}}
  end
end
