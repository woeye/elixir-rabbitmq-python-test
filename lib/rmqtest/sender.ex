defmodule RMQTest.Sender do
  use GenServer
  use AMQP
  import RMQTest.Helpers

  def start_link([channel: channel, out_queue: out_queue, in_queue: in_queue]) do
    initial_state = %{ channel: channel, out_queue: out_queue, in_queue: in_queue }
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  ## API

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

  ## Server Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:calculate, value}, _from, state) do
    task_id = generate_hash()
    message = Poison.encode!(%{
      :command => "calculate",
      :task_id => task_id,
      :respond_to => state.in_queue.queue,
      :params => %{
        :value => value
      }
    })
    Basic.publish(state.channel, "", state.out_queue.queue, message, persistent: true)
    {:reply, task_id, state}
  end
end
