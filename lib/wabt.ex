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
  Convert a wasm binary file to a wat file.
  """
  @spec wasm_to_wat_file(String.t(), String.t()) :: {atom(), String.t()}
  def wasm_to_wat_file(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      :ok -> {:ok, wat_file}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Convert a wasm binary file to a wat file. It might raise Wabt.Error
  """
  @spec wasm_to_wat_file!(String.t(), String.t()) :: String.t()
  def wasm_to_wat_file!(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      {:ok, wat_file} -> wat_file
      {:error, msg} -> raise Error, message: msg
    end
  end

  @doc """
  Convert wasm binary bytes to wat bytes.
  """
  @spec wasm_to_wat_bytes(String.t()) :: {atom(), String.t()}
  def wasm_to_wat_bytes(wasm_bytes) when is_bitstring(wasm_bytes) do
    wasm_file = Briefly.create!()
    File.write!(wasm_file, wasm_bytes, [:binary])

    wat_file = Briefly.create!()

    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      :ok ->
        wat_bytes = File.read!(wat_file)
        File.rm!(wasm_file)
        File.rm!(wat_file)
        {:ok, wat_bytes}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Convert wasm binary bytes to wat bytes. It might raise Wabt.Error
  """
  @spec wasm_to_wat_bytes!(String.t()) :: String.t()
  def wasm_to_wat_bytes!(wasm_bytes) when is_bitstring(wasm_bytes) do
    case Wabt.wasm_to_wat_bytes(wasm_bytes) do
      {:error, msg} -> raise Error, message: msg
      {:ok, wat} -> wat
    end
  end

  @doc """
  Convert a wat file to a wasm binary file.
  """
  @spec wat_to_wasm_file(String.t(), String.t()) :: {atom(), String.t()}
  def wat_to_wasm_file(wat_file, wasm_file)
      when is_bitstring(wat_file) and is_bitstring(wasm_file) do
    case Wabt.Native.wat_to_wasm(wat_file, wasm_file) do
      :ok -> {:ok, wasm_file}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Convert a wat file to a wasm binary file. It might raise Wabt.Error
  """
  @spec wat_to_wasm_file!(String.t(), String.t()) :: String.t()
  def wat_to_wasm_file!(wat_file, wasm_file)
      when is_bitstring(wat_file) and is_bitstring(wat_file) do
    case Wabt.Native.wat_to_wasm(wat_file, wasm_file) do
      :ok -> wasm_file
      {:error, msg} -> raise Error, message: msg
    end
  end

  @doc """
  Convert wat bytes to wasm binary bytes.
  """
  @spec wat_to_wasm_bytes(String.t()) :: {atom(), String.t()}
  def wat_to_wasm_bytes(wat_bytes) when is_bitstring(wat_bytes) do
    wat_file = Briefly.create!()
    File.write!(wat_file, wat_bytes, [:binary])

    wasm_file = Briefly.create!()

    case Wabt.Native.wat_to_wasm(wat_file, wasm_file) do
      :ok ->
        wasm_bytes = File.read!(wasm_file)
        File.rm!(wasm_file)
        File.rm!(wat_file)
        {:ok, wasm_bytes}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Convert wat bytes to wasm binary bytes. It might raise Wabt.Error
  """
  @spec wat_to_wasm_bytes!(String.t()) :: String.t()
  def wat_to_wasm_bytes!(wat_bytes) when is_bitstring(wat_bytes) do
    case Wabt.wat_to_wasm_bytes(wat_bytes) do
      {:ok, wasm_bytes} -> wasm_bytes
      {:error, msg} -> {:error, msg}
    end
  end
end
