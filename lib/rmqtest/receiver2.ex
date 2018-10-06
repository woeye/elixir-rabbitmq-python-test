defmodule RMQTest.Receiver2 do
  use AMQP

  def send_and_receive(sender, channel, value) do
    {:ok, response_queue} = Queue.declare(channel, "", [exclusive: true, durable: true])

    message = :msgpack.pack(%{
      :command => "calculate",
      :respond_to => response_queue.queue,
      :params => %{
        :value => value
      }
    })
    AMQP.Basic.publish(channel, "", "task_queue", message, persistent: true)

    # Consume messages
    {:ok, _consumer_tag} = Basic.consume(channel, response_queue.queue)
    loop(sender, channel)
  end

  defp loop(sender, channel) do
    receive do
      {:basic_consume_ok, payload, _} ->
        IO.inspect(payload)
    after 5_000 ->
       loop(sender, channel)
    end
  end

  # # Confirmation sent by the broker after registering this process as a consumer
  # def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
  #   IO.puts("Registered as consumer: " <> consumer_tag)
  #   {:noreply, chan}
  # end

  # def handle_info({:basic_deliver, payload, %{delivery_tag: _tag, redelivered: _redelivered}}, state) do
  #   #spawn fn -> consume(chan, tag, redelivered, payload) end
  #   {:ok, data} = :msgpack.unpack(payload)
  #   IO.inspect(data)
  #   GenServer.reply(state.from, {:done, Map.get(data, 'result')})
  #   {:noreply, state}
  # end

  # def handle_call({:queue_name}, _from, state) do
  #   {:reply, state.response_queue.queue, state}
  # end

end
