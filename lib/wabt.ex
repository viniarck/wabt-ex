defmodule Wabt do
  @moduledoc """
  Wabt: WebAssembly Binary Toolkit bindings for Elixir.
  """

  defmodule Error do
    defexception message: ""
  end

  defmodule Native do
    @moduledoc """
    Wabt NIFs module. This module isn't meant to be used directly by the end user.
    """
    @on_load :load_nifs

    def load_nifs do
      :erlang.load_nif('./priv/native', 0)
    end

    def wasm_to_wat(_wasm_bytes) do
      raise "NIF wasm_to_wat/1 failed to load"
    end

    def wat_to_wasm(_wat_bytes) do
      raise "NIF wat_to_wasm/1 failed to load"
    end

    def wasm_decompile(_wasm_file) do
      raise "NIF wasm_decompile/1 failed to load"
    end
  end
end
