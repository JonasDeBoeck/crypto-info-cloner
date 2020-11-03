# Worker application

This application is responsible for fetching the required information from the public API (=https://poloniex.com/public). This application consist of a structure of different modules that guarantee the creation and the uptime of the workers, the rate in which data is fetched and a manager.

## Goal

* The __chunk consumer__ will need to fetch the message from the `todo-chunk` topic, start the fetching process with the information in this message and send the result to the kafka on the `finished-chunk`.
* The __rate limiter__ will control the amount of fetch request that will be send to the public API by selecting the workers that get permission to start their fetch proces.
* The __dynamic supervisor__ maintain and create workers in the worker pool.
* The __queue__ is a queue of tasks.
* The __manager__ is the module that keeps track of the available workers, working workers and give the tasks that need to be done to an available worker.
* The __worker__ is the module that will fetch the data from the public API.

## Data flow

The __chunk consumer__ will start with consuming the message from the `todo-chunk` topic. It will decode the message and give the task to the __manager__, who will put this task on the __queue__. The __manager__ will periodically pull an task from the __queue__ and give it to an available worker. When a worker receives a task it will register with the rate limiter that he is waiting for permission to start his task. When he gets this permission he checks whether the window size is not to big and fetches the data from the public API. When the window size is to big, the worker will create an `AssignmentMessages.ClonedChunk` struct with `:WINDOW_TOO_BIG`. If the data fetch is succesful, the worker will put the data in a `AssignmentMessages.ClonedChunk` struct and send it back to the __manager__. If the fetch is not succesful, you need to log an error. 

## Libraries and usage for this application

We provide 2 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Look at the readme / API overview how to use these.

## Constraints

### Kafka constraints

/

### API & functionality constraints

Here are some hints on what methods you can expect in the different modules:

* Workerpool.Worker.clone_chunk
* Workerpool.Queue.add_to_queue
* Workerpool.Queue.get_first_element
* Workerpool.WorkerManager.add_task
* Workerpool.RateLimiter.register
* Workerpool.RateLimiter.set_rate

### Config constraints

/

### Design constraints

This application will not interact with the database. We expect you to create a design that contains the modules as written in goal and the data flow statement.

## Tips

* `AssignmentMessages.TodoChunk` struct
* `AssignmentMessages.ClonedChunk` struct
* `AssignmentMessages.ClonedEntry` struct 
* AssignmentMessages.encode_message/1
