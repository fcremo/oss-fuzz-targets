CC       = afl-clang-fast
CFLAGS   = -g -fsanitize=array-bounds,null,return,shift -fsanitize-coverage=trace-pc-guard -I.

CXX      = afl-clang-fast++
CXXFLAGS = $(CFLAGS) -std=c++11

LDFLAGS  = -L.
LDLIBS   = -lwolfssl

PYTHON   = python2

prefix   = ./out

src     = $(wildcard ./*/target.c)
opt     = $(wildcard ./*/target.options)
trg     = $(notdir $(src:/target.c=))
trg_opt = $(notdir $(opt:/target.options=))
obj     = $(src:.c=.o)
out     = $(src:.c=)

targets   = $(patsubst %,$(prefix)/%,                $(trg))
corpora   = $(patsubst %,$(prefix)/%_seed_corpus.zip,$(trg))
optionses = $(patsubst %,$(prefix)/%.options,        $(trg_opt))

found_dictionaries = $(wildcard ./*.dict)
dictionaries = $(addprefix $(prefix)/,$(notdir $(found_dictionaries)))

exports = $(targets) $(corpora) $(optionses) $(dictionaries)

all: $(out)                     # make all
export: $(prefix) $(exports)    # not quite install, but close
deps: $(CC) $(CXX) $(libFuzzer) # dependencies
dependencies: deps              # deps alias
%: %.c                          # cancel the implicit rule
%: %.cc                         # cancel the implicit rule

.PHONY: clean spotless export unexport
.INTERMEDIATE: $(obj)

# actual source code

$(obj): %.o: %.c
	@echo "CC	$<	-o $@"
	@$(CC) -c $< $(CFLAGS) -o $@

$(out): %: %.o
	@echo "C++	$<	-o $@"
	@$(CXX) $< $(CXXFLAGS) $(LDFLAGS) $(LDLIBS) -o $@

# export

$(prefix):
	@mkdir -p $(prefix)

$(corpora): $(prefix)/%_seed_corpus.zip: ./%
	@find $</* -maxdepth 0 -type d \
	    -printf "zip\t$@\t%f\n" \
	    -exec zip -q -r $@ {} +

$(optionses): $(prefix)/%.options: ./%/target.options
	@echo "cp	$<	$@"
	@cp $< $@

$(targets): $(prefix)/%: ./%/target
	@echo "cp	$<	$@"
	@cp $< $@

$(dictionaries): $(prefix)/%: ./%
	@echo "cp	$<	$@"
	@cp $< $@

# cleanup

clean:
	@rm -f $(out)
	@echo "Cleaned!"
spotless:
	@rm -rf $(fuzzer_dir) $(libFuzzer) $(new_clang) $(CC) $(CXX) $(out)
	@echo "Cleaned harder!"
unexport:
	@rm -rf $(prefix)/*
	@echo "Un-exported!"
