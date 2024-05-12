This repo contains an attempt (not very impressive, so far) to deconstruct the [Snowball stemmers](https://snowballstem.org/) using Ruby.

The goals of the investigation were:

1. understand better how the stemmers work;
2. understand better Snowball programming language;
3. experiment with a different DSL/language to describe such algorithms.

I used Ruby as my primary "tool of thinking," and while goals (1) and (2) were successfully met, I am not impressed with my own attempts towards goal (3), and starting to think that it is not something that should be approached the way I did.

Anyway, publishing the (intermediate?) result here for posterity.

Contents of the repo:

* `sbl/`: original stemmers in Snowball language;
* `data/`: stemmer-testing data from the [snowball-data](https://github.com/snowballstem/snowball-data) repo;
* `ruby/`: code of stemmers ported to Ruby:
  * `english_naive.rb`: very straitforward word-by-word port, mostly for my own understanding that I learned to read Snowball algorithms correctly;
  * `english_clean.rb` and `ukrainian_clean.rb`: DSL-y ports (no cool metaprogramming, just several helper methods to try and express the algorithm declartively);
  * `base.rb`: those base methods/DSL definitions;
* `test/`: code for testing ports; super-naive scripts that are used like this:
  * `ruby test/test_word.rb ruby/english_clean.rb international`: treats the first argument as a path to a stemmer implementaiton, and the second as a word to stem, runs stemming in debug mode (with output of intermediate steps)
  * `ruby test/test_dictionary.rb ruby/english_clean.rb`: full-dictionary test, guesses the test data by the script name, and takes from `data/<lang_name>/voc.txt` (input words) and `output.txt` (expected stemmings), writes output to `test/out/<lang>_<algo>.txt`
