defmodule Director do
  alias KafkaEx.Protocol.CreateTopics.TopicRequest
  alias KafkaEx.Protocol.Produce.Request

  def create_topics() do
    KafkaEx.create_topics([%TopicRequest{topic: "todo-tasks", num_partitions: 2, replication_factor: 1}, 
                           %TopicRequest{topic: "finished-tasks", num_partitions: 2, replication_factor: 1}
                          ])
  end

  def delete_topics() do
    KafkaEx.delete_topics(["todo-tasks", "finished-tasks"])
  end

  def create_tasks() do

  end

  def create_task(from, until, pair) do
    todo_task = %AssignmentMessages.TodoTask{task_operation: :ADD, currency_pair: pair, from_unix_ts: from |> DateTime.to_unix, until_unix_ts: until |> DateTime.to_unix, task_uuid: Ecto.UUID.generate}
    encoded_task = AssignmentMessages.encode_message!(todo_task)
    message = %KafkaEx.Protocol.Produce.Message{value: encoded_task}
    request = %{%Request{topic: "todo-tasks", required_acks: 1} | messages: [message]}
    KafkaEx.produce(request)
  end

  def hello do
    :world
  end
end