# Worker application

This application is responsible for fetching the required information from the public API (= [https://poloniex.com/public](https://poloniex.com/public)). This application consist of a structure of different modules that guarantee the creation and the uptime of the workers, the rate in which data is fetched and a manager.

## Goal

This application consists of following modules:

* The __chunk consumer__ will need to fetch the message from the `todo-chunk` topic, start the fetching process with the information in this message and send the result to the kafka on the `finished-chunk`.
* The __rate limiter__ will control the amount of fetch request that will be send to the public API by selecting the workers that get permission to start their fetch proces.
* The __dynamic supervisor__ maintain and create workers in the worker pool.
* The __queue__ is a queue of tasks.
* The __manager__ is the module that keeps track of the available workers, working workers and give the tasks that need to be done to an available worker.
* The __worker__ is the module that will fetch the data from the public API.

## Data flow

The __chunk consumer__ will start with consuming the message from the `todo-chunk` topic. It will decode the message and give the task to the __manager__, who will put this task on the __queue__. The __manager__ will periodically pull an task from the __queue__ and give it to an available worker. When a worker receives a task it will register with the rate limiter that he is waiting for permission to start his task. When he gets this permission he checks whether the window size is not to big and fetches the data from the public API. When the window size is to big, the worker will create an `AssignmentMessages.ClonedChunk` struct with `:WINDOW_TOO_BIG`. If the data fetch is succesful, the worker will put the data in a `AssignmentMessages.ClonedChunk` struct and send it back to the __manager__. If the fetch is not succesful, you need to log an error.

## Libraries and usage for this application

We provide 1 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.

Look at the readme / API overview how to use it.

## Constraints

### Kafka constraints

None, you're just consuming a topic and producing on an existing topic.

### API & functionality constraints

Create the following functions:

* `ClonerWorker.Queue.add_to_queue`
* `ClonerWorker.Queue.get_first_element`
* `ClonerWorker.WorkerManager.add_task`
* `ClonerWorker.RateLimiter.register`
* `ClonerWorker.RateLimiter.set_rate`

Following processes (not necessarily modules!) are expected to be alive when your application starts:

* `ClonerWorker.MyRegistry`
* `ClonerWorker.WorkerDynamicSupervisor`
* n `ClonerWorker.Worker` processes depending on your config. You don't need to be able to change the amount of workers at runtime.
  * Registers itself in the registry as {:worker, n} where n is a number.
* `ClonerWorker.Queue`
* `ClonerWorker.WorkerManager`
* `ClonerWorker.RateLimiter`

### Config constraints

Use a config file to configure the amount of workers and the rate limit: `n_workers`, `default_rate`

### Design constraints

This application will not interact with the database. We expect you to create a design that contains the modules as written in goal and the data flow statement.

## Tips

* `AssignmentMessages.TodoChunk` struct
* `AssignmentMessages.ClonedChunk` struct
* `AssignmentMessages.ClonedEntry` struct
* AssignmentMessages.encode_message/1

## Naming conventions and sample code

__You have to adhere to these naming conventions!__ If not, tests will fail and points will be subtracted from your end score.

Config:

```elixir
config :cloner_worker,
  n_workers: 4,
  default_rate: 2
```

```elixir
iex> ClonerWorker.Queue.add_to_queue
:ok
iex> ClonerWorker.Queue.get_first_element
{:ok, first_element_from_queue}
iex> ClonerWorker.WorkerManager.add_task
TODO
iex> ClonerWorker.RateLimiter.register
:ok
iex> ClonerWorker.RateLimiter.set_rate
:ok
```

### Consumer

In this application we will make use of the `ClonerWorker.TodoChunkConsumer` module for our consumer.
