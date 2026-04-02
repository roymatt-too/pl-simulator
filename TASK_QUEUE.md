# SUSHIHEY Task Queue

本ファイルは、SUSHIHEY の常時実行キューとする。  
主軸は `Data-and-Media-first, Guide-as-bootstrap, IP-linked brand building`。

## Priority Order

1. Data / Tracking
2. Media / Editorial
3. Authority / Site Asset
4. Brand / IP
5. Revenue / Product

---

## In Progress

- [ ] Tabelog 寿司ランキング追跡の最小データモデルを定義する
- [ ] 順位変動 / 星変動 / 店舗属性変動の履歴保存単位を定義する
- [ ] ランキング追跡データを記事導線へ接続する最小メディア構成を定義する
- [ ] IP をデータ/記事の拡散装置として使う最小週次運用を定義する

---

## Next Tasks

### Data / Tracking

- [ ] `shops` の canonical ID 設計
- [ ] `ranking_snapshots` テーブル設計
- [ ] `shop_metrics_history` テーブル設計
- [ ] `rating_change_events` テーブル設計
- [ ] 更新タイミングの監視条件を定義
- [ ] 初回取得対象店舗の優先順位を決める
- [ ] 差分生成ロジックを定義する

### Media / Editorial

- [ ] 「今月の順位変動」記事テンプレートを作る
- [ ] 「初掲載 / 圏外落ち / 星変動」記事テンプレートを作る
- [ ] `shops` ページと `guides` ページの相互リンク方針を決める
- [ ] `neta` / `glossary` / `seasonal` との接続方針を決める
- [ ] 海外向けトップページの情報優先順位を決める

### Authority / Site Asset

- [ ] `shops` `neta` `glossary` `guides` `seasonal` の公開順を決める
- [ ] 最初の 30 店舗ページ候補を確定する
- [ ] 最初の 30 ネタページ候補を確定する
- [ ] SUSHI HEY Score の初期表示方針を決める

### Brand / IP

- [ ] 小肌くんを「説明キャラ」として使う最小フォーマットを決める
- [ ] 記事連動ショート動画の最小テンプレートを作る
- [ ] ランキング変動を説明するキャラカードのテンプレートを作る
- [ ] IP を主役にしない運用ルールを固定する

### Revenue / Product

- [ ] 寿司ガイドを「関連商品」としてどこに置くか決める
- [ ] ガイドから `neta` / `glossary` への送客導線を整理する
- [ ] 無料サンプルの文字化け修正を優先確認する

---

## Stop Conditions

以下の場合のみ停止してよい。

- blocker がある
- 権限待ちがある
- 目的に対して次のタスクが未定義
- 高リスク判断が必要

それ以外は、上から順に次の open タスクを取る。
