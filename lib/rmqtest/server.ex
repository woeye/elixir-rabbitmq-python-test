defmodule RMQTest.Server do
  use GenServer
  use AMQP

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def calculate(value) do
    GenServer.call(__MODULE__, {:calculate, value}, :infinity) # Wait for ever ... well
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, connection} = Connection.open
    {:ok, channel} = Channel.open(connection)
    Queue.declare(channel, "task_queue", durable: true)

    {:ok, %{
       :connection => connection,
       :channel => channel,
       :requests => %{}
    }}
  end

  def handle_call({:calculate, value}, from, state) do
    IO.puts "Spawning worker ..."
    pid = spawn fn ->
      {:ok, response_queue} = Queue.declare(state.channel, "", [exclusive: true, durable: true, auto_delete: true])

      message = :msgpack.pack(%{
        :command => "calculate",
        :respond_to => response_queue.queue,
        :params => %{
          :value => value
        }
      })
      Basic.publish(state.channel, "", "task_queue", message, persistent: true)

      # Consume messages
      {:ok, consumer_tag} = Basic.consume(state.channel, response_queue.queue)
      # IO.inspect(consumer_tag)
      loop(from, state.channel, consumer_tag)
    end
    Process.monitor(pid)

    {:noreply, state}
  end

  defp loop(from, channel, consumer_tag) do
    receive do
      {:basic_deliver, payload, %{delivery_tag: delivery_tag}} ->
        Basic.ack(channel, delivery_tag)
        Basic.cancel(channel, consumer_tag) # Unsubscribe -> this will delete the queue (because of auto delete)
        deliver_result(from, payload)
      after 2_000 -> # Still nothing, keep going for now
       loop(from, channel, consumer_tag)
    end
  end

  defp deliver_result(from, payload) do
    {:ok, data} = :msgpack.unpack(payload)
    # IO.inspect(data)
    GenServer.reply(from, {:done, Map.get(data, 'result')})
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    IO.puts "Worker finished: "
    IO.inspect(pid)
    {:noreply, state}
  end

  # IO.inspect(state)

    # Fire up receiver
    # {:ok, pid} = RMQTest.Receiver.start_link({from, state.channel})
    # queue_name = RMQTest.Receiver.queue_name?(pid)

    # message = :msgpack.pack(%{
    #   :command => "calculate",
    #   :respond_to => queue_name,
    #   :params => %{
    #     :value => value
    #   }
    # })
    # AMQP.Basic.publish(state.channel, "", "task_queue", message, persistent: true)

  #   {:noreply, state}
  # end
end
