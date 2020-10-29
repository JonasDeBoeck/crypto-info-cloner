# Chunk creator application

This is a stand-alone application that doesn't need interaction from humans. It isn't connected to other nodes as well.

While this uses the same database as our director application, do understand that this is bad design. Managing migrations across multiple nodes is a recipe for disaster, though we do this so that you don't have to run multiple databases or integrate with Kafka Connect.

## Goal

__START OF TODO: REREAD__

The goal of this application is to verify incoming tasks, chunk the task up in chunks based on a config setting, put the chunks on the `todo-chunks` topic and await the result from the ``

## Data flow

This application will consume the `todo-tasks` topic. When a message arrives, it'll be responsible for:

 1. Checking whether it doesn't overlap with current tasks, if so emit a `AssignmentMessages.TaskResponse` with the `:TASK_CONFLICT` status.
 2. If there are no problems, create a task, divide it up into chunks (and put everything in the database). After that put those chunks (that need to be cloned) on the `todo-chunks` topic.

It will also consume the `finished-chunks` topic. It'll have to do the following when a chunk its result is posted:

 1. Check the `chunk_result`. If it is `WINDOW_TOO_BIG`, update your database that 2 smaller chunks need to be cloned. Also put these chunks again on the `todo-chunks` topic.
 2. If the result is good, update your database (and check if your task is complete). If your task is complete, put it on the `finished-tasks` topic with the `:COMPLETE` status.



Process __TodoTask__. These come from the director application and will contain the information of the information that needs to be fetched.

Create new __TodoChunk__. In this application, a chunk is defined as:

```text
A TodoChunk is a structure that contains a currency pair, a task id and two timestamps that indicate the interval where the information from the currency pair still needs to be fetched.
```

Process __ClonedChunk__ that are created by the workers.

```text
A ClonedChunk is a structure, created by the workers, that contain the fetched result. The Result enum tells whether the fetched result is complete or whether the time window was to big. When the chunk is complete you can find the fetched information in the collection of entries.
```

## Data flow

The chunk creator will use following topics:

* `todo-task` => use the `AssignmentMessages.TodoTask` struct from the extra library to encode your messages.
* `finished-task` => use the `AssignmentMessages.TaskResponse` struct
* `todo-chunk` => use the `AssignmentMessages.TodoChunk` struct
* `finished-chunks` => use the `AssignmentMessages.ClonedChunk` struct

__END OF TODO: REREAD__

## Libraries and usage for this application

We provide 2 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Look at the readme / API overview how to use these.

## Constraints

### Kafka constraints

Every topic should at least have 2 partitions.

### API & functionality constraints

TODO: work with kafkacontext

### Config constraints

Configure your window size in your config with the key `:max_window_size_in_sec`.

### Design constraints

This application will __only__ perform queries on the `TaskStatus`, `TaskRemainingChunk`, `CurrencyPairChunk` and `CurrencyPairEntry` tables.

## Tips

TODO: write this (and provide API of libraries)
