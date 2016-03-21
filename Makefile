PROJECT = lhc
ROOT_DIR = $(shell pwd)
REPO = $(shell git config --get remote.origin.url)
LFE = _build/default/lib/lfe/bin/lfe
DOCS_DIR = $(ROOT_DIR)/docs
DOCS_PROD_DIR = $(DOCS_DIR)/master
API_PROD_DIR = $(DOCS_PROD_DIR)/current/api
DOCS_GIT_HACK = $(DOCS_DIR)/.git
LOCAL_DOCS_HOST = localhost
LOCAL_DOCS_PORT = 5099

compile:
	rebar3 compile

check:
	@rebar3 as test eunit

repl: compile
	@$(LFE)

shell:
	@rebar3 shell

clean:
	@rebar3 clean
	@rm -rf ebin/* _build/*/lib/$(PROJECT)

clean-all: clean
	@rebar3 as dev lfe clean

$(DOCS_GIT_HACK):
	@ln -s $(ROOT_DIR)/.git $(DOCS_DIR)

docs-setup:
	@echo "\nInstalling and setting up dependencies ..."
	@cd $(DOCS_DIR) && bundle install

docs-clean:
	@echo "\nCleaning build directories ..."
	@rm -rf $(API_PROD_DIR)

docs-lodox:
	@echo
	@rebar3 lfe lodox

docs: clean compile docs-clean $(DOCS_GIT_HACK)
	@echo "\nBuilding docs ...\n"
	@make docs-lodox

devdocs: docs
	@echo
	@echo "Running docs server on http://$(LOCAL_DOCS_HOST):$(LOCAL_DOCS_PORT) ... (To quit, hit ^c twice)"
	@echo
	@erl -s inets -noshell -eval 'inets:start(httpd,[{server_name,"devdocs"},{document_root, "$(DOCS_PROD_DIR)"},{server_root, "$(DOCS_PROD_DIR)"},{port, $(LOCAL_DOCS_PORT)},{mime_types,[{"html","text/html"},{"htm","text/html"},{"js","text/javascript"},{"css","text/css"},{"gif","image/gif"},{"jpg","image/jpeg"},{"jpeg","image/jpeg"},{"png","image/png"}]}]).'

setup-temp-repo: $(DOCS_GIT_HACK)
	@echo "\nSetting up temporary git repos for gh-pages ...\n"
	@rm -rf $(DOCS_PROD_DIR)/.git $(DOCS_PROD_DIR)/*/.git
	@cd $(DOCS_PROD_DIR) && git init
	@cd $(DOCS_PROD_DIR) && git add * > /dev/null
	@cd $(DOCS_PROD_DIR) && git commit -a -m "Generated content." > /dev/null

teardown-temp-repo:
	@echo "\nTearing down temporary gh-pages repos ..."
	@rm $(DOCS_DIR)/.git
	@rm -rf $(DOCS_PROD_DIR)/.git $(DOCS_PROD_DIR)/*/.git

publish-docs: docs setup-temp-repo
	@echo "\nPublishing docs ...\n"
	@cd $(DOCS_PROD_DIR) && git push -f $(REPO) master:gh-pages
	@make teardown-temp-repo

.PHONY: docs

