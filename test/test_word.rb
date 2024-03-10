name = ARGV.shift
word = ARGV.shift

load name

stem = Stemmer.stem(word, debug: true)

puts

puts "#{word} => #{stem}"
