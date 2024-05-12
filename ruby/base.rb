# Because Ruby's native Regex MatchData is somewhat lacking in its API
class MatchData
  alias _begin begin
  alias _end end

  def begin(idx = 0) = _begin(idx)
  def end(idx = 0) = _end(idx)

  def match_before?(pattern) = pre_match.match?(pattern)
end

class Base
  def self.stem(word, debug: false) = new(word, debug:).tap(&:stem).word

  def initialize(word, debug: false)
    @word = word.dup
    @debug = debug
    @start = 0
  end

  attr_reader :word

  private

  def debug? = @debug

  # Service functions/micro-DSL

  # Replace `pattern` _at the end of the word_ with `replacement` (or pass it to `block`).
  # Returns truthy value if the replacement was made (pattern was found), falsy otherwise.
  #
  # If `after:` is provided, the truthy value & the replacement only happens if the found pattern
  # is after the specified position in the word.
  def replace_suffix(pattern, replacement = nil, after: nil, &block)
    # @start vs after:
    #   start sets the search scope; after checks post-match
    # e.g. if we have a pattern "ement|ment|ent" => "", and the word "agreement", then:
    #  * setting start to 5: "ent" will be found (in the search scope after "agreem") and removed
    #  * setting after to 5: "ement" will be found, but would not match after: condition, and nothing will be changed
    m = word.match(/#{pattern}$/, @start) or return

    after && m.begin < after and return

    replacement = block.call(m) if block
    word[m.begin..m.end] = replacement.to_s
  end

  # Remove the specified pattern at the end of the word.
  def remove_suffix(pattern, **)
    replace_suffix(pattern, '', **)
  end

  # Return true (which potentially stops the chain of `or`-s) if the word has this suffix
  def keep_suffix(pattern)
    word.match?(/#{pattern}$/)
  end

  # Accepts a {pattern => replacement} hash, finds the first matching pattern, and replaces it with
  # the replacement.
  # If `after:` is provided, and the pattern found is starting before that point, the pattern
  # still considered found (not looking into other patterns), but replacement is not made.
  #
  def replace_suffixes(patterns, after: nil)
    # Construct an alternate regexp of all patterns, where each one will have its own capture group
    regexp = patterns.keys.map { "(#{_1})" }.join('|').then { /(?:#{_1})/ }

    # by the index of capture group that is not nil, guess which replacement should be used
    replace_suffix(regexp, after:) { patterns.values[_1.captures.find_index(&:itself)] }
  end

  # Annotate method to be a formal "step" of the algorithm. This changes the method's behavior only
  # in debug mode, by printing the current word before and after the step.
  def self.step(name)
    alias_method "_#{name}", name
    define_method(name) {
      puts "before #{name}: #{word}" if debug?
      send("_#{name}")
        .tap { puts "after #{name}: => #{word}" if debug? }
    }
  end
end
