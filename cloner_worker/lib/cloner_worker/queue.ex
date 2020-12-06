defmodule ClonerWorker.Queue do
  use GenServer
  @me __MODULE__
  defstruct tasks: []

  def start_link(args \\ []) do
    GenServer.start_link(@me, args, name: @me)
  end

  def init(_args) do
    {:ok, %@me{}}
  end

  def add_to_queue(task) do
    GenServer.cast(@me, {:add_to_queue, task})
  end

  def handle_cast({:add_to_queue, task}, %@me{} = state) do
    new_queue = state.tasks ++ [task]
    {:noreply, %@me{tasks: new_queue}}
  end
end
