defmodule ClonerWorker.Worker do
  use Tesla
  use GenServer
  alias KafkaEx.Protocol.Produce.Request
  require Logger
  @me __MODULE__
  @url "https://poloniex.com/public?command=returnTradeHistory&currencyPair="
  defstruct tasks: []

  def start_link(name: name) do
    n = {:via, Registry, {ClonerWorker.MyRegistry, name}}
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
    # Send de request
    send_request(task)
    # Drop de taak uit de lijst
    new_tasks = Enum.drop(state.tasks, 1)
    # Verander zijn status
    ClonerWorker.WorkerManager.change_worker_status(self())
    {:noreply, %@me{tasks: new_tasks}}
  end

  defp send_request(task) do
    # Stel de request url samen
    request_url =
      "#{@url}#{task.currency_pair}&start=#{task.from_unix_ts}&end=#{task.until_unix_ts}"

    # Stuur request
    {_, res} = Tesla.get(request_url, [])
    # Handle de request body
    handle_request_body(res, task)
  end

  defp handle_request_body(res, task) do
    # Als de response code 200 is
    if res.status == 200 do
      # Parse de body
      result = Jason.decode!(res.body)
      # Als de body een map is, dan bevat de request een error
      if !is_map(result) do
        # Maak een lijst van ClonedEntries
        entries = Enum.map(result, &create_cloned_entry/1)

        if length(result) >= 1000 do
          Logger.warn("Window too big for pair #{task.currency_pair}... #{DateTime.from_unix!(task.from_unix_ts)} - #{DateTime.from_unix!(task.until_unix_ts)}")
          # Zet WINDOW_TOO_BIG op de finished-chunks topic
          encoded_cloned_chunk = create_chunk_message(task, entries, :WINDOW_TOO_BIG)
          send_kafka_request(encoded_cloned_chunk)
        else
          {hours, minutes, seconds} = seconds_to_time(task.until_unix_ts - task.from_unix_ts)
          Logger.info("Succesfully cloned #{task.currency_pair}. Length: #{length(result)} Window time in seconds: #{seconds}, minutes: #{minutes}, hours: #{hours}")
          # Zet geclonede chunk op de finished-chunks topic
          encoded_cloned_chunk = create_chunk_message(task, entries, :COMPLETE)
          send_kafka_request(encoded_cloned_chunk)
        end
      else
        # Zet een chunk met de error op de finished-chunks topic
        encoded_cloned_chunk = create_chunk_error_message(task, [], result)
        send_kafka_request(encoded_cloned_chunk)
      end
    end
  end

  defp seconds_to_time(seconds) do
    hours = round(seconds / 3600)
    new_sec = seconds - (seconds / 3600)
    IO.puts(new_sec)
    minutes = round(new_sec / 60)
    leftover_sec = seconds - (new_sec / 60)
    {hours, minutes, leftover_sec}
  end

  # Create chunk message for window too big, pattern match
  defp create_chunk_message(task, entries, :WINDOW_TOO_BIG) do
    cloned_chunk = %AssignmentMessages.ClonedChunk{
      chunk_result: :WINDOW_TOO_BIG,
      original_todo_chunk: task,
      entries: entries,
      possible_error_message: "More than 1000 elements"
    }

    encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
    encoded_cloned_chunk
  end

  # Create chunk message for complete, pattern match
  defp create_chunk_message(task, entries, :COMPLETE) do
    cloned_chunk = %AssignmentMessages.ClonedChunk{
      chunk_result: :COMPLETE,
      original_todo_chunk: task,
      entries: entries,
      possible_error_message: ""
    }

    encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
    encoded_cloned_chunk
  end

  # Create chunk message for error
  defp create_chunk_error_message(task, entries, result) do
    cloned_chunk = %AssignmentMessages.ClonedChunk{
      chunk_result: :RANDOM_ERROR,
      original_todo_chunk: task,
      entries: entries,
      possible_error_message: Map.get(result, "error")
    }

    encoded_cloned_chunk = AssignmentMessages.ClonedChunk.encode!(cloned_chunk)
    encoded_cloned_chunk
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
