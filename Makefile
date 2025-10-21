.PHONY: build clean test install

build:
	dune build

clean:
	dune clean

test:
	dune runtest

install: build
	dune install

dev:
	dune build -w

format:
	dune build @fmt --auto-promote

release:
	dune build --profile release
	@echo "Binaries in _build/default/bin/"
