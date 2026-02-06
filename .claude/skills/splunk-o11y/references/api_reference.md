# Splunk Observability Cloud APM Topology API Reference

## 概要

サービス間の依存関係とトポロジーを取得するためのAPI。

**ベースURL**: `https://api.{REALM}.signalfx.com/v2`

**必要な権限**: admin, power, または read_only ロール

---

## 1. APIエンドポイント一覧

| メソッド | エンドポイント | 説明 |
|---------|---------------|------|
| POST | `/v2/apm/topology` | 環境内の全サービスのトポロジーを取得 |
| POST | `/v2/apm/topology/{serviceName}` | 特定サービスの依存関係を取得 |

---

## 2. 認証方法

全てのリクエストに `X-SF-Token` ヘッダーが必須。

```
X-SF-Token: <your_access_token>
```

**トークン種別**: Organization Access Token（API権限付き）またはSession Token

---

## 3. リクエストボディ

### 共通フィールド

```json
{
  "timeRange": "<start_time>/<end_time>",
  "tagFilters": [...]
}
```

### timeRange (必須)

ISO 8601形式のタイムスタンプ2つをスラッシュで区切る。

```
"timeRange": "2021-01-23T12:00:00Z/2021-01-24T00:00:00Z"
```

**制約**:
- 最小: 5分
- 最大: トレース保持期間
- 開始時刻 < 終了時刻

### tagFilters (任意)

#### equals演算子

単一値でフィルタリング。

```json
{
  "name": "sf_environment",
  "operator": "equals",
  "scope": "GLOBAL",
  "value": "production"
}
```

#### in演算子

複数値でフィルタリング。

```json
{
  "name": "sf_environment",
  "operator": "in",
  "scope": "GLOBAL",
  "values": ["production", "staging"]
}
```

### scope値

| 値 | 説明 |
|----|------|
| `GLOBAL` | 全スパンの最初の出現にマッチ |
| `TIER` | サービス層スパンの最初の出現にマッチ |
| `INCOMING` | サービス層スパンの受信エッジスパンの値にマッチ |
| `SPAN` | トレース内の各スパンのタグにマッチ |

### サポートされるタグ名

- `sf_service` - サービス名
- `sf_environment` - 環境名
- `sf_httpMethod` - HTTPメソッド
- `sf_kind` - スパン種別
- カスタムインデックスタグ

---

## 4. レスポンス構造

### POST /v2/apm/topology

全サービスのトポロジーをグラフ形式で返却（最大1,000オブジェクト）。

```json
{
  "nodes": [
    {
      "serviceName": "checkout-service",
      "inferred": false,
      "type": "service"
    }
  ],
  "edges": [
    {
      "fromNode": "frontend",
      "toNode": "checkout-service"
    }
  ]
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `nodes` | array | サービス一覧 |
| `nodes[].serviceName` | string | サービス名 |
| `nodes[].inferred` | boolean | 推論されたサービスか |
| `nodes[].type` | string | `service`, `database`, `pubsub` |
| `edges` | array | サービス間の接続 |
| `edges[].fromNode` | string | 接続元サービス |
| `edges[].toNode` | string | 接続先サービス |

### POST /v2/apm/topology/{serviceName}

指定サービスのインバウンド/アウトバウンド依存関係を返却。

```json
{
  "inbound": ["frontend", "api-gateway"],
  "outbound": ["database", "cache"],
  "services": [
    {
      "serviceName": "frontend",
      "inferred": false,
      "type": "service"
    }
  ]
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `inbound` | array | このサービスを呼び出すサービス名の配列 |
| `outbound` | array | このサービスが呼び出すサービス名の配列 |
| `services` | array | 関連サービスの詳細情報 |

**注意**: serviceNameが存在しない場合、200ステータスと空レスポンスを返却。

---

## 5. エラーコードと対処法

### 400 Bad Request

| メッセージ | 対処法 |
|-----------|--------|
| `timeRange is required` | timeRangeフィールドを追加 |
| `Invalid delimiter used to split time range` | スラッシュ(/)で区切る |
| `Invalid time range` | ISO 8601形式を確認 |
| `time range must not be negative` | 開始時刻 < 終了時刻にする |
| `time range must be more than or equal to 5 minutes` | 5分以上の範囲を指定 |
| `time range must be less than or equal to the trace retention limit` | 保持期間内に収める |
| `name is a mandatory field` | tagFilterにnameを追加 |
| `scope is a mandatory field` | tagFilterにscopeを追加 |
| `value is a mandatory field` | equals演算子にはvalueが必須 |
| `values is a mandatory field` | in演算子にはvaluesが必須 |
| `unsupported filter name` | サポートされるタグ名を使用 |
| `Invalid tag filter operator value` | equalsまたはinを使用 |

### 401 Unauthorized

```json
{
  "code": 401,
  "message": "Unauthorized: Invalid token"
}
```

**対処法**: X-SF-Tokenの値を確認し、有効なトークンを使用する。

---

## 6. サンプルリクエスト

### 全サービスのトポロジー取得

```bash
curl -X POST "https://api.us1.signalfx.com/v2/apm/topology" \
  -H "Content-Type: application/json" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN" \
  -d '{
    "timeRange": "2024-01-01T00:00:00Z/2024-01-01T01:00:00Z",
    "tagFilters": [
      {
        "name": "sf_environment",
        "operator": "equals",
        "scope": "GLOBAL",
        "value": "production"
      }
    ]
  }'
```

### 特定サービスの依存関係取得

```bash
curl -X POST "https://api.us1.signalfx.com/v2/apm/topology/checkout-service" \
  -H "Content-Type: application/json" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN" \
  -d '{
    "timeRange": "2024-01-01T00:00:00Z/2024-01-01T01:00:00Z",
    "tagFilters": [
      {
        "name": "sf_environment",
        "operator": "equals",
        "scope": "GLOBAL",
        "value": "production"
      }
    ]
  }'
```

### 複数環境でフィルタリング

```bash
curl -X POST "https://api.us1.signalfx.com/v2/apm/topology" \
  -H "Content-Type: application/json" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN" \
  -d '{
    "timeRange": "2024-01-01T00:00:00Z/2024-01-01T01:00:00Z",
    "tagFilters": [
      {
        "name": "sf_environment",
        "operator": "in",
        "scope": "GLOBAL",
        "values": ["production", "staging"]
      }
    ]
  }'
```

---

## 7. Trace ID API

トレースIDを指定して、特定のトレースのスパン情報を取得するためのAPI。

### エンドポイント

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/v2/apm/trace/{traceId}/segments` | トレースのセグメントタイムスタンプ一覧取得 |
| GET | `/v2/apm/trace/{traceId}/{segmentTimestamp}` | 特定セグメントのスパン取得 |
| GET | `/v2/apm/trace/{traceId}/latest` | 最新セグメントのスパン取得 |

### レスポンス構造

#### GET /v2/apm/trace/{traceId}/segments

セグメントタイムスタンプの配列を返却。

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `segments` | array[int64] | タイムスタンプの配列 |

#### GET /v2/apm/trace/{traceId}/{segmentTimestamp} および /latest

Spanオブジェクトの配列を返却。

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `traceId` | string | トレースID（16進数文字列） |
| `spanId` | string | スパンID（16進数文字列） |
| `parentId` | string | 親スパンID（16進数文字列） |
| `serviceName` | string | サービス名 |
| `operationName` | string | オペレーション名 |
| `startTime` | string | 開始時刻（ISO-8601形式） |
| `durationMicros` | int64 | 継続時間（マイクロ秒） |
| `tags` | object | スパンタグ（key-value） |
| `processTags` | object | プロセスタグ（key-value） |
| `logs` | array | Logオブジェクトの配列 |

### Acceptヘッダー

| 値 | 説明 |
|----|------|
| `application/json` | JSON配列（デフォルト） |
| `application/x-ndjson` | 改行区切りJSON |

### エラーコード

| コード | 説明 |
|--------|------|
| 404 | トレースが存在しない |
| 429 | レート制限超過 |

### サンプルリクエスト

#### セグメントタイムスタンプ一覧取得

```bash
curl -X GET "https://api.us1.signalfx.com/v2/apm/trace/abc123def456/segments" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN"
```

#### 特定セグメントのスパン取得

```bash
curl -X GET "https://api.us1.signalfx.com/v2/apm/trace/abc123def456/1704067200000" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN" \
  -H "Accept: application/json"
```

#### 最新セグメントのスパン取得

```bash
curl -X GET "https://api.us1.signalfx.com/v2/apm/trace/abc123def456/latest" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN"
```

#### NDJSON形式で取得

```bash
curl -X GET "https://api.us1.signalfx.com/v2/apm/trace/abc123def456/latest" \
  -H "X-SF-Token: YOUR_ACCESS_TOKEN" \
  -H "Accept: application/x-ndjson"
```

---

## 8. SignalFlow Execute API

SignalFlowプログラムを実行し、リアルタイムまたは過去のメトリクスデータをSSE（Server-Sent Events）ストリームとして取得するAPI。

**ベースURL**: `https://stream.{REALM}.signalfx.com/v2`

### エンドポイント

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/v2/signalflow/execute` | SignalFlowプログラムを実行 |

### リクエスト

**ヘッダー**:
```
Content-Type: application/json
X-SF-Token: <your_access_token>
```

**クエリパラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `start` | int64 | はい | 開始時刻（エポックミリ秒） |
| `stop` | int64 | いいえ | 終了時刻（エポックミリ秒）。省略時はリアルタイムストリーム |
| `resolution` | int64 | いいえ | データポイント解像度（ミリ秒） |
| `immediate` | boolean | いいえ | `true`で即時結果返却（過去データ向け） |

**リクエストボディ**:

```json
{
  "programText": "data('service.request.count', filter=filter('sf_environment', 'production')).sum(by=['sf_service']).publish('throughput')"
}
```

### SSEレスポンス形式

レスポンスはSSE（Server-Sent Events）ストリームで、複数のイベントタイプを含む。各`data:`フィールドは複数行にまたがるJSON。

#### イベントタイプ

| イベント | 説明 |
|---------|------|
| `control-message` | ストリーム制御メッセージ（`STREAM_START`, `JOB_START`, `END_OF_CHANNEL`） |
| `metadata` | 時系列のメタデータ（tsId、プロパティ、ラベル） |
| `data` | 実際のデータポイント |
| `message` | 情報メッセージ |

#### metadata イベント構造

```json
{
  "properties": {
    "sf_service": "checkout",
    "sf_environment": "production",
    "sf_streamLabel": "throughput",
    "sf_originatingMetric": "service.request.count",
    "sf_resolutionMs": 60000
  },
  "tsId": "AAAAAF0-GPM"
}
```

#### data イベント構造

```json
{
  "data": [
    {"tsId": "AAAAAF0-GPM", "value": 82},
    {"tsId": "AAAAABr7PB8", "value": 206}
  ],
  "logicalTimestampMs": 1770338520000,
  "maxDelayMs": 10000
}
```

**注意**: `data`フィールドはリスト形式（`[{tsId, value}, ...]`）。

### APMメトリクス用SignalFlowプログラム例

#### エラー率

```
errors = data('service.request.count',
  filter=filter('sf_error', 'true') and filter('sf_environment', 'production'))
  .sum(by=['sf_service']).publish('errors')
total = data('service.request.count',
  filter=filter('sf_environment', 'production'))
  .sum(by=['sf_service']).publish('total')
```

#### P99レイテンシ

```
data('service.request.duration.ns.p99',
  filter=filter('sf_environment', 'production'))
  .mean(by=['sf_service']).publish('latency_p99')
```

#### スループット

```
data('service.request.count',
  filter=filter('sf_environment', 'production'))
  .sum(by=['sf_service']).publish('throughput')
```

### サービスフィルタリング

特定サービスに絞り込むには`filter('sf_service', 'name')`を追加:

```
data('service.request.count',
  filter=filter('sf_environment', 'production') and filter('sf_service', 'checkout'))
  .sum(by=['sf_service']).publish('throughput')
```
