defmodule WabtTest do
  use ExUnit.Case
  doctest Wabt

  test "wasm_to_wat_bytes" do
    wasm_file = "test/data/hello_bg.wasm"

    wat_bytes =
      wasm_file
      |> File.read!()
      |> Wabt.Wasm.to_wat_bytes!()

    assert String.contains?(wat_bytes, "plus_10")
  end

  test "wasm bytes -> wat bytes -> wasm bytes" do
    wasm_file = "test/data/hello_bg.wasm"

    wasm_bytes =
      wasm_file
      |> File.read!()
      |> Wabt.Wasm.to_wat_bytes!()
      |> Wabt.Wat.to_wasm_bytes!()

    assert File.read!(wasm_file) |> String.slice(0, 50) == wasm_bytes |> String.slice(0, 50)
  end

  test "wat bytes -> wasm bytes -> wat bytes" do
    wat_file = "test/data/plus_10.wat"

    wat_bytes =
      wat_file
      |> File.read!()
      |> Wabt.Wat.to_wasm_bytes!()
      |> Wabt.Wasm.to_wat_bytes!()

    assert wat_file |> File.read!() == wat_bytes

  end
end
