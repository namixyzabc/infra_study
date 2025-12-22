
## 基本的な出力例

```bash
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.100  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::a1b2:c3d4:e5f6:7890  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:3a:2b:1c  txqueuelen 1000  (Ethernet)
        RX packets 12345  bytes 1234567 (1.1 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 6789  bytes 678901 (663.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

## 各項目の意味

### **1行目：インターフェース名と状態**
- **eth0** - ネットワークインターフェース名
- **UP** - インターフェースが有効
- **RUNNING** - 稼働中
- **mtu 1500** - 最大転送単位（一度に送れるデータサイズ）

### **2行目：IPv4アドレス情報**
- **inet** - IPアドレス（192.168.1.100）
- **netmask** - サブネットマスク
- **broadcast** - ブロードキャストアドレス

### **3行目：IPv6アドレス情報**
- **inet6** - IPv6アドレス

### **4行目：MACアドレス**
- **ether** - 物理アドレス（MACアドレス）

### **5-6行目：受信（RX）統計**
- **packets** - 受信パケット数
- **bytes** - 受信バイト数
- **errors** - エラー数
- **dropped** - 破棄されたパケット数

### **7-8行目：送信（TX）統計**
- **packets** - 送信パケット数
- **bytes** - 送信バイト数
- **errors** - エラー数
- **collisions** - 衝突回数

## 注意点

最近のRHEL（7以降）では、`ifconfig`は非推奨で、**`ip`コマンド**が推奨されています。

```bash
ip addr show  # ifconfigの代替
ip link show  # インターフェース情報
```
