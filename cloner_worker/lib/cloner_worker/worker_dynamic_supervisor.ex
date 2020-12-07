defmodule ClonerWorker.WorkerDynamicSupervisor do
  use DynamicSupervisor

  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_workers() do
    amount_of_workers = Application.get_env(:cloner_worker, :n_workers)
    Enum.each(1..amount_of_workers, fn worker ->
      childspec = {ClonerWorker.Worker, [name: worker |> Integer.to_string |> String.to_atom]}
      DynamicSupervisor.start_child(ClonerWorker.WorkerDynamicSupervisor, childspec)
    end)
    for {_, pid, _, _} <- DynamicSupervisor.which_children(ClonerWorker.WorkerDynamicSupervisor) do
      ClonerWorker.WorkerManager.add_worker(%{pid: pid, available: true})
    end
  end
end
