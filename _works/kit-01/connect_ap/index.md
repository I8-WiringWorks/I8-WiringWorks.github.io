---
layout: work
title: "DA16200 WiFi Shield"
subtitle: "Arduino UNO ピン互換 WiFi 拡張ボード"
subpage: true
---

## アクセスポイントへの接続方法

FTDI製USBシリアル変換ケーブル(3.3V) TTL-232R-3V3 を使って、ターミナルソフトから直接設定する方法と、ATコマンドを使ってプログラムから設定する方法の2種類があります。

### ターミナルソフトから直接設定する

ここでは、最も一般的な SSIDとパスワードによる接続と、DHCPによるIP取得について説明します。

1. [動作確認ページのボード単体で確認する場合](../check) を参考に、ターミナルソフトを接続して起動します。
2. エンターキーを押し、`[/DA16200] #` の表示がされることを確認します。
3. ファクトリーリセットをします。`factory` と入力し `y` を入力します。

    ```text
	[/DA16200] # factory
	FACTORY RESET [N/y/?] y
	Start Factory-Reset ...
	Rebooting....
    ```

4. 設定モードに入ります。`setup` と入力し、`Y` を入力します。

    ```text
	[/DA16200] # setup
	Stop all services for the setting.
	 Are you sure ? [Yes/No] : Y
    ```

5. 国コードの入力をします。`JP` を入力します。

    ```text
	[ DA16200 EASY SETUP ]
	Country Code List:
	AD  AE  AF  AI  AL  AM  AR  AS  AT  AU  AW  AZ  BA  BB  BD  BE  BF  BG  BH  BL
	BM  BN  BO  BR  BS  BT  BY  BZ  CA  CF  CH  CI  CL  CN  CO  CR  CU  CX  CY  CZ
	DE  DK  DM  DO  DZ  EC  EE  EG  ES  ET  EU  FI  FM  FR  GA  GB  GD  GE  GF  GH
	GL  GP  GR  GT  GU  GY  HK  HN  HR  HT  HU  ID  IE  IL  IN  IR  IS  IT  JM  JO
	JP  KE  KH  KN  KP  KR  KW  KY  KZ  LB  LC  LI  LK  LS  LT  LU  LV  MA  MC  MD
	ME  MF  MH  MK  MN  MO  MP  MQ  MR  MT  MU  MV  MW  MX  MY  NG  NI  NL  NO  NP
	NZ  OM  PA  PE  PF  PG  PH  PK  PL  PM  PR  PT  PW  PY  QA  RE  RO  RS  RU  RW
	SA  SE  SG  SI  SK  SN  SR  SV  SY  TC  TD  TG  TH  TN  TR  TT  TW  TZ  UA  UG
	UK  US  UY  UZ  VA  VC  VE  VI  VN  VU  WF  WS  YE  YT  ZA  ZW  ALL

	 COUNTRY CODE ? [Quit] (Default KR) :JP
```

6. 接続モードを指定します。`1` を入力します。

    ```text
    SYSMODE(WLAN MODE) ?
            1. Station
            2. Soft-AP
            3. Station & SOFT-AP
     MODE ?  [1/2/3/Quit] (Default Station) : 1
    ```

7. SSIDのリストが表示されます。接続するSSIDを、`[NO]`欄の番号で入力します。


    ```text
    [ STATION CONFIGURATION ]
    ============================================================================
    [NO] [SSID]                                         [SIGNAL] [CH] [SECURITY]
    ----------------------------------------------------------------------------
    [ 1] SSID                                               -43   1         WPA2
    [ 2] AirPort42718                                       -53  11   WPA / WPA2
    [ 3] Game42718                                          -54  11          WEP
    [ 4] aterm-818ddb-g                                     -81   3   WPA / WPA2
    [ 5] elecom2g-d41db1                                    -85   6   WPA / WPA2
    ----------------------------------------------------------------------------
    [M] Manual Input
    [Enter] Rescan
    ============================================================================

     Select SSID ? (1~09/Manual/Quit) : 1
    ```

8. パスワードを入力し、`Y` を入力します。

    ```text
     PSK-KEY(ASCII characters 8~63 or Hexadecimal characters 64) ? [Quit]
    [123456789|123456789|123456789|123456789|123456789|123456789|1234]
    :password
    ```

9. 次の入力では、何も入力せずエンターを押します。

    ```text
    Do you want to set advanced WiFi configuration ? [No/Yes/Quit] (Default No) :
    ```

10. 確認画面が表示されますので、`Y` を入力します。

    ```text
	============================================
	SSID        : SSID
	AUTH        : WPA/WAP2-PSK
	ENCRYPTION  : TKIP/AES(CCMP)
	PSK KEY     : password
	KEY TYPE    : ASCII
	PMF MODE    : Disable
	Hidden AP   : Not connect
	============================================
	 WIFI CONFIGURATION CONFIRM ? [Yes/No/Quit] : Y
    ```

11. 次の入力では、DHCPを使うために、`A` を入力します。

    ```text
    IP Connection Type ? [Automatic IP/Static IP/Quit] : A
    ```

12. 確認画面が表示されますので、`Y` を入力します。

    ```text
 IP CONFIGURATION CONFIRM ? [Yes/No/Quit] : Y
    ```

13. SNTPや省電力モードを使用するか確認されますが、ここでは使用しないことにしてすべて `N`　を入力します。

    ```text
     SNTP Client enable ? [Yes/No/Quit] : N

     Fast Connection Sleep 2 Mode ? [Yes/No/Quit] : N

     Dialog DPM (Dynamic Power Management) ? [Yes/No/Quit] : N
    ```

14. 自動的にリブートし、続いてAPへの接続情報が表示されます。

    ```text
	Configuration OK

	Reboot...
	（中略）

	>>> Network Interface (wlan0) : UP
	>>> Associated with 3c:01:ef:0d:7d:da

	Connection COMPLETE to 3c:01:ef:0d:7d:da

	-- DHCP Client WLAN0: SEL(6)

	### User Call-back : Success to connect Wi-Fi ...
	-- DHCP Client WLAN0: REQ(1)
	-- DHCP Client WLAN0: CHK(8)
	-- DHCP Client WLAN0: BOUND(10)
			 Assigned addr   : 192.168.43.156
				   netmask   : 255.255.255.0
				   gateway   : 192.168.43.32
				   DNS addr  : 192.168.43.32

			 DHCP Server IP  : 192.168.43.32
			 Lease Time      : 02h 00m 00s
			 Renewal Time    : 01h 00m 00s
    ```


以上で終了です。
ここで入力した情報はモジュール本体に記憶され、電源を切っても消えません。


--------------------------------------------------------------------------------
### ATコマンドで設定する

1. [動作確認ページのボード単体で確認する場合](../check#2-atコマンドによる確認) の「2. ATコマンドによる確認」を参考に、ターミナルソフトを接続して起動します。
2. ターミナルソフトから、`ATE`と入力します。
    入力時には、画面には何も表示されないですが、それで正常です。
3. エンターを押すと、OK と表示されます。以後入力が表示されます。
4. APをスキャンし、接続したい SSID が表示されていることを確認します。

    ```text
	AT+WFSCAN
	```

5. SSIDとパスワードを指定して接続を開始します。
    しばらくして接続に成功すると、以下の通り `+WFJAP:` に引き続いて接続した SSIDとIPアドレスが表示されます。

    ```text
	AT+WFJAPA=SSID,password
    OK

    +WFJAP:1,'SSID',192.168.1.2
	```

6. エコーバックがプログラムの邪魔になる可能性があるので、もう一度 `ATE` と入力して停止しておきます。

    ```text
	ATE
	```


以上で終了です。
ここで入力した情報はモジュール本体に記憶され、電源を切っても消えません。
