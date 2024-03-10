require_relative './base'

class Stemmer < Base
  VOWEL = 'аеєиіїоуюя'

  def stem
    prelude

    mark_regions

    @after = first_vowel

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
    del_list!(%w[вши вшись вшися учи ючи ючись ючися ачи ачись ачися лячи лячись лячися ячи ячись ячися])
  end

  step def reflexive
    # Here and below: we need two calls in some cases, because `sub!` is checking `after:` when
    # regexp is already matched.
    # By snowballs original logic: "ється" matched, but not it a valid region => then it is not
    # a match, try to match "ся", so we need to double-check.
    del_list!(%w[ється еться]) or del_list!(%w[ся сь])
  end

  step def long_endings
    del_list!(%w[ість істю істи істе істського
                 енами
                 очки очці очку очкою очка
                 очко очок очкам очками очках
                 ості ости осте остей остям остями остях
                 ником никові нику ників ника никам никами никах ники
                 ців цями
                 ків]) or
      # female gender
      del_list!(%w[кою кам ками ках
                   ською ська ську сько])
  end

  step def adjective
    del_list!(%w[ий ого ому им ім
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
                 уча уче учу учі]) or
      del_list!(%w[их ими ої ій ою ий ого ому им ім ну])
  end

  step def adjectival
    # return true -- we handled it as "adjectival" -- even if the second replacement wasn't there
    adjective and (del_list!(%w[ен ов яч ач юч уч]); true)
  end

  step def verb
    del_list!(%w[ав али ало ала ать ати
                іть
                йте ймо
                ме
                ла ло ли лу
                но
                єш ємо єте ють
                еш емо ете уть
                лю иш ить имо ите лять ши
                ляти
                їш їть їмо їте ять яти]) or
    # Otherwise, in some cases it matches "ала", but it is before our "after:" and it fails without
    # retrying. Reason is naivete of `sub!` implementation via Ruby's regexp post-processing
    del_list!(%w[ла ло ли])
  end

  step def noun
    del_list!(%w[ам ами ах
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
                 ьї ьє ьєю ью ья])
  end

  step def remove_last_letter
    del_list!(%w[а в е є и і ї] + # NOUN: вод|а, VERB: вчи|в
              %w[й о у ь ю я])
  end

  step def remove_last_2_letters # 2-letters from the all previous sets
    del_list!(%w[ав ам ар ах ач
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
              ям ях яч])
  end

  step def remove_last_vowel
    del!(/[#{VOWEL}йь]/)
  end

  step def remove_last_2_vowels
    del!(/[#{VOWEL}йь][#{VOWEL}йь]/)
  end

  step def derivational
    del_list!(%w[іст ост ень еньк ськ ізм], after: second_syllable)
  end

  # Remove a double-letter, if it is one of the following
  step def tidy_up
    # Base#sub! doesn't work with replacement \1 in "after" context
    word.sub!(/([бвгджзклмнпрстфцчш])\1$/, '\1')
  end

  def sub_list!(endings, replacement, **)
    sub!("(#{endings.join('|')})", replacement, **)
  end

  def del_list!(endings, **)
    sub_list!(endings, '', **)
  end
end
