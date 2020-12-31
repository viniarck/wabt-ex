#ifndef WABTEX_HELPERS_
#define WABTEX_HELPERS_

#include <erl_nif.h>
#include <sys/stat.h>
#include <vector>

#include "src/string-view.h"

std::vector<uint8_t> elr_binary_to_vector(const ErlNifBinary &bin) {
  std::vector<uint8_t> vec;
  for (size_t i = 0; i < bin.size; i++) {
    vec.push_back(bin.data[i]);
  }
  return vec;
}

wabt::Result WriteBufferToFile(wabt::string_view filename,
                               const wabt::OutputBuffer &buffer,
                               wabt::Errors *errors, bool dump_memory = false) {
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

#endif
