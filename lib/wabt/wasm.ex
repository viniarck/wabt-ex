defmodule Wabt.Wasm do
  @moduledoc """
  Wabt wasm binary transformations.
  """

  @doc """
  Convert a wasm binary file to a wat file.
  """
  @spec to_wat_file(String.t(), String.t()) :: {atom(), String.t()}
  def to_wat_file(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      :ok -> {:ok, wat_file}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Convert a wasm binary file to a wat file. It might raise Wabt.Error
  """
  @spec to_wat_file!(String.t(), String.t()) :: String.t()
  def to_wat_file!(wasm_file, wat_file)
      when is_bitstring(wasm_file) and is_bitstring(wat_file) do
    case Wabt.Native.wasm_to_wat(wasm_file, wat_file) do
      {:ok, wat_file} -> wat_file
      {:error, msg} -> raise Error, message: msg
    end
  end

  @doc """
  Convert wasm binary bytes to wat bytes.
  """
  @spec to_wat_bytes(String.t()) :: {atom(), String.t()}
  def to_wat_bytes(wasm_bytes) when is_bitstring(wasm_bytes) do
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
  @spec to_wat_bytes(String.t()) :: String.t()
  def to_wat_bytes!(wasm_bytes) when is_bitstring(wasm_bytes) do
    case Wabt.Wasm.to_wat_bytes(wasm_bytes) do
      {:error, msg} -> raise Error, message: msg
      {:ok, wat} -> wat
    end
  end


end
