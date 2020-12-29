MIX = mix
CFLAGS = -g -O3 -std=c++11 -pedantic -Wall -Wextra -Wno-unused-parameter

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC

	ifeq ($(shell uname),Darwin)
		LDFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
endif

LDFLAGS += -Iwabt/
LDFLAGS += -Inative/include/
LDFLAGS += -Iwabt/build/
LDFLAGS += -I$(ERLANG_PATH)
LDFLAGS += -lwabt

.PHONY: all build clean

all: build

build:
	$(MIX) compile

priv/native.so:
	$(CXX) $(CFLAGS) -shared $(LDFLAGS) -o $@ native/lib.cpp -L .


clean:
	$(MIX) clean
	$(RM) priv/native.so
