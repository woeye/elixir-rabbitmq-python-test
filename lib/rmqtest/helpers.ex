defmodule RMQTest.Helpers do
  @hash_length 25

  def generate_hash() do
    :crypto.strong_rand_bytes(@hash_length) |> Base.url_encode64 |> binary_part(0, @hash_length)
  end
end
