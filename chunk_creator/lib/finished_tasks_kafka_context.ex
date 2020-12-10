defmodule ChunkCreator.FinishedTasksKafkaContext do
  alias KafkaEx.Protocol.Fetch.Message
  alias KafkaEx.Protocol.Produce.Request
  @finished "finished-tasks"

  def create_task_response_produce_message(uuid, result) do
  end

  def produce_messages(messages) when is_list(messages) do
    for message <- messages do
      request = %{%Request{topic: @finished, required_acks: 1} | messages: [message]}
      KafkaEx.produce(request)
    end
  end
end
