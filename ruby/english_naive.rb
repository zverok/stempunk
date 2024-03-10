require_relative './base'

# The first and very straightforward port of english.sbl to Ruby
# Passes all the tests, though.

class Stemmer < Base
  AEO       = 'aeo'
  VOWEL     = 'aeiouy'
  VOWEL_WXY =  VOWEL + 'wxY'

  VALID_LI  = 'cdeghkmnrt'

  def exception1
    {
      # special changes:
      'skis' =>  'ski',
      'skies' => 'sky',
      'dying' => 'die',
      'lying' => 'lie',
      'tying' => 'tie',

      # special -LY cases

      'idly'   => 'idl',
      'gently' => 'gentl',
      'ugly'   => 'ugli',
      'early'  => 'earli',
      'only'   => 'onli',
      'singly' => 'singl'
    }.any? { |from, to| word.replace(to) if word == from } ||

    [
      # invariant forms:
      'sky',
      'news',
      'howe',

      # not plural forms
      'atlas', 'cosmos', 'bias', 'andes'
    ].include?(word)
  end

  def prelude
    @y_found = false
    word.sub!(/^'/, '')
    word.sub!(/^y/, 'Y') and @y_found = true
    word.gsub!(/(?<=[#{VOWEL}])y/, 'Y') and @y_found = true
  end

  def postlude
    word.tr!('Y', 'y') if @y_found
  end

  def mark_regions
    @p1 = word.length
    @p2 = word.length
    if (m = word.match(/((^(gener|commun|arsen))|[#{VOWEL}].*?[^#{VOWEL}])/))
      @p1 = m.end(0)
      if (m = word.match(/[#{VOWEL}].*?[^#{VOWEL}]/, @p1))
        @p2 = m.end(0)
      end
    end
  end

  # It is defined in "backwardmode" in the original, so all operations are frome the end of the string
  def short_syllable?(str)
    str.match?(/[^#{VOWEL}][#{VOWEL}][^#{VOWEL_WXY}]$/) ||
    str.match?(/^[#{VOWEL}][^#{VOWEL}]$/)
  end

  def step_1a
    word.sub!(/('s'|'s|')$/, '')

    word.sub!(/sses$/, 'ss') or
      word.sub!(/(ied|ies)$/) { word.length - _1.length >= 2 ? 'i' : 'ie' } or
      word.match(/(us|ss)$/) or # do nothing but stop singular "s" from being stripped
      word.sub!(/s$/) { word[0...-2].match?(/[#{VOWEL}]/) ? '' : 's' }
  end

  def exception2?
    word.match?(/^(inning|outing|canning|herring|earring|proceed|exceed|succeed)$/)
  end

  def step_1b
    word.sub!(/(eed|eedly)$/) {
      # If more than p1, replace, otherwise ignore
      word.length - _1.length >= @p1 ? 'ee' : _1
    } or word.sub!(/(ed|edly|ing|ingly)$/) {
      break unless word[...-_1.length].match?(/[#{VOWEL}]/) # skip replacement, return nil
      '' # make replacement, returns the word
    } and begin # if the previous made the replacement
      word.sub!(/(?<=at|bl|iz)$/, 'e') and return

      if word.end_with?('bb', 'dd', 'ff', 'gg', 'mm', 'nn', 'pp', 'rr', 'tt')
        word[-1] = '' unless word.match?(/^[#{AEO}]..$/)
      elsif word.length == @p1 && short_syllable?(word)
        word << 'e'
      end
    end
  end

  def step_1c
    word.sub!(/(?<=.[^#{VOWEL}])[yY]$/, 'i')
  end

  def step_2
    {
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
      "(?<=[#{VALID_LI}])li" => ''
    }.any? { |from, to| word.sub!(/(#{from})$/) { word.length - _1.length >= @p1 ? to : _1 } }
  end

  def step_3
    {
     'ational'=> 'ate',
     'tional' => 'tion',
     'alize' => 'al',
     'icate|iciti|ical' => 'ic',
     'ful|ness' => ''
    }.any? { |from, to|
      word.sub!(/(#{from})$/) { word.length - _1.length >= @p1 ? to : _1 } # stop anyway
    } or
      (word.sub!(/ative$/, '') if word.match?(/ative$/, @p2))
  end

  def step_4
    word.sub!(/(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ism|ate|iti|ous|ive|ize)$/) { word.length - _1.length >= @p2 ? '' : break } or
      word.sub!(/(?<=[st])ion$/){ word.length - _1.length >= @p2 ? '' : break }
  end

  def step_5
    if word.end_with?('e') && (word.length - 1 >= @p2 || word.length - 1 >= @p1 && !short_syllable?(word[...-1]))
      word.delete_suffix!('e')
    elsif word.length - 1 >= @p2 && word.end_with?('ll')
      word.delete_suffix!('l')
    end
  end

  def stem
    return if exception1
    return if word.length < 3

    prelude

    mark_regions

    step_1a
    d("step 1a")

    unless exception2?
      step_1b
      d("step 1b")
      step_1c
      d("step 1c")

      step_2
      d("step 2")
      step_3
      d("step 3")
      step_4
      d("step 4")

      step_5
      d("step 5")
    end

    postlude
  end

  def d(info)
    puts "#{info}: #{word}" if debug?
  end
end
