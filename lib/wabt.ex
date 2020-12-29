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

  @doc """
  Convert a Wasm file to a Wat file.
  """
  def wasm_to_wat_file(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    Wabt.Native.wasm_to_wat(wasm_file, wat_file)
  end

  @doc """
  Convert Wasm binary bytes to Wat bytes.
  """
  def wasm_to_wat_bytes(wasm_bytes) when is_bitstring(wasm_bytes) do
    wasm_file = Briefly.create!()
    File.write!(wasm_file, wasm_bytes, [:binary])

    wat_file = Briefly.create!()

    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      :ok ->
        wat = File.read!(wat_file)
        File.rm!(wasm_file)
        File.rm!(wat_file)
        wat

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Convert Wasm binary bytes to Wat bytes.
  """
  def wasm_to_wat_bytes!(wasm_bytes) when is_bitstring(wasm_bytes) do
    case Wabt.wasm_to_wat_bytes(wasm_bytes) do
      {:error, err} -> raise Error, message: err
      wat -> wat
    end
  end


  @doc """
  Convert a Wat file to a Wasm file.
  """
  def wat_to_wasm_file(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    Wabt.Native.wat_to_wasm(wasm_file, wat_file)
  end
end
