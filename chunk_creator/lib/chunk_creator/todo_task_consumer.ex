defmodule ChunkCreator.TodoTaskConsumer do 
    use KafkaEx.GenConsumer
    require Logger
    require IEx
    alias KafkaEx.Protocol.Fetch.Message
    alias KafkaEx.Protocol.Produce.Request

    @topic "todo-tasks"

    def handle_message_set(message_set, state) do
        for %Message{value: message} <- message_set do
            IO.inspect(message)
            decoded_task = AssignmentMessages.TodoTask.decode!(message)
            IO.inspect(decoded_task)
        end
        {:async_commit, state}
  end
end