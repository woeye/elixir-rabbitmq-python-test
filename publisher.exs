{:ok, connection} = AMQP.Connection.open
{:ok, channel} = AMQP.Channel.open(connection)

AMQP.Queue.declare(channel, "task_queue", durable: true)
{:ok, response_queue} = AMQP.Queue.declare(channel, "", [exclusive: true, durable: true])

# Send task
message = :msgpack.pack(%{
  :command => "calculate",
  :respond_to => response_queue.queue,
  :params => %{
    :value => 5
  }
})


AMQP.Basic.publish(channel, "", "task_queue", message, persistent: true)

{:ok, tag} = AMQP.Basic.consume(channel, response_queue)
receive do
   _ ->
    IO.puts("got data")
end

# IO.puts " [x] Sent '#{message}'"

AMQP.Connection.close(connection)
