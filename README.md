# RMQTest

In this proof of concept prototype I wanted to figure out how to set up a multiplexer in Elixir which uses RabbitMQ for calling Python workers. I also wanted to figure out how to implement a synchronous call which uses an asynchronous request / reply mechanism under the hood.

For example:

```elixir
result = RMQTest.Sender.calculate(n)
```

While this function call behaves synchronously on the outside it actually uses an asynchronous request / reply mechanism internally - because this is how most brokers work.

## Technical details

The elixir app will spawn three processes: a sender, a receiver and [Registry](https://hexdocs.pm/elixir/Registry.html) as a simple PubSub service.

Tbe sender will publish a message on the "task_queue" and immediately register with Registry and wait for a broadcast message. The reiver will consume messages on its own queue and use the Registry to inform its listeners as soon as data gets received.

## Synchronizing

In order to synchronize tasks between multiple requests / replies the sender will generate a unique hash (task_id) which will be put into the message. The worker will send this task_id as well as the result back to the receiver.

Both the sender and receiver use the task_id as a "topic" on the Registry. This way it is ensured that each request gets its proper reply.

Sender:

```elixir
def calculate(value) do
  task_id = GenServer.call(__MODULE__, {:calculate, value})
  Registry.register(:rmqtest, task_id, [])
  receive do
    {:broadcast, result} ->
      Registry.unregister(:rmqtest, task_id)
      IO.puts("calculate(#{value}) returned: #{result}")
      result
  end
end
```

The `receive do` call will block the invoking process until it receives the broadcast message. This way the `calculate` method can behave synchronously.

Receiver:

```elixir
def handle_info({:basic_deliver, payload, %{delivery_tag: delivery_tag, redelivered: _redelivered}}, state) do
  ...
  Registry.dispatch(:rmqtest, task_id, fn(listeners) ->
    for {pid, _} <- listeners, do: send(pid, {:broadcast, result})
  end)
  ...
end
```
