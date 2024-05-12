require_relative './base'

class Stemmer < Base
  VOWEL = 'аеєиіїоуюя'

  def stem
    prelude

    mark_regions

    # Any Regexp searches should be performed only in this region
    @start = first_vowel

    case word.length
    when ...4 then return
    when 4 then short_word_4l
    when 5 then short_word_5l
    when 6.. then long_word
    end and
      tidy_up
  end

  private

  attr_reader :first_vowel, :second_syllable

  def prelude
    word.tr!('ґ', 'г')
  end

  def mark_regions
    @first_vowel = word.length
    @second_syllable = word.length

    m = word.match(/^.*?[#{VOWEL}]/) or return
    @first_vowel = m.end

    m = word.match(/[^#{VOWEL}].*?[#{VOWEL}].*?[^#{VOWEL}]/, first_vowel) or return
    @second_syllable = m.end
  end

  step def short_word_4l
    remove_last_2_vowels or remove_last_vowel
  end

  step def short_word_5l
    remove_last_2_vowels or remove_last_vowel or remove_last_2_letters
    remove_last_vowel
    true # always proceed to the next (tidy-up) stage for the long word
  end

  step def long_word
    perfective_gerund or (
      reflexive

      long_endings or adjectival or verb or noun or remove_last_letter
    )
    derivational
    remove_last_2_vowels
    remove_last_vowel

    true # always proceed to the next (tidy-up) stage for the long word
  end

  step def perfective_gerund
    remove_suffix_list(%w[вши вшись вшися учи ючи ючись ючися ачи ачись ачися лячи лячись лячися ячи ячись ячися])
  end

  step def reflexive
    # ється: "смі|ється"
    remove_suffix_list(%w[ється еться ся сь])
  end

  step def long_endings
    remove_suffix_list(
      # nouns
      %w[ість істю істи істе істського
         енами
         очки очці очку очкою очка
         очко очок очкам очками очках
         ості ости осте остей остям остями остях
         ником никові нику ників ника никам никами никах ники
         ців цями
         ків] +
         # female gender
         %w[кою кам ками ках
            ською ська ську сько])
  end

  step def adjective
    remove_suffix_list(
      %w[ий ого ому им ім
         іший ішого ішому ішим ішім іше іш
         ої ій ою
         іша ішої ішій ішу ішою
         их ими
         ний на не ним нім ної ну ною ній  них ні ник но ного ними ному
         іші іших ішими
         ього ьому
         ьої ьою
         іх іми
         ова ове во
         їй иїй
         йому ийому
         єє еє
         ен ена ені ене ену енам ени енів еном
         яча яче ячу ячі
         ача аче ачу ачі
         юча юче ючу ючі
         уча уче учу учі]
    )
  end

  step def adjectival
    # return true -- we handled it as "adjectival" -- even if the second replacement wasn't there
    adjective and (remove_suffix_list(%w[ен ов яч ач юч уч]); true)
  end

  step def verb
    remove_suffix_list(
      %w[ав али ало ала ать ати
         іть
         йте ймо
         ме
         ла ло ли лу
         но
         єш ємо єте ють
         еш емо ете уть
         лю иш ить имо ите лять ши
         ляти
         їш їть їмо їте ять яти]
    )
  end

  step def noun
    remove_suffix_list(
      %w[ам ами ах
         ар арем аря
         ею
         ям ями ях
         ові ом
         ець ем
         ень
         ой
         ію ії
         ів
         ев ов ей иям иях ию
         іям іях ія
         ия єю еві єм еїв їв
         ією иєю еєю
         ка ки ці ку ко ок
         ьї ьє ьєю ью ья]
    )
  end

  step def remove_last_letter
    remove_suffix_list(
      %w[а в е є и і ї] + # NOUN: вод|а, VERB: вчи|в
      %w[й о у ь ю я]
    )
  end

  step def remove_last_2_letters # 2-letters from the all previous sets
    remove_suffix_list(
      %w[ав ам ар ах ач
         ев еє ей ем ен еш ею
         єє єм єш єю
         ий им их иш ию ия
         ів їв ії ій їй ім іх ію
         їш] +
         %w[ла ли ло лю] + # аку|лі ?
         %w[ме] + # дія|ми ?
         %w[ов ої ой ом ою сь ся
         уч
         ьє ьї ью ья
         юч
         ям ях яч]
    )
  end

  step def remove_last_vowel
    remove_suffix(/[#{VOWEL}йь]/)
  end

  step def remove_last_2_vowels
    remove_suffix(/[#{VOWEL}йь][#{VOWEL}йь]/)
  end

  step def derivational
    remove_suffix_list(%w[іст ост ень еньк ськ ізм], after: second_syllable)
  end

  # Remove a double-letter, if it is one of the following
  step def tidy_up
    # Base#sub! doesn't work with replacement \1 in "after" context
    word.sub!(/([бвгджзклмнпрстфцчш])\1$/, '\1')
  end

  # More services
  def replace_suffix_list(endings, replacement, **)
    replace_suffix("(#{endings.join('|')})", replacement, **)
  end

  def remove_suffix_list(endings, **)
    replace_suffix_list(endings, '', **)
  end
end
