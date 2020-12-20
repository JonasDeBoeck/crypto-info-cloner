defmodule ChunkCreator.FinishedTasksKafkaContext do
  alias KafkaEx.Protocol.Produce.Request
  @finished "finished-tasks"

  def create_task_response_produce_message(uuid, result) when is_atom(result) do
    task_response = %AssignmentMessages.TaskResponse{
      task_result: result,
      todo_task_uuid: uuid
    }

    encoded_task_response = AssignmentMessages.TaskResponse.encode!(task_response)
    %KafkaEx.Protocol.Produce.Message{value: encoded_task_response}
  end

  def produce_messages(messages) when is_list(messages) do
    for message <- messages do
      produce_message(message)
    end
  end

  def produce_message(message) do
    request = %{%Request{topic: @finished, required_acks: 1} | messages: [message]}
    KafkaEx.produce(request)
  end
end
