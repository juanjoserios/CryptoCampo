# Makefile - CryptoCampo

.DEFAULT_GOAL := help

FORGE ?= forge

.PHONY: help build test test-verbose gas-report fmt fmt-check snapshot clean

help:
	@echo "CryptoCampo - comandos disponibles:"
	@echo "  make build        Compilar contratos"
	@echo "  make test         Ejecutar pruebas"
	@echo "  make test-verbose Ejecutar pruebas detalladas"
	@echo "  make gas-report   Mostrar consumo de gas"
	@echo "  make fmt          Formatear Solidity"
	@echo "  make fmt-check    Comprobar formato"
	@echo "  make snapshot     Generar snapshot de gas"
	@echo "  make clean        Limpiar compilaciones"

build:
	$(FORGE) build

test:
	$(FORGE) test

test-verbose:
	$(FORGE) test -vvv

gas-report:
	$(FORGE) test --gas-report

fmt:
	$(FORGE) fmt

fmt-check:
	$(FORGE) fmt --check

snapshot:
	$(FORGE) snapshot

clean:
	$(FORGE) clean
