# MariaDB Backup to S3

MariaDB データベースのバックアップを取得し、Amazon S3 にアップロードする Docker イメージです。

## タグ命名規則

- `ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11` - MariaDB 11 版（メジャーバージョン）
- `ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11.4` - MariaDB 11.4 版（フルバージョン）
- `ghcr.io/<repo>/mariadb-dump-to-s3:latest-maria11` - 最新版 (MariaDB 11)

## 環境変数

| 変数名 | 必須 | デフォルト値 | 説明 |
|--------|------|-------------|------|
| `DB_HOST` | Yes | - | データベースのホスト名 |
| `DB_PORT` | Yes | 3306 | データベースのポート |
| `DB_USER` | Yes | root | データベースのユーザー名 |
| `DB_PASSWORD` | Yes | - | データベースのパスワード |
| `DB_NAME` | Yes | - | バックアップするデータベース名 |
| `BACKUP_NAME` | Yes | - | バックアップファイル名（拡張子なし、例: `daily_backup`） |
| `BUCKET_NAME` | Yes* | - | S3 バケット名（`SKIP_S3_UPLOAD=false`時は必須） |
| `BUCKET_DIR` | Yes* | - | S3 バケット内のディレクトリ/プレフィックス（`SKIP_S3_UPLOAD=false`時は必須） |
| `SKIP_S3_UPLOAD` | No | false | S3 アップロードをスキップするかどうか |
| `AWS_ACCESS_KEY_ID` | No | - | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | No | - | AWS シークレットキー |
| `AWS_REGION` | No | - | AWS リージョン |
| `BUCKET_URL` | No | - | カスタム S3 エンドポイント URL (MinIOなど) |
| `DISCORD_WEBHOOK` | No | - | Discord Webhook URL（バックアップ成功/失敗時に通知） |

## 使用例

### 基本的な使用方法

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=mariadb/ \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_REGION=us-east-1 \
  ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11
```

### IAM ロールを使用 (AWS EC2 / ECS / EKS)

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=mariadb/ \
  -e AWS_REGION=us-east-1 \
  --network host \
  ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11
```

### MinIO などの互換 S3 を使用

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=mariadb/ \
  -e BUCKET_URL=http://minio:9000 \
  -e AWS_ACCESS_KEY_ID=minioadmin \
  -e AWS_SECRET_ACCESS_KEY=minioadmin \
  ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11
```

### Discord 通知を有効化

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=mariadb/ \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_REGION=us-east-1 \
  -e DISCORD_WEBHOOK=https://discord.com/api/webhooks/... \
  ghcr.io/<repo>/mariadb-dump-to-s3:v1.2.0-maria11
```

## バックアップ検証

このイメージは、S3 にアップロードする前に以下の検証を行います：

1. **ファイルサイズチェック**: バックアップファイルのサイズを確認
2. **署名チェック**: ファイルが有効な MariaDB/MySQL ダンプであることを確認（`MySQL database dump` または `MariaDB database dump` 文字列のチェック）
3. **ダンプ完了チェック**: ダンプが最後まで完了したことを確認（`Dump completed on` 文字列のチェック）
4. **SQL ステートメントチェック**: ダンプに有効な SQL ステートメント（`CREATE`、`INSERT` コマンドなど）が含まれていることを確認

## mysqldump オプション

このイメージは `--single-transaction` オプションを使用してバックアップを取得します。これにより、トランザクション一貫性のあるバックアップが取得できます（InnoDBテーブルの場合）。

## 開発とテスト

```bash
# テスト環境を構築
docker compose -f compose.test.yml up -d

# テスト実行（S3 アップロードをスキップ）
docker build -t mariadb-dump-to-s3:test -f Dockerfile ..
docker run --rm \
  --network mariadb-backup_default \
  -e DB_HOST=test-mariadb \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=testpass \
  -e DB_NAME=testdb \
  -e BACKUP_NAME=test_backup \
  -e SKIP_S3_UPLOAD=true \
  mariadb-dump-to-s3:test

# 後片付け
docker compose -f compose.test.yml down -v
```

## リリース方法

新しいバージョンをリリースするには、以下の形式でタグを作成してプッシュします：

```bash
# タグを作成（MariaDBバージョンは含めない）
git tag mariadb-dump-to-s3-v0.0.5
git push origin mariadb-dump-to-s3-v0.0.5
```

GitHub Actions により、以下の Docker イメージタグが自動的にビルド・プッシュされます：

- `ghcr.io/<repo>/mariadb-dump-to-s3:latest-maria11` - 最新版（メジャーバージョン）
- `ghcr.io/<repo>/mariadb-dump-to-s3:v0.0.5-maria11` - 指定バージョン（メジャーバージョン）
- `ghcr.io/<repo>/mariadb-dump-to-s3:v0.0.5-maria11.4` - 指定バージョン（フルバージョン）

> **Note**: タグ名には MariaDB のバージョンを含めないでください。ビルド時に自動的に MariaDB のメジャーバージョン（`11`）とフルバージョン（`11.4`）が付与されます。
