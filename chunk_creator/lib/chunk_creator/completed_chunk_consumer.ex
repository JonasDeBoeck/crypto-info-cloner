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
      # Delegeer het afhandelen door aan handle_message
      handle_message(decoded_message)
    end

    {:async_commit, state}
  end

  defp handle_message(decoded_message) do
    # Delegeer het afhandelen van de chunk door aan handle_chunk
    handle_chunk(decoded_message, decoded_message.chunk_result)
  end

  defp handle_chunk(decoded_message, :RANDOM_ERROR) do
    Logger.error(decoded_message.possible_error_message)
  end

  # Handle de complete chunks, pattern mathc op :COMPLETE
  defp handle_chunk(decoded_message, :COMPLETE) do
    # Fetch de info en steek deze in de juiste variabelen
    info = fetch_info(decoded_message)
    task_db_id = elem(info, 0)
    from = elem(info, 1)
    until = elem(info, 2)
    task = elem(info, 3)
    # Haal de entries uit de ClonedChunk message
    entries = decoded_message.entries
    # Fetch de remaining chunk
    task_remaining_chunk =
      DatabaseInteraction.TaskRemainingChunkContext.get_chunk_by(task_db_id, from, until)

    # Markeer hem als done
    DatabaseInteraction.TaskRemainingChunkContext.mark_as_done(task_remaining_chunk)
    # Insert data into db
    DatabaseInteraction.CurrencyPairChunkContext.create_chunk_with_entries(
      task_remaining_chunk,
      entries
    )

    # Check of de taak done is
    status = DatabaseInteraction.TaskStatusContext.task_status_complete?(task_db_id)
    # Als de taak klaar is
    if elem(status, 0) do
      # Handle de afgewerkte taak
      handle_finished_task(task)
    else
      Logger.info("UPDATE: #{elem(status, 2).done} / #{elem(status, 2).n} is done for task with uuid #{elem(status, 1).uuid}")
    end
  end

  # Handle de andere chunks
  defp handle_chunk(decoded_message, _) do
    # Fetch de info en steek deze in de juiste variabelen
    info = fetch_info(decoded_message)
    task_db_id = elem(info, 0)
    from = elem(info, 1)
    until = elem(info, 2)
    task = elem(info, 3)
    # Halveer de chunks
    chunks = DatabaseInteraction.TaskRemainingChunkContext.halve_chunk(task_db_id, from, until)
    halved = Tuple.to_list(chunks)
    # Zet elke chunk apart op de todo-chunks topic
    for chunk <- halved do
      produce(chunk, task, @todo)
    end
  end

  defp fetch_info(decoded_message) do
    # Fetch het id van de taak, from en until
    task_db_id = decoded_message.original_todo_chunk.task_dbid
    from = decoded_message.original_todo_chunk.from_unix_ts
    until = decoded_message.original_todo_chunk.until_unix_ts
    # Query de taak uit de database
    task = DatabaseInteraction.TaskStatusContext.get_by_id!(task_db_id)
    # Return dit in tuple vorm
    {task_db_id, from, until, task}
  end

  # Handle de afgewerkte tasks
  defp handle_finished_task(task) do
    # Verwijder de gecomplete taak uit de database
    DatabaseInteraction.TaskStatusContext.delete_task_status(task)
    # Zet een taskresponse op de finished-tasks topic
    produce(task, @finished)
  end

  # Produce de KafkaRequest voor de todo topic
  defp produce(chunk, task, @todo) do
    loaded = DatabaseInteraction.TaskStatusContext.load_association(task, [:currency_pair])
    message = ChunkCreator.TodoChunksKafkaContext.task_remaining_chunk_to_produce_message(chunk, loaded.currency_pair.currency_pair)
    ChunkCreator.TodoChunksKafkaContext.produce_message(message)
  end

  # Produce de KafkaRequest op de finished topic
  defp produce(task, @finished) do
    message = ChunkCreator.FinishedTasksKafkaContext.create_task_response_produce_message(task.uuid, :COMPLETE)
    ChunkCreator.FinishedTasksKafkaContext.produce_message(message)
  end
end
