# Chunk creator application

This is a stand-alone application that doesn't need interaction from humans. It isn't connected to other nodes as well.

While this uses the same database as our director application, do understand that this is bad design. Managing migrations across multiple nodes is a recipe for disaster, though we do this so that you don't have to run multiple databases or integrate with Kafka Connect (while this is the correct approach).

## Goal

TODO: write this

## Data flow

TODO: write this

## Libraries and usage for this application

We provide 2 libraries for you:

* [Messages library](https://github.com/distributed-applications-2021/assignment-messages). This will describe how the data in the messages should be put on your Kafka topics.
* [Database interaction library](https://github.com/distributed-applications-2021/assignment-database-interaction). This will abstract away how you'll have to interact with the database.

Look at the readme / API overview how to use these.

## Constraints

### Kafka constraints

Every topic should at least have 2 partitions.

### API & functionality constriants

TODO: write this

### Config constraints

TODO: write this

### Design constraints

TODO: write this

## Tips

TODO: write this
