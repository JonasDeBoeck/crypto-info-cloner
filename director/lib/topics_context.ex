defmodule Director.TopicsContext do
  alias KafkaEx.Protocol.CreateTopics.TopicRequest

  def create_topics() do
    # Create topics
    KafkaEx.create_topics([
      %TopicRequest{topic: "todo-tasks", num_partitions: 2, replication_factor: 1},
      %TopicRequest{topic: "finished-tasks", num_partitions: 2, replication_factor: 1},
      %TopicRequest{topic: "todo-chunks", num_partitions: 2, replication_factor: 1},
      %TopicRequest{topic: "finished-chunks", num_partitions: 2, replication_factor: 1}
    ])
  end

  def delete_topics() do
    # Delete topics
    KafkaEx.delete_topics(["todo-tasks", "finished-tasks", "todo-chunks", "finished-chunks"])
  end
end
