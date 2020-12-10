defmodule ClonerWorker.TodoChunksKafkaContext do
  alias KafkaEx.Protocol.Fetch.Message
  alias KafkaEx.Protocol.Produce.Request
  @todo "todo-chunks"
  def task_remaining_chunk_to_produce_message(chunk, pair) do
    # todo_chunk = %AssignmentMessages.TodoChunk{currency_pair: pair, from_unix_ts: DateTime.to_unix(chunk.from), until_unix_ts: DateTime.to_unix(chunk.until), task_dbid: task.task_status.id}
    # encoded_chunk = AssignmentMessages.encode_message!(todo_chunk)
    # message = %Message{value: encoded_chunk}
    # message
  end

  def produce_message(messages) when is_list(messages) do
    for message <- messages do
      request = %{%Request{topic: @todo, required_acks: 1} | messages: [message]}
      KafkaEx.produce(request)
    end
  end
end
