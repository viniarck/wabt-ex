#include <erl_nif.h>
#include <iostream>
#include <vector>

#include "src/apply-names.h"
#include "src/binary-reader-ir.h"
#include "src/binary-reader.h"
#include "src/binary-writer.h"
#include "src/decompiler-naming.h"
#include "src/decompiler.h"
#include "src/error-formatter.h"
#include "src/feature.h"
#include "src/generate-names.h"
#include "src/ir.h"
#include "src/option-parser.h"
#include "src/stream.h"
#include "src/string-view.h"
#include "src/validator.h"
#include "src/wast-lexer.h"
#include "src/wast-parser.h"
#include "src/wat-writer.h"
#include "helpers.h"

ERL_NIF_TERM mk_atom(ErlNifEnv *env, const char *atom) {
  ERL_NIF_TERM ret;

  if (!enif_make_existing_atom(env, atom, &ret, ERL_NIF_LATIN1)) {
    return enif_make_atom(env, atom);
  }

  return ret;
}

ERL_NIF_TERM mk_error(ErlNifEnv *env, const std::string &msg) {
  return enif_make_tuple2(env, mk_atom(env, "error"),
                          enif_make_string(env, msg.c_str(), ERL_NIF_LATIN1));
}

ERL_NIF_TERM enif_make_error(ErlNifEnv *env, const char *err_msg) {
  return enif_make_tuple2(env, enif_make_atom(env, "error"),
                          enif_make_string(env, err_msg, ERL_NIF_LATIN1));
}

int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info) { return 0; }

void unload(ErlNifEnv *env, void *priv) {}

ERL_NIF_TERM wasm_to_wat(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary wasm_bytes;
  if (!enif_inspect_binary(env, argv[0], &wasm_bytes))
    return mk_error(env, "invalid wasm argument");

  wabt::InitStdio();
  wabt::Errors errors;
  wabt::Result result;
  wabt::Features s_features;
  wabt::WriteWatOptions s_write_wat_options;
  std::unique_ptr<wabt::FileStream> s_log_stream;

  auto file_data = elr_binary_to_vector(wasm_bytes);
  wabt::Module module;
  const bool s_read_debug_names = true;
  const bool kStopOnFirstError = true;
  const bool s_fail_on_custom_section_error = true;
  wabt::ReadBinaryOptions options(s_features, s_log_stream.get(),
                                  s_read_debug_names, kStopOnFirstError,
                                  s_fail_on_custom_section_error);
  result = wabt::ReadBinaryIr("", file_data.data(), file_data.size(), options,
                              &errors, &module);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::ValidateOptions val_options(s_features);
  result = wabt::ValidateModule(&module, &errors, val_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::MemoryStream stream;
  result = wabt::WriteWat(&stream, &module, s_write_wat_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  ErlNifBinary out;
  std::vector<uint8_t> *data = &stream.output_buffer().data;
  enif_alloc_binary(data->size(), &out);
  for (size_t i = 0; i < data->size(); i++) {
    out.data[i] = data->at(i);
  }

  return enif_make_tuple2(env, mk_atom(env, "ok"), enif_make_binary(env, &out));
}

ERL_NIF_TERM wat_to_wasm(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {

  ErlNifBinary wat_bytes;
  if (!enif_inspect_binary(env, argv[0], &wat_bytes))
    return mk_error(env, "invalid wat argument");

  wabt::InitStdio();
  wabt::Errors errors;
  wabt::Result result;
  std::unique_ptr<wabt::FileStream> s_log_stream;
  wabt::WriteBinaryOptions s_write_binary_options;

  auto file_data = elr_binary_to_vector(wat_bytes);
  std::unique_ptr<wabt::WastLexer> lexer = wabt::WastLexer::CreateBufferLexer(
      "", file_data.data(), file_data.size());

  wabt::Features s_features;
  std::unique_ptr<wabt::Module> module;
  wabt::WastParseOptions parse_wast_options(s_features);
  result = ParseWatModule(lexer.get(), &module, &errors, &parse_wast_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::ValidateOptions options(s_features);
  result = wabt::ValidateModule(module.get(), &errors, options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::MemoryStream stream(s_log_stream.get());
  s_write_binary_options.features = s_features;
  result =
      wabt::WriteBinaryModule(&stream, module.get(), s_write_binary_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  ErlNifBinary out;
  std::vector<uint8_t> *data = &stream.output_buffer().data;
  enif_alloc_binary(data->size(), &out);
  for (size_t i = 0; i < data->size(); i++) {
    out.data[i] = data->at(i);
  }

  return enif_make_tuple2(env, mk_atom(env, "ok"), enif_make_binary(env, &out));
}

ERL_NIF_TERM wasm_decompile(ErlNifEnv *env, int argc,
                            const ERL_NIF_TERM argv[]) {

  ErlNifBinary wasm_bytes;
  if (!enif_inspect_binary(env, argv[0], &wasm_bytes))
    return mk_error(env, "invalid wasm argument");

  wabt::InitStdio();
  wabt::Errors errors;
  wabt::Result result;

  wabt::Features features;
  wabt::DecompileOptions decompile_options;
  bool fail_on_custom_section_error = true;

  auto file_data = elr_binary_to_vector(wasm_bytes);

  wabt::Module module;
  const bool kStopOnFirstError = true;
  wabt::ReadBinaryOptions options(features, nullptr, true, kStopOnFirstError,
                                  fail_on_custom_section_error);
  result = wabt::ReadBinaryIr("", file_data.data(), file_data.size(), options,
                              &errors, &module);
  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::ValidateOptions val_options(features);
  result = wabt::ValidateModule(&module, &errors, val_options);
  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  result = wabt::GenerateNames(
      &module, static_cast<wabt::NameOpts>(wabt::NameOpts::AlphaNames));
  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }
  RenameAll(module);

  result = wabt::ApplyNames(&module);
  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  auto s = Decompile(module, decompile_options);

  ErlNifBinary out;
  enif_alloc_binary(s.length(), &out);
  for (size_t i = 0; i < s.length(); i++) {
    out.data[i] = s.at(i);
  }

  return enif_make_tuple2(env, mk_atom(env, "ok"), enif_make_binary(env, &out));
}

ErlNifFunc nif_funcs[] = {
    {"wasm_to_wat", 1, wasm_to_wat, 0},
    {"wat_to_wasm", 1, wat_to_wasm, 0},
    {"wasm_decompile", 1, wasm_decompile, 0},
};

ERL_NIF_INIT(Elixir.Wabt.Native, nif_funcs, load, NULL, NULL, unload);
