# Because Ruby's native Regex MatchData is somewhat lacking in its API
class MatchData
  alias _begin begin
  alias _end end

  def begin(idx = 0) = _begin(idx)
  def end(idx = 0) = _end(idx)
end

class Base
  def self.stem(word, debug: false) = new(word, debug:).tap(&:stem).word

  def initialize(word, debug: false)
    @word = word.dup
    @debug = debug
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
  def sub!(pattern, replacement = nil, after: @after, &block)
    pattern = /#{pattern}$/
    if replacement
      if after
        word.sub!(pattern) {
          break if Regexp.last_match.begin < after # don't replace & return `nil`, so next replacement can be chained
          replacement
        }
      else
        word.sub!(pattern, replacement)
      end
    else
      word.sub!(pattern) { block.call(Regexp.last_match) }
    end
  end

  # Remove the specified pattern at the end of the word.
  def del!(pattern, **)
    sub!(pattern, '', **)
  end

  # Accepts a {pattern => replacement} hash, finds the first matching pattern, and replaces it with
  # the replacement.
  # If `after:` is provided, and the pattern found is starting before that point, the pattern
  # still considered found (not looking into other patterns), but replacement is not made.
  #
  def multisub!(patterns, after: nil)
    # Construct an alternate regexp of all patterns, where each one will have its own capture group
    regexp = patterns.keys.map { "(#{_1})" }.join('|').then { /(?:#{_1})/ }

    sub!(regexp) {
      break if after && _1.begin < after

      # by the index of capture group that is not nil, guess which replacement should be used
      patterns.values[_1.captures.find_index(&:itself)]
    }
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
