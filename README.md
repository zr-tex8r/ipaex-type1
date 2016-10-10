ipaex-type1 パッケージ
=====================

IPAexフォントを Type1 形式の Unicode サブフォントに変換したもの。

### インストール

パッケージ内のファイルを次のように配置する。

  - `tfm/*.tfm`       → $TEXMF/fonts/tfm/public/ipaex-type1/
  - `type1/*.pfb`     → $TEXMF/fonts/type1/public/ipaex-type1/
  - `ipaex-type1.map` → $TEXMF/fonts/map/dvips/ipaex-type1/
  - `*.sty`           → $TEXMF/tex/latex/ipaex-type1/
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

ipaex-type1 バンドル 0.4 版以降では、フォントの使用をより簡単にするため
の同名の LaTeX パッケージが付属している。

### ライセンス

「IPAフォントライセンスv1.0」が適用される。
（内容は LICENSE ファイルを参照。）

ipaex-type1 パッケージ
----------------------

### パッケージ読込

パッケージオプションは存在しない。

    \usepackage{ipaex-type1}

### 使用法

以下の記述では CJK パッケージが読み込まれていることを仮定する。

  * `\ipxmfamily`／`\ipxgfamily`： CJK と非 CJK の両方のフォントファミリ
    を `ipxm`／`ipxg` に変更する。
  * `\textipxm{<text>}`／`\textipxg{<text>}`： 前項のテキスト命令版。
  * `\CJKipxmfamily`／`\CJKipxgfamily`: CJK ファミリのみを `ipxm`／`ipxg`
    に変更する。
  * `\textCJKipxm{<text>}`／`\textCJKipxg{<text>}`： テキスト命令版。
  * `\ipxmsymbol{<Unicode-point>}`／`\ipxgsymbol{<Unicode-point>}`：
    指定の Unicode 値をもつ CJK 文字を CJK ファミリ `ipxm`／`ipxg` で
    出力する。例えば、`\ipxmsymbol{"2603}` は次のコードと同等である：
    `{\CJKfamily{ipxm}\Unicode{"26}{"03}}`

CJK パッケージが読み込まれていない、あるいは `CJK(*)` 環境の外で命令が
呼び出された場合は、一般的には、CJK ファミリに対する効果を除外した動作
になる。例えば、`\ipxmfamily` は非 CJK ファミリ（それしかない）を `ipxm`
に変更し、また `\CJKipxgfamily` は何の効果も持たない。ただしこの一般規則
には幾つかの例外があり、それを以下で解説する。

### `\textCJKipxm`／`\textCJKipxg` 命令

CJK パッケージが読込済でかつ `CJK` 環境の外で `\textCJKipxm` が呼ばれた
という場合、その引数は自動的に `CJK*` 環境に入れたと見なされる。例えば：


    Japan (\textCJKipxm{日本})

は以下と同等になる：

    Japan (\begin{CJK*}{UTF8}{ipxm}日本\end{CJK*})

### `\ipxmsymbol`／`\ipxgsymbol` 命令

これらの命令は `CJK` 環境の外、および CJK パッケージを使用しない場合でも
利用できる。その場合、出力の CJK 文字は組版上は記号と同じ扱いになる。
例えば、文書中に現れる日本語の単語が「日本」一つしかないという場合、CJK
パッケージを使わずに以下のように書いて済ませることができる：

    Japan (\ipxmsymbol{"65E5}\ipxmsymbol{"672C})

更新履歴
--------

  * Version 0.4  ‹2016/10/01›
      - 変換元の IPAex フォントのバージョンを 003.01 版に更新した。
      - BMP 外の文字に対応した。
      - 補助の LaTeX パッケージを作製した。
  * Version 0.3b ‹2013/10/11›
      - ドキュメント修正。
  * Version 0.3a ‹2013/05/18›
      - (試験的) 縦書きオフセットを設定。
  * Version 0.3  ‹2013/05/08›
      - (試験的) 縦書きに対応した。
  * Version 0.2a ‹2013/04/22›
      - 欧文エンコーディング（OT1/T1/TS1）の一部の TFM の空白量が
        ゼロになっていたのを修正。
  * Version 0.2  ‹2013/04/21›
      - 最初の公開版。

--------------------
Takayuki YATO (aka. "ZR")  
http://zrbabbler.sp.land.to/
