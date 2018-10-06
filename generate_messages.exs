nums = 1..100

stream = Task.async_stream(nums, fn n ->
  RMQTest.Sender.calculate(n)
end, timeout: :infinity)
Enum.each(stream, &IO.inspect/1)
