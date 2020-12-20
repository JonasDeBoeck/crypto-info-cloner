defmodule ClonerWorker.TodoChunkConsumer do
  use KafkaEx.GenConsumer
  require Logger
  require IEx
  alias KafkaEx.Protocol.Fetch.Message

  def handle_message_set(message_set, state) do
    for %Message{value: message} <- message_set do
      # Decode de message
      decoded_message = AssignmentMessages.TodoChunk.decode!(message)
      # Add de taak aan de queue
      ClonerWorker.WorkerManager.add_task(decoded_message)
    end

    {:async_commit, state}
  end
end
