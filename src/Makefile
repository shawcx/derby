
COFFEE     = ./node_modules/.bin/coffee
SASS       = ./node_modules/.bin/sass
BROWSERIFY = ./node_modules/.bin/browserify

STATIC_ROOT = ../static

COFFEE_FILES := $(wildcard coffee/*.coffee)
JS_FILES     := $(patsubst coffee/%.coffee, js/%.js, $(COFFEE_FILES))
MAP_FILES    := $(patsubst %, %.map, $(JS_FILES))

JS_FILE = js/derby.js
JS_OUT  = $(STATIC_ROOT)/$(JS_FILE)

CSS_OUT = $(STATIC_ROOT)/css/derby.css
CSS_SRC = sass/derby.scss $(wildcard sass/*.scss)

SASS_FLAGS = -I ./node_modules/@fortawesome/fontawesome-pro/scss \
             -I ./node_modules/bootstrap/scss

WEBFONTS_SRC = ./node_modules/@fortawesome/fontawesome-pro/webfonts
WEBFONTS = $(STATIC_ROOT)/webfonts

all: node_modules $(JS_OUT) $(CSS_OUT) $(WEBFONTS)
	@#

$(WEBFONTS): $(WEBFONTS_SRC)
	@cp -r $(WEBFONTS_SRC) $(STATIC_ROOT)

node_modules:
	@npm install .

$(JS_OUT): $(JS_FILES)
	@echo browserify $(JS_FILE) '=>' $@
	@$(BROWSERIFY) $(JS_FILE) -o $@

js/%.js: coffee/%.coffee
	@echo coffee $< '=>' $@
	@$(COFFEE) -o `dirname $@` -b -m --no-header -c $<

$(CSS_OUT): $(CSS_SRC)
	@echo sass $< '=>' $@
	@$(SASS) $(SASS_FLAGS) $< $@

clean:
	@rm -f $(JS_FILES)
	@rm -f $(MAP_FILES)

distclean: clean
	@rm -f $(CSS_OUT)
	@rm -f $(JS_FILE)
