---
layout: work
title: "DA16200 WiFi Shield"
subtitle: "Arduino UNO ピン互換 WiFi 拡張ボード"
subpage: true
---

## サンプルコード Arduino UNO UART

### 準備

* デバッグ用に高ボーレートで出力するため、AltSoftSerial を使います。
  ライブラリマネージャで、AltSoftSerial を導入してください。
* AltSoftSerialは、TxD=D9, RxD=D8 のピン配置が固定です。
* DA16200標準の 115200bps に合わせて、多くのデータをデバッグ出力に転送する場合は、デバッグ出力への取りこぼしが発生します。これが問題になる場合は、DA16200側のボーレートを 57600bps 等に落としてから試してください。
ボーレートを 57600bpsに設定する ATコマンドは、`ATB 57600` です。
* DA16200は、[アクセスポイントへの接続](../connect_ap)ページを参考に、APへ接続した状態にしておいてください。
* ArduinoUNOへプログラムを書き込む時には、WiFi Shield を外した状態で書き込んでください。付けたままだと、UARTが干渉して書き込みが失敗します。

### プログラム

サイト httpbin.org への HTTP GET サンプル

* https://httpbin.org へ、HTTP GET プロトコルでアクセスします。
* その際、パラメータとして param1=111 param2=222 を送信します。
* サイトからのレスポンスは、特定の解析などはせず、そのままデバッグ表示します。
* 一連の動作終了後、PCからコマンド受け付けとレンスポンス表示のモードに移行します。

```c++
#include <AltSoftSerial.h>

// Arduino UNO: Rx=D8, Tx=D9（固定）をデバッグ用シリアルとして使用
AltSoftSerial debugSerial;

// ATコマンド送信とレスポンス待機のヘルパー関数
bool sendCommand(const char* cmd, const char* expected, unsigned long timeoutMs) {
  debugSerial.print(F("\n[SEND] "));
  debugSerial.println(cmd);

  // DA16200 (Serial) へ送信
  Serial.println(cmd);

  unsigned long startTime = millis();
  String response = "";

  while (millis() - startTime < timeoutMs) {
    while (Serial.available()) {
      char c = Serial.read();
      response += c;
      debugSerial.write(c); // デバッグ用に受信内容を AltSoftSerial へ出力

      if (response.indexOf(expected) != -1) {
        return true;
      }
    }
  }

  debugSerial.println(F("\n[TIMEOUT]"));
  return false;
}

void setup() {
  // DA16200 とのシリアル通信開始（ハードウェアシリアル: D0=Rx, D1=Tx）
  Serial.begin(115200);
  while (!Serial) { ; }

  // デバッグ出力用の AltSoftSerial 開始
  debugSerial.begin(57600);
  debugSerial.println(F("--- DA16200 HTTP GET Test via Hardware Serial ---"));

  delay(1000);

  // 1. 通信疎通確認
  debugSerial.println(F("\n--- 1. Testing AT ---"));
  while (sendCommand("AT", "OK", 2000) == false) {
    delay(1000);
  }

  // 2. Wi-Fi接続確認 (すでにAPへ接続済みであることを前提とします)
  // 未接続の場合は事前に以下のコマンド等で接続しておいてください:
  // AT+WFJAPA=<SSID>,<PASSPHRASE>
  debugSerial.println(F("\n--- 2. Checking Wi-Fi Status ---"));
  sendCommand("AT+WFSTA", "OK", 3000);

  // 3. HTTP GET リクエストの送信
  // URL: https://httpbin.org/get?param1=111&param2=222
  debugSerial.println(F("\n--- 3. Sending HTTPS GET Request ---"));
  const char* getCmd = "AT+NWHTC=https://httpbin.org/get?param1=111&param2=222,get";

  // HTTPS通信およびサーバー応答には数秒かかるため、タイムアウトを長め(10秒)に設定
  sendCommand(getCmd, "OK", 10000);
}

void loop() {
  // DA16200 (Serial) からの非同期通知があればデバッグ用シリアルへ転送
  while (Serial.available()) {
    char c = Serial.read();
    debugSerial.write(c);
  }

  // デバッグ用シリアルからの手動ATコマンド入力を DA16200 へ転送
  while (debugSerial.available()) {
    char c = debugSerial.read();
    Serial.write(c);
  }
}
```

### 実行結果

```text
--- DA16200 HTTP GET Test via Hardware Serial ---

--- 1. Testing AT ---

[SEND] AT

OK

--- 2. Checking Wi-Fi Status ---

[SEND] AT+WFSTA


+WFSTA:1
OK
--- 3. Sending HTTPS GET Request ---

[SEND] AT+NWHTC=https://httpbin.org/get?param1=111&param2=222,get


OK
HTTP/1.1 200 OK
Date: Tue, 27 Oct 2026 14:38:12 GMT
Content-Type: application/json
Content-Length: 364
Connection: close
Server: gunicorn/19.9.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true

{
  "args": {
    "param1": "111",
    "param2": "222"
  },
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "lwIP/2.1.2 (http://savannah.nongnu.org/projects/lwip)",
    "X-Amzn-Trace-Id": "Root=1-6ae0b754-51cfb63f5392854672a57bac"
  },
  "origin": "153.156.176.3",
  "url": "https://httpbin.org/get?param1=111&param2=222"
}

+NWHTCSTATUS:0
```

