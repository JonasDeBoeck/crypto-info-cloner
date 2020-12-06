defmodule Director do
  alias KafkaEx.Protocol.Produce.Request
  alias Director.TopicsContext

  def create_topics() do
    TopicsContext.create_topics()
  end

  def delete_topics() do
    TopicsContext.delete_topics()
  end

  def create_tasks() do
    # Get config variabelen
    pairs = Application.fetch_env!(:director, :pairs_to_clone)
    {:ok, from} = DateTime.from_unix(Application.fetch_env!(:director, :from))
    {:ok, until} = DateTime.from_unix(Application.fetch_env!(:director, :until))
    # Loop over currency pairs uit config en maak een taak voor elke
    Enum.each(pairs, fn pair ->
      create_task(from, until, pair)
    end)
  end

  def create_task(from, until, pair) do
    # Als de currency pair nog niet in de database bestaat, maak hem dan aan
    if (DatabaseInteraction.CurrencyPairContext.get_pair_by_name(pair) == nil) do
      DatabaseInteraction.CurrencyPairContext.create_currency_pair(%{currency_pair: pair})
    end
    # Maak task
    todo_task = %AssignmentMessages.TodoTask{task_operation: :ADD, currency_pair: pair, from_unix_ts: from |> DateTime.to_unix, until_unix_ts: until |> DateTime.to_unix, task_uuid: Ecto.UUID.generate}
    # Encode task
    encoded_task = AssignmentMessages.encode_message!(todo_task)
    # Wrap task in een message
    message = %KafkaEx.Protocol.Produce.Message{value: encoded_task}
    # Wrap de message in een request
    request = %{%Request{topic: "todo-tasks", required_acks: 1} | messages: [message]}
    # Zet de request op Kafka
    KafkaEx.produce(request)
  end
end