m = Map("others", "その他の設定") -- "others"は設定ファイル名（/etc/config/othersに対応）、"その他の設定"はこのセクションのタイトルです。

s = m:section(TypedSection, "others_section", "セクションの説明")
s.addremove = true -- セクションの追加と削除を許可
s.anonymous = true -- 名前のないセクションを許可

o = s:option(Value, "example_option", "例のオプション", "このオプションの説明。")
o.datatype = "string" -- 入力値の型を指定
o.default = "デフォルト値" -- デフォルト値の設定

return m
