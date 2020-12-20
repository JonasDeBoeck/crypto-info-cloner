defmodule Director.TodoTasksKafkaContext do
  alias KafkaEx.Protocol.Produce.Request

  def create_kafka_message({from_t1, until_t2}, pair) do
    # Maak task
    todo_task = %AssignmentMessages.TodoTask{
      task_operation: :ADD,
      currency_pair: pair,
      from_unix_ts: from_t1 |> DateTime.to_unix(),
      until_unix_ts: until_t2 |> DateTime.to_unix(),
      task_uuid: Ecto.UUID.generate()
    }

    # Encode task
    encoded_task = AssignmentMessages.encode_message!(todo_task)
    # Wrap task in een message
    message = %KafkaEx.Protocol.Produce.Message{value: encoded_task}
    message
  end

  def create_kafka_messages(timestamps, pair) do
    Enum.map(timestamps, fn ts ->
      # Maak task
      todo_task = %AssignmentMessages.TodoTask{
        task_operation: :ADD,
        currency_pair: pair,
        from_unix_ts: elem(ts, 0) |> DateTime.to_unix(),
        until_unix_ts: elem(ts, 1) |> DateTime.to_unix(),
        task_uuid: Ecto.UUID.generate()
      }

      # Encode task
      encoded_task = AssignmentMessages.encode_message!(todo_task)
      # Wrap task in een message
      message = %KafkaEx.Protocol.Produce.Message{value: encoded_task}
      message
    end)
  end

  def produce_to_topic(message) when is_struct(message) do
    # Wrap de message in een request
    request = %{%Request{topic: "todo-tasks", required_acks: 1} | messages: [message]}
    # Zet de request op Kafka
    KafkaEx.produce(request)
  end

  def produce_to_topic(messages) when is_list(messages) do
    for message <- messages do
      # Wrap de message in een request
      request = %{%Request{topic: "todo-tasks", required_acks: 1} | messages: [message]}
      # Zet de request op Kafka
      KafkaEx.produce(request)
    end
  end
end
