defmodule ChunkCreator.CompletedChunkConsumer do
  use KafkaEx.GenConsumer
  require Logger
  require IEx
  alias KafkaEx.Protocol.Fetch.Message
  alias KafkaEx.Protocol.Produce.Request

  @todo "todo-chunks"
  @finished "finished-tasks"

  def handle_message_set(message_set, state) do
    for %Message{value: message} <- message_set do
      # Decode message
      decoded_message = AssignmentMessages.ClonedChunk.decode!(message)
      # Fetch het id van de taak, from en until
      task_db_id = decoded_message.original_todo_chunk.task_dbid
      from = decoded_message.original_todo_chunk.from_unix_ts
      until = decoded_message.original_todo_chunk.until_unix_ts
      # Query de taak uit de database
      task = DatabaseInteraction.TaskStatusContext.get_by_id!(task_db_id)
      # Check of de chunk complete is
      if (decoded_message.chunk_result == :COMPLETE) do
        # Fetch de remaining chunk
        task_remaining_chunk = DatabaseInteraction.TaskRemainingChunkContext.get_chunk_by(task_db_id, from, until)
        # Markeer hem als done
        DatabaseInteraction.TaskRemainingChunkContext.mark_as_done(task_remaining_chunk)
        # Check of de taak done is
        status = DatabaseInteraction.TaskStatusContext.task_status_complete?(task_db_id)
        if (elem(status, 0)) do
          # Zet een taskresponse op de finished-tasks topic
          task_response = %AssignmentMessages.TaskResponse{task_result: :COMPLETE, todo_task_uuid: task.uuid}
          encoded_task_response = AssignmentMessages.TaskResponse.encode!(task_response)
          message = %KafkaEx.Protocol.Produce.Message{value: encoded_task_response}
          request = %{%Request{topic: @finished, required_acks: 1} | messages: [message]}
          KafkaEx.produce(request)
        end
      else
        # Halveer de chunks
        chunks = Enum.map(DatabaseInteraction.TaskRemainingChunkContext.halve_chunk(task_db_id, from, until), fn x -> x end)
        # Zet elke chunk apart op de todo-chunks topic
        for chunk <- chunks do
          todo_chunk = %AssignmentMessages.TodoChunk{currency_pair: task.currency_pair, from_unix_ts: DateTime.to_unix(chunk.from), until_unix_ts: DateTime.to_unix(chunk.until), task_dbid: task.task_status.id}
          encoded_chunk = AssignmentMessages.encode_message!(todo_chunk)
          message = %KafkaEx.Protocol.Produce.Message{value: encoded_chunk}
          request = %{%Request{topic: @todo, required_acks: 1} | messages: [message]}
          KafkaEx.produce(request)
        end
      end
    end
    {:async_commit, state}
  end
end
