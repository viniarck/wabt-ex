defmodule Wabt.Wat do
  @moduledoc """
  Wabt wat transformations.
  """

  @doc """
  Convert wat bytes to wasm binary.
  """
  @spec to_wasm(String.t()) :: {atom(), String.t()}
  def to_wasm(wat_bytes) when is_bitstring(wat_bytes) do
    Wabt.Native.wat_to_wasm(wat_bytes)
  end

  @doc """
  Convert wat bytes to wasm binary. It might raise Wabt.Error
  """
  @spec to_wasm!(String.t()) :: String.t()
  def to_wasm!(wat_bytes) do
    case Wabt.Wat.to_wasm(wat_bytes) do
      {:error, msg} -> raise Wabt.Error, message: msg
      {:ok, wasm_bytes} -> wasm_bytes
    end
  end
end
