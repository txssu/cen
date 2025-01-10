defmodule Cen.PCKE do
  @moduledoc false

  alias Cen.PCKE.Storage

  @spec start_challenge() :: {String.t(), String.t()}
  def start_challenge do
    state = generate_state()
    code = generate_code()
    :ok = Storage.put(state, code)

    {state, code}
  end

  @spec get_code(String.t()) :: String.t()
  def get_code(state) do
    Storage.take(state)
  end

  defp generate_state do
    random_string(32)
  end

  defp generate_code do
    code_length = 43 + :rand.uniform(85)
    random_string(code_length)
  end

  alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  numbers = "0123456789"

  @chars String.split(alphabets <> String.downcase(alphabets) <> numbers, "", trum: true)

  defp random_string(length) do
    1..length
    |> Enum.reduce([], fn _element, acc -> [Enum.random(@chars) | acc] end)
    |> Enum.join("")
  end
end
