defmodule WabtTest do
  use ExUnit.Case
  doctest Wabt

  test "wasm_to_wat_bytes" do
    wasm_file = "test/data/hello_bg.wasm"

    wat_bytes =
      wasm_file
      |> File.read!()
      |> Wabt.Wasm.to_wat!()

    assert String.contains?(wat_bytes, "plus_10")
  end

  test "wasm bytes -> wat bytes -> wasm bytes" do
    wasm_file = "test/data/hello_bg.wasm"

    wasm_bytes =
      wasm_file
      |> File.read!()
      |> Wabt.Wasm.to_wat!()
      |> Wabt.Wat.to_wasm!()

    assert File.read!(wasm_file) |> String.slice(0, 50) == wasm_bytes |> String.slice(0, 50)
  end

  test "wat bytes -> wasm bytes -> wat bytes" do
    wat_file = "test/data/plus_10.wat"

    wat_bytes =
      wat_file
      |> File.read!()
      |> Wabt.Wat.to_wasm!()
      |> Wabt.Wasm.to_wat!()

    assert wat_file |> File.read!() == wat_bytes
  end

  test "wasm_decompile" do
    wasm_file = "test/data/hello_bg.wasm"

    decompiled =
      wasm_file
      |> File.read!()
      |> Wabt.Wasm.decompile!()

    assert String.contains?(decompiled, "export function plus_10")
  end

  test "wasm_validate" do
    wasm_file = "test/data/hello_bg.wasm"

    wasm_bytes =
      wasm_file
      |> File.read!()

    assert wasm_bytes == Wabt.Wasm.validate!(wasm_bytes)
  end

  test "wasm_validate_error" do
    wasm_file = "test/data/hello_bg.wasm"

    wasm_bytes =
      wasm_file
      |> File.read!()
      |> String.slice(0, 10)

    {:error, msg} = Wabt.Wasm.validate(wasm_bytes)
  end
end
