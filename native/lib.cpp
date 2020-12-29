#include <erl_nif.h>
#include <iostream>
#include <sys/stat.h>
#include <vector>

#include "src/apply-names.h"
#include "src/binary-reader-ir.h"
#include "src/binary-reader.h"
#include "src/binary-writer.h"
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

int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info) { return 0; }

ERL_NIF_TERM enif_make_error(ErlNifEnv *env, const char *err_msg) {
  return enif_make_tuple2(env, enif_make_atom(env, "error"),
                          enif_make_string(env, err_msg, ERL_NIF_LATIN1));
}

void unload(ErlNifEnv *env, void *priv) {}

static wabt::Result WriteBufferToFile(wabt::string_view filename,
                                      const wabt::OutputBuffer &buffer,
                                      wabt::Errors *errors,
                                      bool dump_memory = false) {
  if (dump_memory) {
    std::unique_ptr<wabt::FileStream> stream = wabt::FileStream::CreateStdout();
    stream->wabt::Stream::WriteMemoryDump(buffer.data.data(),
                                          buffer.data.size());
  }

  auto result = buffer.WriteToFile(filename);
  if (wabt::Failed(result)) {
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  "failed to write"});
  }
  return result;
}

wabt::Result read_file(wabt::string_view filename,
                       std::vector<uint8_t> *out_data, wabt::Errors *errors) {
  std::string filename_str = filename.to_string();
  const char *filename_cstr = filename_str.c_str();

  struct stat statbuf;
  if (stat(filename_cstr, &statbuf) < 0) {
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string(strerror(errno)) +
                                      std::string(" ") + filename_str});
    return wabt::Result::Error;
  }

  if (!(statbuf.st_mode & S_IFREG)) {
    errors->push_back(
        wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                    std::string("Not a regular file ") + filename_str});
    return wabt::Result::Error;
  }

  FILE *infile = fopen(filename_cstr, "rb");
  if (!infile) {
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string(strerror(errno)) +
                                      std::string(" ") + filename_str});
    return wabt::Result::Error;
  }

  if (fseek(infile, 0, SEEK_END) < 0) {
    fclose(infile);
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string("fseek to end failed")});
    return wabt::Result::Error;
  }

  long size = ftell(infile);
  if (size < 0) {
    fclose(infile);
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string("ftell failed")});
    return wabt::Result::Error;
  }

  if (fseek(infile, 0, SEEK_SET) < 0) {
    fclose(infile);
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string("fseek to beginning failed")});
    return wabt::Result::Error;
  }

  out_data->resize(size);
  if (size != 0 && fread(out_data->data(), size, 1, infile) != 1) {
    fclose(infile);
    errors->push_back(wabt::Error{wabt::ErrorLevel::Error, wabt::Location(),
                                  std::string(strerror(errno)) +
                                      std::string(" fread failed ") +
                                      filename_str});
    return wabt::Result::Error;
  }

  fclose(infile);
  return wabt::Result::Ok;
}

ERL_NIF_TERM wasm_to_wat(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary wasm_file;
  if (!enif_inspect_binary(env, argv[0], &wasm_file))
    return mk_error(env, "invalid wasm argument");

  ErlNifBinary wat_file;
  if (!enif_inspect_binary(env, argv[1], &wat_file))
    return mk_error(env, "invalid wat argument");

  wabt::InitStdio();
  wabt::Result result;
  std::vector<uint8_t> file_data;
  wabt::Features s_features;
  wabt::WriteWatOptions s_write_wat_options;
  std::string s_infile((char *)wasm_file.data, wasm_file.size);
  std::string s_outfile((char *)wat_file.data, wat_file.size);
  std::unique_ptr<wabt::FileStream> s_log_stream;

  wabt::Errors errors;
  result = read_file(s_infile.c_str(), &file_data, &errors);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::Module module;
  const bool s_read_debug_names = true;
  const bool kStopOnFirstError = true;
  const bool s_fail_on_custom_section_error = true;
  wabt::ReadBinaryOptions options(s_features, s_log_stream.get(),
                                  s_read_debug_names, kStopOnFirstError,
                                  s_fail_on_custom_section_error);
  result = wabt::ReadBinaryIr(s_infile.c_str(), file_data.data(),
                              file_data.size(), options, &errors, &module);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::ValidateOptions val_options(s_features);
  result = wabt::ValidateModule(&module, &errors, val_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  wabt::FileStream stream(!s_outfile.empty() ? wabt::FileStream(s_outfile)
                                             : wabt::FileStream(stdout));
  result = wabt::WriteWat(&stream, &module, s_write_wat_options);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  return enif_make_atom(env, "ok");
}

ERL_NIF_TERM wat_to_wasm(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {

  ErlNifBinary wat_file;
  if (!enif_inspect_binary(env, argv[0], &wat_file))
    return mk_error(env, "invalid wat argument");

  ErlNifBinary wasm_file;
  if (!enif_inspect_binary(env, argv[1], &wasm_file))
    return mk_error(env, "invalid wasm argument");

  wabt::InitStdio();
  wabt::Result result;
  std::vector<uint8_t> file_data;
  std::string s_infile((char *)wat_file.data, wat_file.size);
  std::string s_outfile((char *)wasm_file.data, wasm_file.size);
  std::unique_ptr<wabt::FileStream> s_log_stream;
  wabt::WriteBinaryOptions s_write_binary_options;

  wabt::Errors errors;
  result = read_file(s_infile.c_str(), &file_data, &errors);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  std::unique_ptr<wabt::WastLexer> lexer = wabt::WastLexer::CreateBufferLexer(
      s_infile, file_data.data(), file_data.size());

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

  result =
      WriteBufferToFile(s_outfile.c_str(), stream.output_buffer(), &errors);

  if (wabt::Failed(result)) {
    return mk_error(env, errors.at(0).message);
  }

  return enif_make_atom(env, "ok");
}

ErlNifFunc nif_funcs[] = {
    {"wasm_to_wat", 2, wasm_to_wat, 0},
    {"wat_to_wasm", 2, wat_to_wasm, 0},
};

ERL_NIF_INIT(Elixir.Wabt.Native, nif_funcs, load, NULL, NULL, unload);
