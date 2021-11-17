BOOK_NAME := istio-handbook
BOOK_OUTPUT := _book
image := xcbeyond/gitbook-builder:latest
docker := docker run --rm -v $(shell pwd):/gitbook -w /gitbook -p 4000:4000 $(image)

.PHONY: build
build:
	@$(docker) gitbook build
	sudo cp favicon.ico $(BOOK_OUTPUT)/gitbook/images

.PHONY: install
install:
	@$(docker) gitbook install

.PHONY: serve
serve:
	@$(docker) gitbook serve .

.PHONY: epub
epub:
	@$(docker) gitbook epub . $(BOOK_NAME).epub

.PHONY: pdf
pdf:
	@$(docker) gitbook pdf . $(BOOK_NAME).pdf

.PHONY: mobi
mobi:
	@$(docker) gitbook mobi . $(BOOK_NAME).mobi

.PHONY: clean
clean:
	rm -rf $(BOOK_OUTPUT)

.PHONY: help
help:
	@echo "Help for make"
	@echo "make          - Build the book"
	@echo "make build    - Build the book"
	@echo "make serve    - Serving the book on localhost:4000"
	@echo "make install  - Install gitbook and plugins"
	@echo "make epub     - Build epub book"
	@echo "make pdf      - Build pdf book"
	@echo "make clean    - Remove generated files"