defmodule RMQTest.Receiver do
  use GenServer
  use AMQP

  def start_link([channel: channel, out_queue: out_queue, in_queue: in_queue]) do
    initial_state = %{ channel: channel, out_queue: out_queue, in_queue: in_queue }
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  ## Server Callbacks

  def init(state) do
    # Start consuming messages
    {:ok, _consumer_tag} = Basic.consume(state.channel, state.in_queue.queue)
    {:ok, state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    IO.puts("Registered as consumer: " <> consumer_tag)
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: delivery_tag, redelivered: _redelivered}}, state) do
    AMQP.Basic.ack(state.channel, delivery_tag)
    data = Poison.decode!(payload)
    IO.puts("Received data:")
    IO.inspect(data)

    with task_id <- Map.get(data, "task_id"),
         result <- Map.get(data, "result")
    do
      Registry.dispatch(:rmqtest, task_id, fn(listeners) ->
        for {pid, _} <- listeners, do: send(pid, {:broadcast, result})
      end)
    end
    {:noreply, state}
  end
end
