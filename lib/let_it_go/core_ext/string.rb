# Needs parser fixing to work
LetItGo.watch_frozen(String, :+,       positions: [0])
LetItGo.watch_frozen(String, :<<,      positions: [0])
LetItGo.watch_frozen(String, :'<=>',     positions: [0])

# Positions: 0

LetItGo.watch_frozen(String, :split,        positions: [0])
LetItGo.watch_frozen(String, :concat,       positions: [0])
LetItGo.watch_frozen(String, :casecmp,      positions: [0])
LetItGo.watch_frozen(String, :chomp,        positions: [0])
LetItGo.watch_frozen(String, :count,        positions: [0])
LetItGo.watch_frozen(String, :crypt,        positions: [0])
LetItGo.watch_frozen(String, :delete,       positions: [0])
LetItGo.watch_frozen(String, :delete!,      positions: [0])
LetItGo.watch_frozen(String, :each_line,    positions: [0])
LetItGo.watch_frozen(String, :lines,        positions: [0])
LetItGo.watch_frozen(String, :include?,     positions: [0])
LetItGo.watch_frozen(String, :index,        positions: [0])
LetItGo.watch_frozen(String, :rindex,       positions: [0])
LetItGo.watch_frozen(String, :replace,      positions: [0])
LetItGo.watch_frozen(String, :match,        positions: [0])
LetItGo.watch_frozen(String, :partition,    positions: [0])
LetItGo.watch_frozen(String, :rpartition,   positions: [0])
LetItGo.watch_frozen(String, :prepend,      positions: [0])
LetItGo.watch_frozen(String, :scan,         positions: [0])
LetItGo.watch_frozen(String, :slice,        positions: [0])
LetItGo.watch_frozen(String, :slice!,       positions: [0])
LetItGo.watch_frozen(String, :squeeze,      positions: [0])
LetItGo.watch_frozen(String, :start_with?,  positions: [0])
LetItGo.watch_frozen(String, :unpack,       positions: [0])
LetItGo.watch_frozen(String, :upto,         positions: [0])


# Positions; 0, 1

LetItGo.watch_frozen(String, :gsub,    positions: [0, 1])
LetItGo.watch_frozen(String, :gsub!,   positions: [0, 1])
LetItGo.watch_frozen(String, :sub,     positions: [0, 1])
LetItGo.watch_frozen(String, :sub!,    positions: [0, 1])
LetItGo.watch_frozen(String, :tr,      positions: [0, 1])
LetItGo.watch_frozen(String, :tr!,     positions: [0, 1])


# Positions: 1

LetItGo.watch_frozen(String, :insert,   positions: [1])
LetItGo.watch_frozen(String, :ljust,    positions: [1])
LetItGo.watch_frozen(String, :rjust,    positions: [1])
