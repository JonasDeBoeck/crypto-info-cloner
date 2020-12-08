defmodule ClonerWorker.Worker do
  use Tesla
  use GenServer
  alias KafkaEx.Protocol.Produce.Request
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
    ClonerWorker.RateLimiter.regster(self())
    {:noreply, %@me{tasks: new_tasks}}
  end

  def work(pid) do
    GenServer.cast(pid, :work)
  end

  def handle_cast(:work, state) do
    task = Enum.at(state.tasks, 0)
    request_url = "#{@url}#{task.currency_pair}&start=#{task.from_unix_ts}&end=#{task.until_unix_ts}"
    {:ok, res} = Tesla.get(request_url, [])
    result = Jason.decode!(res.body)
    entries = Enum.map(result, &create_cloned_entry/1)
    if (length(result) > 1000) do
      cloned_chunk = %AssignmentMessages.ClonedChunk{chunk_result: :WINDOW_TOO_BIG, original_todo_chunk: task, entries: entries, possible_error_message: "More than 1000 elements"}
      encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
      send_kafka_request(encoded_cloned_chunk)
    else
      cloned_chunk = %AssignmentMessages.ClonedChunk{chunk_result: :COMPLETE, original_todo_chunk: task, entries: entries, possible_error_message: ""}
      encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
      send_kafka_request(encoded_cloned_chunk)
    end
    new_tasks = Enum.drop(state.tasks, 1)
    ClonerWorker.WorkerManager.change_worker_status(self())
    {:noreply, %@me{tasks: new_tasks}}
  end

  defp send_kafka_request(encoded_cloned_chunk) do
    message = %KafkaEx.Protocol.Produce.Message{value: encoded_cloned_chunk}
    request = %{%Request{topic: "finished-chunks", required_acks: 1} | messages: [message]}
    KafkaEx.produce(request)
  end

  defp create_cloned_entry(result) do
    %AssignmentMessages.ClonedEntry{
      type: String.to_atom(String.upcase(Map.get(result, "type"))),
      trade_id: Map.get(result, "tradeID"),
      date: parse_date(Map.get(result, "date")),
      rate: Map.get(result, "rate"),
      amount: Map.get(result, "amount"),
      total: Map.get(result, "total")
    }
  end

  defp parse_date(date) do
    formatted = String.replace("#{date}Z", " ", "T")
    {:ok, res, _} = DateTime.from_iso8601(formatted)
    DateTime.to_unix(res)
  end
end
