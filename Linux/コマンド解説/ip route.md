
---

## 1. ルーティングテーブルの表示（よく使う）
### 現在のルート一覧
```bash
ip route
```
または同義：
```bash
ip r
```

出力例（代表的な形）：
```text
default via 192.168.1.1 dev ens160 proto dhcp metric 100
192.168.1.0/24 dev ens160 proto kernel scope link src 192.168.1.10 metric 100
```

#### よく出る項目の意味
- `default`：デフォルトルート（宛先がどの経路にも一致しない場合の出口）
- `via 192.168.1.1`：次ホップ（ゲートウェイ）
- `dev ens160`：利用するインターフェース
- `proto`：ルートが作られた由来  
  - `kernel`：インターフェースのIP設定により自動生成  
  - `dhcp`：DHCPにより設定  
  - `static`：手動（静的）設定など
- `metric`：優先度（小さいほど優先されることが多い）
- `scope link`：直結ネットワーク（そのインターフェース上で到達可能）
- `src`：その経路を使う際の送信元IPの候補

---

## 2. 特定宛先への「実際に使われる経路」を確認（最重要）
「この宛先に送るとき、どの経路・IF・送信元IPになるか」を確認できる。

```bash
ip route get 8.8.8.8
```

出力例：
```text
8.8.8.8 via 192.168.1.1 dev ens160 src 192.168.1.10 uid 0
```

確認できること：
- `via`：使うゲートウェイ
- `dev`：出ていくNIC
- `src`：OSが選ぶ送信元IP

ルーティングが意図通りか調べるとき、`ip route`表示よりも確実。

---

## 3. ルートの追加（手動・一時的）
### (1) デフォルトゲートウェイを追加
```bash
sudo ip route add default via 192.168.1.1 dev ens160
```

### (2) 特定ネットワーク宛のルートを追加
```bash
sudo ip route add 10.0.0.0/24 via 192.168.1.254 dev ens160
```

### (3) 直結（ゲートウェイなし）として追加（通常は自動で入る）
```bash
sudo ip route add 10.0.0.0/24 dev ens160
```

### (4) 優先度（メトリック）付きで追加
```bash
sudo ip route add default via 192.168.1.1 dev ens160 metric 200
```
※同じ宛先（例：default）が複数ある場合、一般にmetricが小さい方が優先。

---

## 4. ルートの削除
### デフォルトルートを削除
```bash
sudo ip route del default
```
（複数ある場合は`via`や`dev`も指定して正確に）
```bash
sudo ip route del default via 192.168.1.1 dev ens160
```

### 特定ネットワーク宛を削除
```bash
sudo ip route del 10.0.0.0/24
```

---

## 5. ルートの変更（replace / change）
### 置き換え（無ければ追加・あれば置換）
```bash
sudo ip route replace default via 192.168.1.1 dev ens160
```

### 変更（対象が存在する前提）
```bash
sudo ip route change default via 192.168.1.1 dev ens160
```

運用上は「安全に上書きできる」`replace`が使われやすい。

---

## 6. テーブル（複数ルーティングテーブル）を扱う基本
通常は「main」テーブルを見る。

### mainテーブルを見る
```bash
ip route show table main
```

### 全テーブルをざっと見る
```bash
ip route show table all
```

特定テーブルに追加：
```bash
sudo ip route add 10.10.0.0/16 via 192.168.1.254 table 100
```
※ポリシールーティング（送信元やFWマークでテーブルを切り替える）で使用。

---

## 7. 注意点（RHELで重要）
- `ip route add/del/...` で変更した内容は基本的に「再起動・ネットワーク再起動で消える」（一時的）。
- 永続化したい場合は、RHELのネットワーク設定（例：NetworkManagerの接続設定）側にルートを定義する必要がある。

---

## よく使うコマンドまとめ
```bash
ip r                  # ルート一覧
ip route get <IP>     # 実際に選ばれる経路確認
sudo ip route add ... # 追加（一時的）
sudo ip route del ... # 削除（一時的）
sudo ip route replace ... # 置換（一時的）
```

