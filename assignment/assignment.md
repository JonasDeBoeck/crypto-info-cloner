# Assignment Distributed Applications 20-21

## Rules

Read the [rules](rules.md). Submission details and deadline is described in this file.

## Project overview

### Goal

We want to make a platform that allows us to do calculations on past data. In order to make this performant (and make up-to-date) ML models, you'll want to have this data locally.

You'll create a distributed application using Kafka and Elixir<!-- 's distributed communication --> in order to obtain this data. Why should we do this in a distributed approach? It is often that network communication is the bottleneck in applications. Hence that you'll want to use multiple IP addresses to e.g. webscrape / access API's / ... .

### Technologies

#### Kafka

Since our events can be processed in an asynchronous way without any problems, we'll use Kafka to orchestrate the communication and make our application horizontally scalable.

Reliability will be achieved thanks to the events that are recorded on the kafka topics. You can find a schema later on. You'll have to think of the communication through your application in events.

<!-- #### Distributed Elixir

To not only see one approach to distributed applications in this assignment, we'll also be using distributed Elixir. The idea is that you can create multiple workers behind a single IP (e.g. public IP that is NAT'ted to private ip's) and use multiple nodes to achieve a tolerant application (in case a node crashes for example).

In the above case, you'll want to manage your rate over different nodes. E.g. node 1 and 2 __together__ can only have a maximum rate of 6 req/s because they're using a single public IP address. Details regarding the API and implementation will be discussed later on.

It is not often that you'll use these 2 approaches to distributed applications in a single application. _We are aware that this is a bit forced for educational purposes._ -->

### High level schema

The complete application architecture will look like [this](schema2.png). Every piece will be explained in detail.

The database will look like [this](db_schema.png). You won't have to interact with this directly as we'll provide a library for that. In this library, we will set up some queries, transactions, unique constraints and so on.

## Application requirements

Constraints are written in the specifica application requirements files.

### Director application

Read the requirements for the [director application](director_application_requirements.md).

### Chunk creator application

Read the requirements for the [chunk creator application](chunk_creator_application_requirements.md).

### Cloner worker application

Read the requirements for the [cloner worker application](cloner_worker_application_requirements.md).

## Some things to get you started

We provide you with 2 libraries:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Both libraries restrict you to store and pass the data along in a specific format. While this isn't the most enjoyable developer experience, this does give us the opportunity to quickly test all implementations as they use the same naming conventions, structs, encoded messages, and so on.

## Constraints

We provide a [script](../project_test.sh) to see whether you are conform to the project naming convections. Every small sub application will have its own naming conventions. Adhere to these or our tests will fail automatically! Same goes for the topic names, topic partitions, application names, and so on.

### Project names

The project names:

* `Director`
* `ChunkCreator`
* `ClonerWorker`
<!-- * `ClonerRateLimiter` -->

### Kafka topic names

These are the topic names __which each have at least 2 partitions__:

* `todo-tasks`
* `finished-tasks`
* `todo-chunks`
* `finished-chunks`

We'll refer to this topics in te application descriptions, but chances are we make a typo. To avoid confusion, the above names are the correct ones.
