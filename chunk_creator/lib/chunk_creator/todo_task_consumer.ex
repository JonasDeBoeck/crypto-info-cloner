defmodule ChunkCreator.TodoTaskConsumer do 
    use KafkaEx.GenConsumer
    require Logger
    require IEx
    alias KafkaEx.Protocol.Fetch.Message
    alias KafkaEx.Protocol.Produce.Request

    @topic "todo-chunks"

    def handle_message_set(message_set, state) do
        for %Message{value: message} <- message_set do
            # Message decoderen
            decoded_task = AssignmentMessages.TodoTask.decode!(message)
            IO.inspect(decoded_task)
            # Timestamps parsen naar utc
            {:ok, utc_from} = DateTime.from_unix(decoded_task.from_unix_ts)
            {:ok, utc_until} = DateTime.from_unix(decoded_task.until_unix_ts)
            # Chunks generaten voor task
            chunks = DatabaseInteraction.TaskStatusContext.generate_chunk_windows(decoded_task.from_unix_ts, decoded_task.until_unix_ts, Application.fetch_env!(:chunk_creator, :max_window_size_in_sec))
            # Instellen task attributen
            task_attrs = %{from: utc_from, until: utc_until, uuid: decoded_task.task_uuid}
            # Currency pair uit de db halen
            pair = DatabaseInteraction.CurrencyPairContext.get_pair_by_name(decoded_task.currency_pair)
            # Task createn
            {:ok, task} = DatabaseInteraction.TaskStatusContext.create_full_task(task_attrs, pair, chunks)
            IO.inspect(task)
            # Create chunks
            for chunk <- chunks do
                IO.inspect(chunk)
                todo_chunk = %AssignmentMessages.TodoChunk{currency_pair: decoded_task.currency_pair, from_unix_ts: DateTime.to_unix(chunk.from), until_unix_ts: DateTime.to_unix(chunk.until), task_dbid: task.task_status.id}
                encoded_chunk = AssignmentMessages.encode_message!(todo_chunk)
                message = %KafkaEx.Protocol.Produce.Message{value: encoded_chunk}
                request = %{%Request{topic: @topic, required_acks: 1} | messages: [message]}
                KafkaEx.produce(request)
            end
        end
        {:async_commit, state}
    end
end