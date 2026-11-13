import io
p = r"C:\Users\Dmitriy\Downloads\F\FeatherCage\mod\FeatherCageCheats\Scripts\main.lua"
s = io.open(p, encoding="utf-8").read()
s = s.replace("\u2014", "-")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
