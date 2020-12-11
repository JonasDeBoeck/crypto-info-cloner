defmodule Director do
  alias Director.TodoTasksKafkaContext
  alias Director.TopicsContext
  require Logger

  def create_topics() do
    TopicsContext.create_topics()
  end

  def delete_topics() do
    TopicsContext.delete_topics()
  end

  def automatic_create_tasks() do
    # Get config variabelen
    pairs = Application.fetch_env!(:director, :pairs_to_clone)
    {:ok, from} = DateTime.from_unix(Application.fetch_env!(:director, :from))
    {:ok, until} = DateTime.from_unix(Application.fetch_env!(:director, :until))
    # Loop over currency pairs uit config en maak een taak voor elke
    Enum.each(pairs, fn pair ->
      create_task(from, until, pair)
    end)
  end

  defp create_task(from, until, pair) do
    # Als de currency pair nog niet in de database bestaat, maak hem dan aan
    if DatabaseInteraction.CurrencyPairContext.get_pair_by_name(pair) == nil do
      Logger.info("Currency pair #{pair} does not yet exist, creating...")
      DatabaseInteraction.CurrencyPairContext.create_currency_pair(%{currency_pair: pair})
      Logger.info("Currency pair #{pair} created")
    end

    # Get currency pair van database
    currency_pair = DatabaseInteraction.CurrencyPairContext.get_pair_by_name(pair)
    # Genereer missende chunks voor het currency pair en log dit
    from_until =
      DatabaseInteraction.CurrencyPairChunkContext.generate_missing_chunks(
        from,
        until,
        currency_pair
      )

    # Maak kafka message
    message = TodoTasksKafkaContext.create_kafka_message({from, until}, pair)
    # Zet de message op de todo-tasks topic
    TodoTasksKafkaContext.produce_to_topic(message)
  end
end
