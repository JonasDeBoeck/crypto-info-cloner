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
    # Voeg taak toe aan lijst van taken
    new_tasks = state.tasks ++ [task]
    # Registreer zichzelf bij de ratelimiter
    ClonerWorker.RateLimiter.regster(self())
    {:noreply, %@me{tasks: new_tasks}}
  end

  def work(pid) do
    GenServer.cast(pid, :work)
  end

  def handle_cast(:work, state) do
    # Pak de eerste (en enige) taak uit de lijst van taken
    task = Enum.at(state.tasks, 0)
    # Stel de request url samen
    request_url = "#{@url}#{task.currency_pair}&start=#{task.from_unix_ts}&end=#{task.until_unix_ts}"
    # Stuur request
    {:ok, res} = Tesla.get(request_url, [])
    # Parse de body
    result = Jason.decode!(res.body)
    # Maak een lijst van ClonedEntries
    entries = Enum.map(result, &create_cloned_entry/1)
    if (length(result) > 1000) do
      # Zet WINDOW_TOO_BIG op de finished-chunks topic
      cloned_chunk = %AssignmentMessages.ClonedChunk{chunk_result: :WINDOW_TOO_BIG, original_todo_chunk: task, entries: entries, possible_error_message: "More than 1000 elements"}
      encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
      send_kafka_request(encoded_cloned_chunk)
    else
      # Zet geclonede chunk op de finished-chunks topic
      cloned_chunk = %AssignmentMessages.ClonedChunk{chunk_result: :COMPLETE, original_todo_chunk: task, entries: entries, possible_error_message: ""}
      encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
      send_kafka_request(encoded_cloned_chunk)
    end
    # Drop de taak uit de lijst
    new_tasks = Enum.drop(state.tasks, 1)
    # Verander zijn status
    ClonerWorker.WorkerManager.change_worker_status(self())
    {:noreply, %@me{tasks: new_tasks}}
  end

  defp send_kafka_request(encoded_cloned_chunk) do
    # Verzend de kafka request
    message = %KafkaEx.Protocol.Produce.Message{value: encoded_cloned_chunk}
    request = %{%Request{topic: "finished-chunks", required_acks: 1} | messages: [message]}
    KafkaEx.produce(request)
  end

  defp create_cloned_entry(result) do
    # Maakt een cloned entry van een cloned chunk
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
    # Parsed een date
    formatted = String.replace("#{date}Z", " ", "T")
    {:ok, res, _} = DateTime.from_iso8601(formatted)
    DateTime.to_unix(res)
  end
end
