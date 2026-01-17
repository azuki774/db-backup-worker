# PostgreSQL Backup to S3

PostgreSQL データベースのバックアップを取得し、Amazon S3 にアップロードする Docker イメージです。

## タグ命名規則

- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg14` - PostgreSQL 14 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg15` - PostgreSQL 15 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16` - PostgreSQL 16 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg17` - PostgreSQL 17 版
- `ghcr.io/<repo>/pg-dump-to-s3:latest-pg16` - 最新版 (PostgreSQL 16)

## 環境変数

| 変数名 | 必須 | デフォルト値 | 説明 |
|--------|------|-------------|------|
| `DB_HOST` | Yes | - | データベースのホスト名 |
| `DB_PORT` | Yes | 5432 | データベースのポート |
| `DB_USER` | Yes | - | データベースのユーザー名 |
| `DB_PASSWORD` | Yes | - | データベースのパスワード |
| `DB_NAME` | Yes | - | バックアップするデータベース名 |
| `S3_BUCKET` | Yes | - | S3 バケット名 |
| `SKIP_S3_UPLOAD` | No | false | S3 アップロードをスキップするかどうか |
| `AWS_ACCESS_KEY_ID` | No | - | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | No | - | AWS シークレットキー |
| `AWS_REGION` | No | - | AWS リージョン |

## 使用例

### 基本的な使用方法

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e S3_BUCKET=my-backup-bucket \
  -e S3_PREFIX=postgres/ \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_REGION=us-east-1 \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

### 全データベースをバックアップ

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e S3_BUCKET=my-backup-bucket \
  -e S3_PREFIX=postgres/all/ \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

### IAM ロールを使用 (AWS EC2 / ECS / EKS)

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e S3_BUCKET=my-backup-bucket \
  -e S3_PREFIX=postgres/ \
  -e AWS_REGION=us-east-1 \
  --network host \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

## バックアップ検証

このイメージは、S3 にアップロードする前に以下の検証を行います：

1. **ファイルサイズチェック**: バックアップファイルが `MIN_BACKUP_SIZE_BYTES` 以上であること
2. **署名チェック**: ファイルが有効な PostgreSQL ダンプであること
3. **スキーマオブジェクトチェック**: ダンプにスキーマオブジェクト（テーブル、インデックスなど）が含まれていること
4. **データチェック**: ダンプにデータ（COPY 文）が含まれているか確認
5. **ダンプ形式チェック**: ダンプが正しく完了しているか確認

## 開発とテスト

```bash
# テスト環境を構築
docker compose -f docker-compose.test.yml up -d

# テスト実行
docker build -t pg-dump-to-s3:test .
docker run --rm \
  --network container:test-postgres \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=testpass \
  -e DB_NAME=testdb \
  -e S3_BUCKET=test-bucket \
  -e S3_PREFIX=test \
  -e SKIP_S3_UPLOAD=true \
  pg-dump-to-s3:test

# 後片付け
docker compose -f docker-compose.test.yml down -v
```
