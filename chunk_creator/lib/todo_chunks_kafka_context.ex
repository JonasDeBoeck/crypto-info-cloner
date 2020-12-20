defmodule ChunkCreator.TodoChunksKafkaContext do
  alias KafkaEx.Protocol.Produce.Request
  @todo "todo-chunks"

  def task_remaining_chunk_to_produce_message(chunk, pair) do
    chunk_loaded = DatabaseInteraction.TaskRemainingChunkContext.load_association(chunk, [:task_status])
    todo_chunk = %AssignmentMessages.TodoChunk{currency_pair: pair, from_unix_ts: DateTime.to_unix(chunk.from), until_unix_ts: DateTime.to_unix(chunk.until), task_dbid: chunk_loaded.task_status_id}
    encoded_chunk = AssignmentMessages.encode_message!(todo_chunk)
    %KafkaEx.Protocol.Produce.Message{value: encoded_chunk}
  end

  def produce_message(messages) when is_list(messages) do
    for message <- messages do
      produce_message(message)
    end
  end

  def produce_message(message) do
    request = %{%Request{topic: @todo, required_acks: 1} | messages: [message]}
    KafkaEx.produce(request)
  end
end
