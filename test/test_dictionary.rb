name = ARGV.shift

load name

name.match(%r{ruby/(.+)_(.+)\.rb}) => lang, variety

voc = File.readlines("data/#{lang}/voc.txt", chomp: true)
out = File.readlines("data/#{lang}/output.txt", chomp: true)

t = Time.now

compare = voc.zip(out)
  .tap { puts "Checking: #{_1.count}" }
  .map { [_1, _2, Stemmer.stem(_1)] }
  .select { _2 != _3 }
  .tap { puts "Fails: #{_1.count}" }
  .map { _1.join(' | ') }
  .join("\n")
  .then { File.write("test/out/#{lang}_#{variety}.txt", _1) }

puts "Time: %.2fs" % (Time.now - t)

