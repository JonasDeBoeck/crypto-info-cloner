# Director application

This application is our only application that should be interacted with directly.

## Goal

Create new __tasks__. In this application, a task is defined as:

```text
A task contains a currency pair, start time and end time. All the data between this needs to be cloned. There shouldn't be data overlapping in the database and the task that we're creating.
```

E.g. a "good" task would be:

In the database is no data (at all) regarding the `USDT_BTC` currency pair. We create a new task from t1 (start) until t2 (end).

E.g. a "bad" task would be:

In the database is data regarding the `USDT_BTC` currency pair. The database contains entries from 1 August - 13 August. We create a new task from t1 (start - 10 August) until t2 (end - 20 August). This overlaps and should raise an error!

__You could submit the task on the kafka topic, but the chunk creator application should detect this and cancel this task on the `finished-tasks` topic.__

## Data flow

As mentioned previously, the director application will use the following topics:

* `todo-tasks` => use the `AssignmentMessages.TodoTask` struct from the extra library to encode your messages.
* `finished-tasks` => use the `AssignmentMessages.TaskResponse` struct from the extra library to decode your messages.

The topic names are self-explanatory. You can look at [the proto schema](https://github.com/distributed-applications-2021/assignment-messages/blob/main/protobuf_schemas.proto) to see what the accepted values (atoms, e.g. `:ADD, :DELETE, :COMPLETE, :TASK_CONFLICT`) are for the enums.

## Libraries and usage for this application

We provide 2 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Look at the readme / API overview how to use these.

## Constraints

### Kafka constraints

Every topic should at least have 2 partitions.

When a task is completed, it suffices to just print a `Logger` message. E.g. "There has been a task conflict for the task ..." or "The following task has been completed: ...".

### API & functionality constraints

Create the following functions:

* `Director.create_topics/0`
* `Director.delete_topics/0`
* `Director.automatic_create_tasks/0` => this will use the config

### Config constraints

You will use the following config keys:

* `:pairs_to_clone` => a list of currency pairs. E.g. `["BTC_ETH", "USDT_BTC", "USDC_BTC"]`
* `:from` => a time in __unix timestamp format__ (seconds, not milliseconds)
* `:until` => a time in __unix timestamp format__ (seconds, not milliseconds)

These values are used by `Director.automatic_create_tasks/0`.

### Design constraints

This application will __only__ perform queries on the `CurrencyPair` table and read information from the `CurrencyPairChunk` table. It will __by no means perform inserts__ on the `Task` related tables.

## Tips

* `DatabaseInteraction.CurrencyPairContext.get_pair_by_name/1`
* `DatabaseInteraction.CurrencyPairContext.create_currency_pair/1`
* `DatabaseInteraction.CurrencyPairChunkContext.generate_missing_chunks/3`
* `AssignmentMessages.TodoTask` struct
* `AssignmentMessages.TaskResponse` struct
* `AssignmentMessages.encode_message/1`

## Naming conventions and sample code

__You have to adhere to these naming conventions!__ If not, tests will fail and points will be subtracted from your end score.

Config:

```elixir
config :director,
  pairs_to_clone: ["BTC_ETH", "USDT_BTC", "USDC_BTC"],
  from: 1_590_969_600,
  until: 1_591_500_000
```

### Kafka contexts

In order to guide you a bit (and make our testing process easier), we'll ask you to make these "KafkaContexts". These files their purpose is to abstract away the Kafka logic in one module.

We expect the following functions and their return values for `Director.TodoTasksKafkaContext`:

```elixir
# hint: the input of this function is suspiciously similar than the output of CurrencyPairChunkContext.generate_missing_chunks/3
iex> Director.TodoTasksKafkaContext.create_kafka_messages([{from_t1, until_t2}, {from_t3, until_t4}], "BTC_ETH")
[%KafkaEx.Protocol.Produce.Message{}, %KafkaEx.Protocol.Produce.Message{}, ...]
# List of produce messages.
iex> Director.TodoTasksKafkaContext.create_kafka_message({from_t1, until_t2}, "BTC_ETH")
%KafkaEx.Protocol.Produce.Message{}
# Single produce message
iex> Director.TodoTasksKafkaContext.produce_to_topic(%KafkaEx.Protocol.Produce.Message{ ... })
# Output the same as KafkaEx.produce
iex> Director.TodoTasksKafkaContext.produce_to_topic([%KafkaEx.Protocol.Produce.Message{ ... }, ...])
# Output the same as KafkaEx.produce
```

There's also the more general `Director.TopicsKafkaContext`:

```elixir
iex> Director.TopicsContext.create_topics
# self-explanatory. Creates topics with at least 2 partitions per topic
iex> Director.TopicsContext.delete_topics
# self-explanatory.
```

### Application "interface"

You'll interface with your application only through one module:

```elixir
iex> Director.create_topics()
iex> Director.delete_topics()
iex> Director.create_task(unix_from, unix_until, "BTC_ETH")
# Output: {:ok, 0}
#   Integer is the offset of the produced message
iex> Director.automatic_create_tasks
# Output: [ok: 1, ok: 2, ok: 3]
```

### Consumer

The module name is `Director.FinishedTaskConsumer`. You don't need to implement certain functions, except the necessary consumer callback `handle_message_set`.
