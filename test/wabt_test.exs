defmodule WabtTest do
  use ExUnit.Case
  doctest Wabt

  test "wasm_to_wat_bytes" do

    wasm = "test/data/hello_bg.wasm"
    wat_res = Wabt.wasm_to_wat_bytes!(wasm |> File.read!())
    assert String.contains?(wat_res, "plus_10")
  end
end
