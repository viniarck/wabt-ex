defmodule Wabt do
  @moduledoc """
  Wabt: WebAssembly Binary Toolkit bindings for Elixir.
  """

  defmodule Error do
    defexception message: ""
  end

  defmodule Native do
    @on_load :load_nifs

    def load_nifs do
      :erlang.load_nif('./priv/native', 0)
    end

    def wasm_to_wat(_wasm, _wat) do
      raise "NIF wasm_to_wat/2 failed to load"
    end

    def wat_to_wasm(_wat, _wasm) do
      raise "NIF wat_to_wasm/2 failed to load"
    end
  end
end
