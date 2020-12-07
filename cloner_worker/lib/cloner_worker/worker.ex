defmodule ClonerWorker.Worker do
  use Tesla
  use GenServer
  @me __MODULE__
  @url "https://poloniex.com/public?command=returnTradeHistory&currencyPair="
  defstruct tasks: []
  def start_link(name: n) do
    GenServer.start_link(@me, n, name: n)
  end

  def init(_name) do
    {:ok, %@me{}}
  end

  def handle_cast({:add_task, task}, state) do
    new_tasks = state.tasks ++ [task]
    request_url = "#{@url}#{task.currency_pair}&start=#{task.from_unix_ts}&end=#{task.until_unix_ts}"
    {:ok, res} = Tesla.get(request_url, [])
    result = Jason.decode!(res.body)
    IO.inspect(result)
    {:noreply, %@me{tasks: new_tasks}}
  end
end
