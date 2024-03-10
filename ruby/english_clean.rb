require_relative './base'

# An attempt to develop some kind of idiomatic DSL out of naive port of English snowball algorithm.
# * A few main methods, `sub/`, `multisub!` and `del!` are extracted
#   (moved to the the Base class to reuse in other algorithms)
# * Regions are renamed from R1/R2 to (somewhat figuratively) "one syllable"/"two syllables"
# * Each "step" attempted to make into one mostly-declarative statement of what it does.
class Stemmer < Base
  VOWEL = 'aeiouy'
  SHORT_SYLLABLE = "([^#{VOWEL}][#{VOWEL}][^#{VOWEL}wxY]|^[#{VOWEL}][^#{VOWEL}])$"

  def stem
    return if exception1 # handle specially-stemmed words, and return if it was one of them
    return if word.length < 3

    # introduces distinction of two "y" usages, replacing the consonant-sounding "y" with "Y",
    # to distinguish in further algorithms
    prelude

    # remembers marks of the end of the first and second syllable of the word
    # (there are some nuances, see the method)
    mark_regions

    # remove/replace endings like "s", "'s", "ied"/"ies"
    step_1a

    unless exception2? # avoid processing several explicit exceptional words
      # Handles verb-like endings:
      # removes endings like "ed(ly)", "ing",
      # and if they were there, makes other replacement (like "analized" => "analiz" => "analize")
      step_1b

      # replaces "-y" ending with "-i" for unification
      step_1c

      # shortens long endings, like "-fullnes" => "-ful", "-iviti" => "-ive"
      step_2
      # one more set of long endings to shorten, like "-ational" => "-ate"
      step_3
      # removes a list of endings like "-able", "-ment", "-ism"
      step_4

      # handles final "-e" and final "-ll"
      step_5
    end

    # Returns back all "Y" (introduced in prelude) to "y"
    postlude
  end

  private

  step def exception1
    multisub!({
      # special changes:
      '^skis' =>  'ski',
      '^skies' => 'sky',
      '^dying' => 'die',
      '^lying' => 'lie',
      '^tying' => 'tie',

      # special -LY cases

      '^idly'   => 'idl',
      '^gently' => 'gentl',
      '^ugly'   => 'ugli',
      '^early'  => 'earli',
      '^only'   => 'onli',
      '^singly' => 'singl'
    }) or

    [
      # invariant forms:
      'sky',
      'news',
      'howe',

      # not plural forms
      'atlas', 'cosmos', 'bias', 'andes'
    ].include?(word)
  end

  step def prelude
    @y_found = false
    word.sub!(/^'/, '')
    word.sub!(/^y/, 'Y') and @y_found = true
    word.gsub!(/(?<=[#{VOWEL}])y/, 'Y') and @y_found = true
  end

  step def postlude
    # NB: Actually, `if` is not that necessary, there wouldn't be any Y if it wasn't found previously
    word.tr!('Y', 'y') if @y_found
  end

  # Put marks where the first syllable ends, and where the second ends.
  # The "syllables" here are not grammatically precise, but what is practical for the purpose of
  # the algorithm:
  # * first syllable is the first consonant after a vowel (or, some longer exceptional word parts
  #   to consider unsplittable syllables);
  # * second sylable is the next consonant after the next vowel
  # * the marks is set at the end of the word if corresponding conditions aren't met.
  def mark_regions
    @one_syllable = word.length
    @two_syllables = word.length

    m = word.match(/((^(gener|commun|arsen))|[#{VOWEL}].*?[^#{VOWEL}])/) or return
    @one_syllable = m.end

    m = word.match(/[#{VOWEL}].*?[^#{VOWEL}]/, one_syllable)) or return
    @two_syllables = m.end
  end

  attr_reader :one_syllable, :two_syllables

  # remove "'s'" / "'s" / "'"
  #
  # replace endings:
  #  "sses" => "ss"
  #  "ied"/"ies" => if the rest of the word longer than 2 "i", otherwise "ie"
  #  "us" / "ss" => keep
  #  "s" => remove if there is any vowel not directly before it
  step def step_1a
    del!(/('s'|'s|')/)

    sub!(/sses/, 'ss') or
      sub!(/(ied|ies)/) { _1.begin >= 2 ? 'i' : 'ie' } or
      word.match?(/(us|ss)$/) or # do nothing but stop singular "s" from being stripped
      sub!(/s/) { _1.pre_match.match?(/[#{VOWEL}]./) ? '' : _1 }
  end

  def exception2?
    word.match?(/^(inning|outing|canning|herring|earring|proceed|exceed|succeed)$/)
  end

  # handle words that are likely produced from verb:
  # "-ed/-ing(-ly)" endings
  # add "-e" where ending was removed if necessary
  # remove duplicated consonant before removed ending if necessary
  step def step_1b
    # if the word too short to replace eed/eedly, but it is there, the check is still successful
    sub!(/(eed|eedly)/) { _1.pre_match.length >= one_syllable ? 'ee' : _1 } or

    sub!(/(ed|edly|ing|ingly)/) {
      _1.pre_match.match?(/[#{VOWEL}]/) or break # skip replacement, return nil = stop handling
      '' # make replacement, returns the word
    } and # if the removal of the verb-like ending was made...
      (sub!(/(?<=at|bl|iz)/, 'e') or
       sub!(/(?<!^[aeo])(bb|dd|ff|gg|mm|nn|pp|rr|tt)/) { _1.to_s[0] } or
       (word.length == one_syllable && word.match?(/#{SHORT_SYLLABLE}/) and word << 'e'))
  end

  # replace "y"=>"i" if it is after a consonant and the word have at least one more character
  step def step_1c
    sub!(/(?<=.[^#{VOWEL}])[yY]/, 'i')
  end

  # replace these endings if they are after the first syllable
  # (note that the last "i" have emerged on step_1c)
  step def step_2
    multisub!({
      'enci'    => 'ence',
      'anci'    => 'ance',
      'abli'    => 'able',
      'entli'   => 'ent',
      'izer|ization' => 'ize',
      'ational|ation|ator' => 'ate',
      'tional'  => 'tion',
      'alism|aliti|alli' => 'al',
      'fulness' => 'ful',
      'ousli|ousness' => 'ous',
      'iveness|iviti' => 'ive',
      'biliti|bli' => 'ble',
      'fulli'   => 'ful',
      'lessli'  => 'less',
      '(?<=l)ogi' => 'og',
      '(?<=[cdeghkmnrt])li' => ''
    }, after: one_syllable)
  end

  # replace those endings after one or two syllables
  # Note that some endings are repeating from above: there could be two stages of removal:
  # internationally => ... => international[li] (step 2) => intern[ational] (step 3)
  step def step_3
    multisub!({
     'ational'=> 'ate',
     'tional' => 'tion',
     'alize' => 'al',
     'icate|iciti|ical' => 'ic',
     'ful|ness' => ''
    }, after: one_syllable) or del!(/ative/, after: two_syllables)
  end

  # remove those endings after the two syllables
  step def step_4
    del!(/(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ism|ate|iti|ous|ive|ize|(?<=[st])ion)/,
         after: two_syllables)
  end

  # remove final "e" if it is after two syllables, OR, after one syllable and that syllable is not short
  # ...or, deduplicate last "l" but only after two syllables
  step def step_5
    sub!(/e/) {
      if _1.begin >= two_syllables || _1.begin >= one_syllable && !_1.pre_match.match?(/#{SHORT_SYLLABLE}/)
        ''
      else
        _1
      end
    } or del!(/(?<=l)l/, after: two_syllables)
  end
end
