defmodule RMQTest.Receiver do
  use GenServer
  use AMQP

  def start_link({from, channel}) do
    GenServer.start_link(__MODULE__, %{:channel => channel, :from => from})
  end

  def queue_name?(pid) do
    GenServer.call(pid, {:queue_name})
  end

  # def calculate(value) do
  #   GenServer.call(__MODULE__, {:calculate, value})
  # end

  ## Server Callbacks
  def init(state) do
    {:ok, response_queue} = Queue.declare(state.channel, "", [exclusive: true, durable: true])
    state = Map.put(state, :response_queue, response_queue)

    # Consume messages
    {:ok, _consumer_tag} = Basic.consume(state.channel, response_queue.queue)

    {:ok, state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    IO.puts("Registered as consumer: " <> consumer_tag)
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: _tag, redelivered: _redelivered}}, state) do
    #spawn fn -> consume(chan, tag, redelivered, payload) end
    {:ok, data} = :msgpack.unpack(payload)
    IO.inspect(data)
    GenServer.reply(state.from, {:done, Map.get(data, 'result')})
    {:noreply, state}
  end

  def handle_call({:queue_name}, _from, state) do
    {:reply, state.response_queue.queue, state}
  end

end
