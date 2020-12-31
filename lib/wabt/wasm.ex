defmodule Wabt.Wasm do
  @moduledoc """
  Wabt wasm binary transformations.
  """

  @doc """
  Convert wasm binary bytes to wat.
  """
  @spec to_wat(String.t()) :: {atom(), String.t()}
  def to_wat(wasm_bytes) when is_bitstring(wasm_bytes) do
    Wabt.Native.wasm_to_wat(wasm_bytes)
  end

  @doc """
  Convert wasm binary bytes to wat. It might raise Wabt.Error
  """
  @spec to_wat!(String.t()) :: String.t()
  def to_wat!(wasm_bytes) when is_bitstring(wasm_bytes) do
    case Wabt.Wasm.to_wat(wasm_bytes) do
      {:error, msg} -> raise Wabt.Error, message: msg
      {:ok, wat_bytes} -> wat_bytes
    end
  end

  @doc """
  Decompile a wasm binary file into readable C-like syntax.
  """
  @spec decompile(String.t()) :: {atom(), String.t()}
  def decompile(wasm_file) when is_bitstring(wasm_file) do
    Wabt.Native.wasm_decompile(wasm_file)
  end

  @doc """
  Decompile a wasm binary file into readable C-like syntax. It might raise Wabt.Error.
  """
  @spec decompile(String.t()) :: {atom(), String.t()}
  def decompile!(wasm_file) when is_bitstring(wasm_file) do
    case Wabt.Native.wasm_decompile(wasm_file) do
      {:error, msg} -> raise Wabt.Error, message: msg
      {:ok, decompiled} -> decompiled
    end
  end
end
