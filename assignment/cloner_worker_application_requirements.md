# Worker application

This application is responsible for fetching the required information from the public API (=https://poloniex.com/public). This application consist of a structure of different modules that guarantee the creation and the uptime of the workers, the rate in which data is fetched and a manager.

## Goal

The __chunk consumer__ will need to fetch the message from the `todo-chunk` topic, start the fetching process for the information in this message en send the result to the kafka on the `finished-chunk`.
The __rate limiter__ will control the amount of fetch request that will be send to the public API by selecting the workers that get permission to start their fetch proces.
The __dynamic supervisor__ maintain and create workers in the worker pool.
The __manager__ is the module that keeps track of the available workers, working workers and the fetch tasks that need to be done.
The __worker__ is the module that will fetch the data from the public API.

## Data flow

## Libraries and usage for this application

We provide 2 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Look at the readme / API overview how to use these.

## Constraints

### Kafka constraints

### API & functionality constraints

### Config constraints

### Design constraints

## Tips
