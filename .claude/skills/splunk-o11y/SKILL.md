---
name: splunk-o11y
description: Splunk Observability Cloud APM APIを使用してサービストポロジー、トレース、サービスメトリクス（エラー率・レイテンシ・スループット）を取得・分析するためのスキル。デバッグ時の問題特定、サービス依存関係の調査、環境別のサービス比較に使用。トレースID、サービス名、APM、依存関係、トポロジー、エラー率、レイテンシ、スループットなどのキーワードで起動。
---

# Splunk Observability Cloud APM

Splunk Observability CloudのAPM APIを使用してサービストポロジー、トレース、サービスメトリクスを取得する。

## 環境設定

以下の環境変数を設定:

```bash
export SF_TOKEN="your-api-token"    # 必須: Organization Access Token
export SF_REALM="us1"               # オプション: realm (デフォルト: us1)
```

REALMが未設定の場合、スクリプト実行時に確認する。

## サービストポロジー取得

`--environment` にはアプリケーションで設定している環境名（`deployment.environment` 属性の値）を指定する。以下の `production` は例であり、実際の環境名に置き換えること。

### 全サービスのトポロジー

```bash
python scripts/get_topology.py --environment production
```

### 特定サービスの依存関係

```bash
python scripts/get_topology.py --environment production --service my-service
```

### 時間範囲を指定

```bash
python scripts/get_topology.py --environment production \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-01T12:00:00Z
```

## トレース取得

### トレースIDから最新スパンを取得

```bash
python scripts/get_trace.py <trace-id>
```

### セグメント一覧を取得

```bash
python scripts/get_trace.py <trace-id> --segments
```

### 特定セグメントのスパンを取得

```bash
python scripts/get_trace.py <trace-id> --segment-timestamp 1704067200000000
```

## サービスメトリクス取得

SignalFlow APIを使用して、APMサービスメトリクス（エラー率、P99レイテンシ、スループット）を取得する。

### エラー率（全サービス）

```bash
python scripts/get_service_metrics.py --environment production --metric error-rate
```

### P99レイテンシ（特定サービス）

```bash
python scripts/get_service_metrics.py --environment production --metric latency --service checkout
```

### スループット（カスタム時間範囲）

```bash
python scripts/get_service_metrics.py --environment production --metric throughput \
    --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T01:00:00Z
```

### オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--environment` | 環境名（必須） | - |
| `--metric` | `error-rate`, `latency`, `throughput` のいずれか（必須） | - |
| `--service` | サービス名でフィルタ | 全サービス |
| `--start-time` | 開始時刻（ISO8601） | 10分前 |
| `--end-time` | 終了時刻（ISO8601） | 現在 |
| `--resolution` | 解像度（ミリ秒） | 60000 |

### 出力例

```json
{
  "metric_type": "error-rate",
  "environment": "production",
  "results": [
    {
      "service": "checkout",
      "error_rate_pct": 50.0,
      "error_count": 10,
      "total_count": 20
    }
  ]
}
```

## デバッグワークフロー

1. **サービス健全性を確認**: `get_service_metrics.py --metric error-rate` で全サービスのエラー率を確認
2. **問題サービスを特定**: エラー率やレイテンシが異常なサービスを絞り込む
3. **サービス依存関係を調査**: `get_topology.py --service <name>` で上流・下流を確認
4. **問題のトレースを特定**: トレースIDを取得
5. **トレース詳細を取得**: `get_trace.py` でスパン一覧を確認
6. **環境比較**: 異なる `--environment` で結果を比較

## APIリファレンス

- 概要・使用例: [references/api_reference.md](references/api_reference.md)
- OpenAPI定義（詳細）:
  - [references/apm_service_topology-latest.json](references/apm_service_topology-latest.json)
  - [references/trace_id-latest.json](references/trace_id-latest.json)
