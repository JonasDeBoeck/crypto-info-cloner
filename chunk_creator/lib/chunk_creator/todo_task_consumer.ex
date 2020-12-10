defmodule ChunkCreator.TodoTaskConsumer do
    use KafkaEx.GenConsumer
    require Logger
    require IEx

    alias KafkaEx.Protocol.Produce.Request

    @todo "todo-chunks"
    @finished "finished-tasks"

    def handle_message_set(message_set, state) do
        for %Message{value: message} <- message_set do
            # Message decoderen
            decoded_task = AssignmentMessages.TodoTask.decode!(message)
            # Timestamps parsen naar utc
            {:ok, utc_from} = DateTime.from_unix(decoded_task.from_unix_ts)
            {:ok, utc_until} = DateTime.from_unix(decoded_task.until_unix_ts)
            # Check de databank voor overlap
            if (!check_overlap(decoded_task.currency_pair, utc_from, utc_until)) do
                # Geen overlap, dus taak aanmaken
                # Chunks generaten voor task
                chunks = DatabaseInteraction.TaskStatusContext.generate_chunk_windows(decoded_task.from_unix_ts, decoded_task.until_unix_ts, Application.fetch_env!(:chunk_creator, :max_window_size_in_sec))
                # Instellen task attributen
                task_attrs = %{from: utc_from, until: utc_until, uuid: decoded_task.task_uuid}
                # Currency pair uit de db halen
                pair = DatabaseInteraction.CurrencyPairContext.get_pair_by_name(decoded_task.currency_pair)
                IO.inspect(pair)
                # Task createn
                {:ok, task} = DatabaseInteraction.TaskStatusContext.create_full_task(task_attrs, pair, chunks)
                # Create chunks en zet deze op kafka
                for chunk <- chunks do
                    todo_chunk = %AssignmentMessages.TodoChunk{currency_pair: decoded_task.currency_pair, from_unix_ts: DateTime.to_unix(chunk.from), until_unix_ts: DateTime.to_unix(chunk.until), task_dbid: task.task_status.id}
                    encoded_chunk = AssignmentMessages.encode_message!(todo_chunk)
                    message = %KafkaEx.Protocol.Produce.Message{value: encoded_chunk}
                    request = %{%Request{topic: @todo, required_acks: 1} | messages: [message]}
                    KafkaEx.produce(request)
                end
            else
                # Wel overlap dus finished task met :TASK_CONFLICT op kafka zetten
                finished_task = %AssignmentMessages.TaskResponse{task_result: :TASK_CONFLICT, todo_task_uuid: decoded_task.task_uuid}
                encoded_finished_task = AssignmentMessages.encode_message!(finished_task)
                message = %KafkaEx.Protocol.Produce.Message{value: encoded_finished_task}
                request = %{%Request{topic: @finished, required_acks: 1} | messages: [message]}
                KafkaEx.produce(request)
            end
        end
        {:async_commit, state}
    end

    defp get_task_for_pair(loaded_associations, pair) do
        # Zoek de juiste task voor het pair
        Enum.find(loaded_associations, fn x -> x.currency_pair.currency_pair == pair end)
    end

    defp load_associations(task_statuses) do
        # Laad alle associaties en geef deze terug in een lijst
        Map.values(Enum.reduce(task_statuses, %{}, fn task_status, acc -> Map.put(acc, task_status.id, DatabaseInteraction.TaskStatusContext.load_association(task_status, [:currency_pair])) end))
    end

    defp check_overlap(pair, from, until) do
        # Get all tasks statuses van db
        task_statuses = DatabaseInteraction.TaskStatusContext.list_task_status()
        loaded_associations = load_associations(task_statuses)
        task = get_task_for_pair(loaded_associations, pair)
        # Check op overlap
        cond do
            task == nil -> false
            (from >= task.from && from <= task.until) || (until >= task.from && until <= task.until) -> true
            true -> false
        end
    end
end
