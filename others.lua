m = Map(nil, "その他の設定") -- 設定ファイルに依存しない

s = m:section(TypedSection, "others_section", "セクションの説明")
s.addremove = false -- セクションの追加と削除を不可に
s.anonymous = true -- 名前のないセクションを許可

o = s:option(Value, "example_option", "例のオプション", "このオプションの説明。")
o.datatype = "string" -- 入力値の型を指定
o.default = "デフォルト値" -- デフォルト値の設定

function m.on_commit(map)
    -- ここにフォーム送信時の処理を記述
end

return m
