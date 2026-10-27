---
layout: work
title: "DA16200 WiFi Shield"
subtitle: "Arduino UNO ピン互換 WiFi 拡張ボード"
subpage: true
---

## サンプルプログラム Arduino UNO UART

### 準備

* 利便性と信頼性向上のため、AltSoftSerial を使います。
  ライブラリマネージャで、AltSoftSerial を導入します。
* AltSoftSerialは、TxD, RxD のピン配置が固定です。
  D0-TxD, D1-RxDのランド間をつないでいるラインをPカッター等でカットし、D8-TxD, D9-TxD間をジャンパー線で接続してください。
* それでも DA16200標準の 115200bpsでは取りこぼしなどが起こる場合は、あらかじめ DA16200のボーレートを 9600bps 等に落としてから試してください。ボーレートを9600bpsに設定する ATコマンドは、`ATB 9600` です。
* DA16200は、[アクセスポイントへの接続](../connect_ap)ページを参考に、APへ接続した状態にしておいてください。

### プログラム

サイト httpbin.org への HTTP GET サンプル

* https://httpbin.org へ、HTTP GET プロトコルでアクセスします。
* その際、パラメータとして param1=111 param2=222 を送信します。
* サイトからのレスポンスは、特定の解析などはせず、そのままデバッグ表示します。
* 一連の動作終了後、PCからコマンド受け付けとレンスポンス表示のモードに移行します。

```c++
#include <AltSoftSerial.h>

// Arduino UNO: Rx=D8, Tx=D9（固定）
AltSoftSerial wifiSerial;

// ATコマンド送信とレスポンス待機のヘルパー関数
bool sendCommand(const char* cmd, const char* expected, unsigned long timeoutMs) {
  Serial.print(F("\n[SEND] "));
  Serial.println(cmd);

  // 送信
  wifiSerial.println(cmd);

  unsigned long startTime = millis();
  String response = "";

  while (millis() - startTime < timeoutMs) {
    while (wifiSerial.available()) {
      char c = wifiSerial.read();
      response += c;
      Serial.write(c); // デバッグ用に受信内容をシリアルモニタへ出力

      if (response.indexOf(expected) != -1) {
        return true;
      }
    }
  }

  Serial.println(F("\n[TIMEOUT]"));
  return false;
}

void setup() {
  Serial.begin(115200);
  while (!Serial) { ; }
  Serial.println(F("--- DA16200 HTTP GET Test via AltSoftSerial ---"));

  // DA16200 のシリアル開始
  wifiSerial.begin(9600);
  delay(1000);

  // 1. 通信疎通確認
  Serial.println(F("\n--- 1. Testing AT ---"));
  while( sendCommand("AT", "OK", 2000) == false ) {
    delay( 1000 );
  }

  // 2. Wi-Fi接続確認 (すでにAPへ接続済みであることを前提とします)
  // 未接続の場合は事前に以下のコマンド等で接続しておいてください:
  // AT+WFJAPA=<SSID>,<PASSPHRASE>
  Serial.println(F("\n--- 2. Checking Wi-Fi Status ---"));
  sendCommand("AT+WFSTA", "OK", 3000);

  // 3. HTTP GET リクエストの送信
  // URL: https://httpbin.org/get?param1=111&param2=222
  Serial.println(F("\n--- 3. Sending HTTPS GET Request ---"));
  const char* getCmd = "AT+NWHTC=https://httpbin.org/get?param1=111&param2=222,get";
  
  // HTTPS通信およびサーバー応答には数秒かかるため、タイムアウトを長め(10秒)に設定
  sendCommand(getCmd, "OK", 10000);
}

void loop() {
  // レスポンス本文の非同期通知（+NWHTC: ... など）があればシリアルモニタへそのまま転送
  if (wifiSerial.available()) {
    char c = wifiSerial.read();
    Serial.write(c);
  }

  // シリアルモニタからの手動ATコマンド入力テスト用
  if (Serial.available()) {
    char c = Serial.read();
    wifiSerial.write(c);
  }
}
```

### 実行結果

```text
--- DA16200 HTTP GET Test via AltSoftSerial ---

--- 1. Testing AT ---

[SEND] AT

ERROR:-1

[TIMEOUT]

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

