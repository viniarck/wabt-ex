defmodule Wabt.Wat do
  @moduledoc """
  Wabt wat transformations.
  """

  @doc """
  Convert a wat file to a wasm binary file.
  """
  @spec to_wasm_file(String.t(), String.t()) :: {atom(), String.t()}
  def to_wasm_file(wat_file, wasm_file)
      when is_bitstring(wat_file) and is_bitstring(wasm_file) do
    case Wabt.Native.wat_to_wasm(wat_file, wasm_file) do
      :ok -> {:ok, wasm_file}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Convert a wat file to a wasm binary file. It might raise Wabt.Error
  """
  @spec to_wasm_file!(String.t(), String.t()) :: String.t()
  def to_wasm_file!(wat_file, wasm_file)
      when is_bitstring(wat_file) and is_bitstring(wat_file) do
    case Wabt.Native.wat_to_wasm(wat_file, wasm_file) do
      :ok -> wasm_file
      {:error, msg} -> raise Error, message: msg
    end
  end

  @doc """
  Convert wat bytes to wasm binary bytes.
  """
  @spec to_wasm_bytes(String.t()) :: {atom(), String.t()}
  def to_wasm_bytes(wat_bytes) when is_bitstring(wat_bytes) do
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
  @spec to_wasm_bytes!(String.t()) :: String.t()
  def to_wasm_bytes!(wat_bytes) when is_bitstring(wat_bytes) do
    case Wabt.Wat.to_wasm_bytes(wat_bytes) do
      {:ok, wasm_bytes} -> wasm_bytes
      {:error, msg} -> {:error, msg}
    end
  end
end
