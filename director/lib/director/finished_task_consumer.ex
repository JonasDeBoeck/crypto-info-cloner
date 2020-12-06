defmodule Director.FinishedTaskConsumer do 
    use KafkaEx.GenConsumer
    require Logger
    require IEx
    alias KafkaEx.Protocol.Fetch.Message
    alias KafkaEx.Protocol.Produce.Request

    def handle_message_set(message_set, state) do
        for %Message{value: message} <- message_set do
            decoded_message = AssignmentMessages.TaskResponse.decode!(message)
            if (decoded_message.task_result == :TASK_CONFLICT) do
                Logger.error("There has been a task conflict for the task #{decoded_message.todo_task_uuid}")
            end
        end
        {:async_commit, state}
    end
end