defmodule RMQTest do
  use Application
  use AMQP

  def start(_type, _args) do
    # children = [
    #   {RMQTest.Server, []}
    # ]
    # Supervisor.start_link(children, strategy: :one_for_one)

    # Initialize AMQP channel and queues
    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    {:ok, out_queue} = Queue.declare(channel, "task_queue", durable: true)
    {:ok, in_queue} = Queue.declare(channel, "", [exclusive: true, durable: true])

    children = [
      { Registry, [keys: :unique, name: :rmqtest] },
      { RMQTest.Sender, [channel: channel, out_queue: out_queue, in_queue: in_queue] },
      { RMQTest.Receiver, [channel: channel, out_queue: out_queue, in_queue: in_queue] },
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
