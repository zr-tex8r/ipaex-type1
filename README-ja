ipaex-type1 パッケージ
=====================

IPAexフォントを Type1 形式の Unicode サブフォントに変換したもの。

### インストール

パッケージ内のファイルを次のように配置する。

  - `tfm/*.tfm`       → $TEXMF/fonts/tfm/public/ipaex-type1/
  - `type1/*.pfb`     → $TEXMF/fonts/type1/public/ipaex-type1/
  - `ipaex-type1.map` → $TEXMF/fonts/map/dvips/ipaex-type1/
  - `*.fd`, `*.fdx`   → $TEXMF/tex/latex/ipaex-type1/

その後で updmap で ipaex-type1.map を有効化する。

    updmap --enable Map ipaex-type1.map

（W32TeX では `updmap --add ipaex-type1.map` ）

### 使用法

インストールが済むと、

  * OT1、T1、TS1 のエンコーディング
  * CJK パッケージの `UTF8` エンコーディング（C70）

の各々について以下のファミリが使えるようになる。

  * `ipxm` : IPAex明朝
  * `ipxg` : IPAexゴシック

欧文での使用例。

    \documentclass{article}
    \renewcommand{\rmdefault}{ipxm}
    \renewcommand{\sfdefault}{ipxg}
    \begin{document}
    \textsf{Test}\quad Hello, {\TeX} world!
    \end{document}

CJK パッケージでの使用例。

    % 文字コードはUTF-8
    \documentclass{article}
    \usepackage{CJK}
    \begin{document}
    \begin{CJK*}{UTF8}{ipxm}
    これは簡単なテスト文書です。
    \end{CJK*}
    \end{document}

### ライセンス

「IPAフォントライセンスv1.0」が適用される。
（内容は LICENSE ファイルを参照。）

更新履歴
--------

  * Version 0.3b [2013/10/11]
      - ドキュメント修正。
  * Version 0.3a [2013/05/18]
      - (試験的) 縦書きオフセットを設定。
  * Version 0.3  [2013/05/08]
      - (試験的) 縦書きに対応した。
  * Version 0.2a [2013/04/22]
      - 欧文エンコーディング（OT1/T1/TS1）の一部の TFM の空白量が
        ゼロになっていたのを修正。
  * Version 0.2  [2013/04/21]
      - 最初の公開版。

--------------------
Takayuki YATO (aka. "ZR")  
http://zrbabbler.sp.land.to/
