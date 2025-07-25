
---

### 1. ファイル転送とそれに伴うデータ加工

**目的:** 異なるシステム間でデータ連携を行う際、ファイル転送とそれに続くデータ形式の変換、不要データ除去などを自動化します [会話履歴]。これにより、人的コストを削減し、貴重な人的資源をより創造的な業務に集中させることが可能になります。

**処理例の詳細:**
この例では、外部の取引先システムからFTPで売上データ（CSV形式、UTF-8）を受信し、自社システムで取り込み可能な形式（Shift-JIS、特定項目のみ抽出、ヘッダー/フッター除去）に加工し、最終的にデータインポートフォルダに配置する一連のプロセスを自動化します。

1.  **ファイル受信監視ジョブ:**
    *   **JP1/AJS3ユニット:** イベントジョブの一種であるファイル監視ジョブ。
    *   **設定:** `C:\Incoming\SalesData\` フォルダを監視対象とし、新しいCSVファイル（例: `sales_*.csv`）が作成されるたびに起動するよう設定します。ファイル監視ジョブは、監視対象ファイルを監視している間の情報を随時退避し、JP1/AJS3サービスが一時的に停止した場合でも監視状態を引き継ぐことが推奨されます。
    *   **引き継ぎ情報:** 検知したファイルのフルパスを、後続のジョブネットに引き継ぎ情報（マクロ変数）として渡します。

2.  **売上データ処理ジョブネット（トリガー起動）:**
    *   ファイル監視ジョブによってトリガーされるジョブネットとして定義します。

    a.  **受信ファイル移動・準備ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** ファイル監視ジョブから引き継いだファイルパスを使用して、受信したCSVファイルを一時処理フォルダ（例: `C:\Processing\SalesData\`）に移動します。これにより、同じファイルが再度監視によって検知されるのを防ぎます。移動後、ファイル名とパスを次のジョブに渡すためのマクロ変数を更新します。
        *   **スクリプト例 (`move_received_file.bat`):**
            ```batch
            @echo off
            REM 受信したファイルパスをマクロ変数から取得
            set "RECEIVED_FILE_PATH=%AJS2_MACRO_RECEIVED_FILE%"
            REM 例: %AJS2_MACRO_RECEIVED_FILE% が "C:\Incoming\SalesData\sales_20231026.csv"
            REM といった値を持っていると仮定

            set "PROCESSING_DIR=C:\Processing\SalesData\"
            set "ARCHIVE_DIR=C:\Archive\SalesData\Original\"
            set "PROCESSED_FILENAME_PREFIX=processed_sales_"

            REM ファイル名のみを抽出
            for %%f in ("%RECEIVED_FILE_PATH%") do set "FILENAME=%%~nxf"
            set "NEW_FILE_PATH=%PROCESSING_DIR%%FILENAME%"
            set "ARCHIVE_FILE_PATH=%ARCHIVE_DIR%%FILENAME%"

            echo Moving "%RECEIVED_FILE_PATH%" to "%NEW_FILE_PATH%"...
            move "%RECEIVED_FILE_PATH%" "%NEW_FILE_PATH%"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to move file!
                exit /b 1
            )

            echo Creating processed filename for macro variable...
            for /f "tokens=1-3 delims=/ " %%a in ('echo %date%') do set "CURRENT_DATE=%%c%%a%%b"
            for /f "tokens=1-2 delims=:" %%a in ('echo %time%') do set "CURRENT_TIME=%%a%%b"
            set "PROCESSED_FILENAME=%PROCESSED_FILENAME_PREFIX%%CURRENT_DATE%%CURRENT_TIME%.csv"
            echo Processed Filename: %PROCESSED_FILENAME%

            REM 後続ジョブに引き継ぐ情報を標準出力に出力
            REM JP1/AJS3は、標準出力から必要な情報を切り出して後続ジョブに引き継ぐことができます
            echo AJS2ENV:FILE_TO_PROCESS=%NEW_FILE_PATH%
            echo AJS2ENV:PROCESSED_OUTPUT_FILENAME=%PROCESSED_FILENAME%
            echo AJS2ENV:ORIGINAL_ARCHIVE_PATH=%ARCHIVE_FILE_PATH%

            echo File preparation completed.
            exit /b 0
            ```

    b.  **データ加工・変換ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** `move_received_file.bat` から引き継いだ`FILE_TO_PROCESS` (入力ファイルパス) と `PROCESSED_OUTPUT_FILENAME` (出力ファイル名) を使用して、データ加工スクリプトを実行します。このスクリプトは、文字コード変換、ヘッダー/フッター除去、特定列の抽出、不要行のフィルタリングを行います。加工後のファイルは、最終的なインポートフォルダ（例: `C:\Import\SalesData\`）に保存されます。
        *   **スクリプト例 (`process_sales_data.bat`):**
            ```batch
            @echo off
            REM 前のジョブから引き継いだマクロ変数を取得
            set "INPUT_FILE_PATH=%AJS2_MACRO_FILE_TO_PROCESS%"
            set "PROCESSED_OUTPUT_FILENAME=%AJS2_MACRO_PROCESSED_OUTPUT_FILENAME%"
            set "ORIGINAL_ARCHIVE_PATH=%AJS2_MACRO_ORIGINAL_ARCHIVE_PATH%"

            set "OUTPUT_DIR=C:\Import\SalesData\"
            set "TEMP_OUTPUT_FILE=%OUTPUT_DIR%temp_%PROCESSED_OUTPUT_FILENAME%"
            set "FINAL_OUTPUT_FILE=%OUTPUT_DIR%%PROCESSED_OUTPUT_FILENAME%"

            if not exist "%INPUT_FILE_PATH%" (
                echo ERROR: Input file "%INPUT_FILE_PATH%" not found!
                exit /b 1
            )

            echo Processing data from "%INPUT_FILE_PATH%"...

            REM --- 1. 文字コード変換 (UTF-8 to Shift-JIS) ---
            REM PowerShell を使用して文字コード変換
            powershell -Command "Get-Content -Path '%INPUT_FILE_PATH%' -Encoding UTF8 | Set-Content -Path '%TEMP_OUTPUT_FILE%' -Encoding Default"
            if %errorlevel% neq 0 (
                echo ERROR: Character encoding conversion failed!
                exit /b 1
            )
            echo Character encoding converted to Shift-JIS.

            REM --- 2. ヘッダー/フッター除去と特定項目抽出 ---
            REM (例: CSVの1行目をヘッダーとして除去、最終行をフッターとして除去)
            REM (例: 特定の列 (例: 1,3,5列目) のみを抽出)
            REM この例では簡易的に、PowerShellで1行目と最終行を除外し、特定の列を抽出します。
            powershell -Command "Import-Csv '%TEMP_OUTPUT_FILE%' -Encoding Default | Select-Object -Skip 0 -Last ( (Import-Csv '%TEMP_OUTPUT_FILE%' -Encoding Default | Measure-Object).Count -1 ) | Select-Object 'ColumnA', 'ColumnC', 'ColumnE' | Export-Csv '%FINAL_OUTPUT_FILE%' -Encoding Default -NoTypeInformation -UseCulture -Force"
            REM 上記のSelect-Object -Skip 0 -Lastはヘッダー除去とフッター除去の簡易的な例です。
            REM 実際のファイル構造に合わせて調整が必要です。
            REM あるいは、grep/awk for Windows などのツールを使用することも可能です。
            REM 例： findstr /v /b /c:"Header" "%TEMP_OUTPUT_FILE%" | findstr /v /e /c:"Footer" > "%FINAL_OUTPUT_FILE%"
            if %errorlevel% neq 0 (
                echo ERROR: Data extraction and filtering failed!
                del "%TEMP_OUTPUT_FILE%"
                exit /b 1
            )
            echo Data extraction and filtering completed.

            REM 一時ファイルの削除
            del "%TEMP_OUTPUT_FILE%"

            echo Data processing completed. Processed file saved to "%FINAL_OUTPUT_FILE%".
            exit /b 0
            ```

    c.  **加工後ファイル品質チェックジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 加工後のファイル（`FINAL_OUTPUT_FILE`）の存在確認、ファイルサイズチェック（0バイトでないか）、簡易的なデータフォーマットチェックなどを行います。問題があれば異常終了し、後続処理を止めます。
        *   **スクリプト例 (`check_processed_file.bat`):**
            ```batch
            @echo off
            set "PROCESSED_FILE_PATH=%AJS2_MACRO_PROCESSED_OUTPUT_FILENAME%"
            set "OUTPUT_DIR=C:\Import\SalesData\"
            set "FINAL_OUTPUT_FILE=%OUTPUT_DIR%%PROCESSED_FILE_PATH%"

            if not exist "%FINAL_OUTPUT_FILE%" (
                echo ERROR: Processed file "%FINAL_OUTPUT_FILE%" does not exist!
                exit /b 1
            )

            for %%I in ("%FINAL_OUTPUT_FILE%") do set FILE_SIZE=%%~zI
            if %FILE_SIZE% equ 0 (
                echo ERROR: Processed file "%FINAL_OUTPUT_FILE%" is empty!
                exit /b 1
            )

            echo File "%FINAL_OUTPUT_FILE%" is ready for import.
            exit /b 0
            ```

    d.  **受信ファイルアーカイブジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 加工が成功した場合、元の受信ファイルをアーカイブフォルダ（例: `C:\Archive\SalesData\Original\`）に移動します。
        *   **スクリプト例 (`archive_original_file.bat`):**
            ```batch
            @echo off
            set "INPUT_FILE_PATH=%AJS2_MACRO_FILE_TO_PROCESS%"
            set "ORIGINAL_ARCHIVE_PATH=%AJS2_MACRO_ORIGINAL_ARCHIVE_PATH%"

            echo Archiving original file "%INPUT_FILE_PATH%" to "%ORIGINAL_ARCHIVE_PATH%"...
            move "%INPUT_FILE_PATH%" "%ORIGINAL_ARCHIVE_PATH%"
            if %errorlevel% neq 0 (
                echo WARNING: Failed to archive original file "%INPUT_FILE_PATH%". It might have been processed already.
                REM 警告として続行するが、必要に応じてエラーにすることも可能
                exit /b 0
            )
            echo Original file archived.
            exit /b 0
            ```

    e.  **処理完了通知ジョブ（正常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 一連のファイル転送とデータ加工が正常に完了したことを、関係者にメールで通知します。メール本文には、処理されたファイル名、パス、処理日時などを含めることができます。

    f.  **処理エラー通知ジョブ（異常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 上記のいずれかのジョブが異常終了した場合に、アラートメールをシステム管理者に送信します。エラー発生時刻、ジョブネット名、異常終了したジョブ名、エラーコードなどを記載し、迅速な対応を促します。

**JP1/AJS3の関連機能:**
*   **ジョブネットコネクタ:** 異なるジョブネット間で実行順序を制御したい場合に使用できます。
*   **マクロ変数:** イベントジョブで受信したイベント情報（ファイル名など）を後続ジョブ中に変数（マクロ変数）として定義し、引き継ぐことが可能です。
*   **起動条件の有効範囲:** イベントジョブに打ち切り時間を指定したり、起動条件付きジョブネットの有効範囲を絶対時刻で指定したりして、監視期間を制御できます。
*   **実行エージェントグループ:** 複数のエージェントホスト間でジョブの実行を負荷分散させる運用を行う場合、実行エージェントグループを指定できます。

---

### 2. データベースへのデータ登録・更新

**目的:** ファイル転送で受け取ったデータや、他のシステムから収集したデータをデータベースに登録・更新する処理を自動化します [会話履歴]。夜間バッチ処理として、日次の売上データを集計し、販売管理データベースに登録するシナリオを想定します。

**処理例の詳細:**
データ加工された売上データを、販売管理データベースのマスターテーブルに集計・登録します。

1.  **日次売上データ取り込みジョブネット（時間指定起動）:**
    *   **JP1/AJS3ユニット:** ルートジョブネット。
    *   **設定:** 毎日深夜3時など、データ加工が完了し、かつ業務に影響の少ない時間帯に実行されるようスケジュールします。

    a.  **データファイル存在確認ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 前の「ファイル転送とデータ加工」処理で出力された最終的な加工済みファイル（例: `C:\Import\SalesData\processed_sales_*.csv`）が存在するかを確認します。存在しない場合、またはファイルサイズが0の場合、異常終了します。
        *   **スクリプト例 (`check_import_file.bat`):**
            ```batch
            @echo off
            set "IMPORT_FILE_DIR=C:\Import\SalesData\"
            REM 最新のprocessed_sales_YYYYMMDDHHMM.csvファイルを取得
            for /f "delims=" %%i in ('dir /b /o-d "%IMPORT_FILE_DIR%processed_sales_*.csv"') do (
                set "LATEST_IMPORT_FILE=%%i"
                goto :found_file
            )
            echo ERROR: No sales data file found in "%IMPORT_FILE_DIR%".
            exit /b 1

            :found_file
            set "FULL_IMPORT_FILE_PATH=%IMPORT_FILE_DIR%%LATEST_IMPORT_FILE%"
            echo Checking file: "%FULL_IMPORT_FILE_PATH%"

            if not exist "%FULL_IMPORT_FILE_PATH%" (
                echo ERROR: File "%FULL_IMPORT_FILE_PATH%" does not exist.
                exit /b 1
            )

            for %%I in ("%FULL_IMPORT_FILE_PATH%") do set FILE_SIZE=%%~zI
            if %FILE_SIZE% equ 0 (
                echo ERROR: File "%FULL_IMPORT_FILE_PATH%" is empty.
                exit /b 1
            )

            echo AJS2ENV:DATA_FILE_TO_IMPORT=%FULL_IMPORT_FILE_PATH%
            echo File check completed successfully.
            exit /b 0
            ```

    b.  **データインポートジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** `check_import_file.bat` から引き継いだ `DATA_FILE_TO_IMPORT` を使用して、加工済みCSVファイルをデータベースのステージングテーブルにインポートします。データベースの種類に応じたツール（例: SQL*Loader、bcpコマンド、またはカスタムインポートアプリケーション）を使用します。
        *   **スクリプト例 (`import_data_to_staging.bat`):** (SQL Serverのbcpコマンドを例に)
            ```batch
            @echo off
            set "DATA_FILE_TO_IMPORT=%AJS2_MACRO_DATA_FILE_TO_IMPORT%"

            set "DB_SERVER=YourDbServer"
            set "DB_NAME=SalesDB"
            set "DB_USER=your_db_user"
            set "DB_PASSWORD=your_db_password"
            set "STAGING_TABLE=StagingSalesData"
            set "FORMAT_FILE=C:\Scripts\SalesData.fmt" REM bcp形式ファイル

            echo Importing data from "%DATA_FILE_TO_IMPORT%" to %DB_SERVER%.%DB_NAME%.%STAGING_TABLE%...

            bcp %STAGING_TABLE% in "%DATA_FILE_TO_IMPORT%" -S %DB_SERVER% -d %DB_NAME% -U %DB_USER% -P %DB_PASSWORD% -f "%FORMAT_FILE%" -c -t,
            if %errorlevel% neq 0 (
                echo ERROR: BCP import failed!
                exit /b 1
            )

            echo Data imported to staging table.
            exit /b 0
            ```

    c.  **データ集計・更新ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** ステージングテーブルのデータを集計し、販売管理データベースのマスターテーブル（例: `DailySales`）に登録・更新するSQLスクリプトを実行します。トランザクション管理を行い、エラー時にはロールバックするように設計します。
        *   **スクリプト例 (`aggregate_and_update_db.bat`):** (SQL Serverのsqlcmdを例に)
            ```batch
            @echo off
            set "DB_SERVER=YourDbServer"
            set "DB_NAME=SalesDB"
            set "DB_USER=your_db_user"
            set "DB_PASSWORD=your_db_password"
            set "SQL_SCRIPT=C:\Scripts\aggregate_sales.sql"

            echo Executing SQL script for aggregation and update...

            sqlcmd -S %DB_SERVER% -d %DB_NAME% -U %DB_USER% -P %DB_PASSWORD% -i "%SQL_SCRIPT%"
            if %errorlevel% neq 0 (
                echo ERROR: SQL script execution failed!
                exit /b 1
            )

            echo Database aggregation and update completed.
            exit /b 0
            ```
        *   **SQLスクリプト例 (`aggregate_sales.sql`):**
            ```sql
            -- aggregate_sales.sql
            BEGIN TRANSACTION;

            -- ステージングテーブルのデータで日次売上を更新または挿入
            MERGE DailySales AS target
            USING (
                SELECT SaleDate, ProductID, SUM(Quantity) AS TotalQuantity, SUM(Amount) AS TotalAmount
                FROM StagingSalesData
                GROUP BY SaleDate, ProductID
            ) AS source
            ON (target.SaleDate = source.SaleDate AND target.ProductID = source.ProductID)
            WHEN MATCHED THEN
                UPDATE SET TotalQuantity = target.TotalQuantity + source.TotalQuantity,
                           TotalAmount = target.TotalAmount + source.TotalAmount
            WHEN NOT MATCHED THEN
                INSERT (SaleDate, ProductID, TotalQuantity, TotalAmount)
                VALUES (source.SaleDate, source.ProductID, source.TotalQuantity, source.TotalAmount);

            -- ステージングテーブルをクリア
            TRUNCATE TABLE StagingSalesData;

            COMMIT TRANSACTION;
            ```

    d.  **履歴ログ更新ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** データ登録・更新の成功を、社内履歴管理用のログテーブルに記録します。実行日時、処理対象期間、処理件数などを記録します。

    e.  **取り込み完了通知ジョブ（正常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 日次データ取り込みが正常に完了したことを関係者（例: 営業部門）に通知します。

    f.  **取り込み異常通知ジョブ（異常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 上記のいずれかのジョブが異常終了した場合に、アラートメールをシステム管理者に送信します。異常終了したジョブ名、エラーコード、データベースのログ出力先などを記載します。

**JP1/AJS3の関連機能:**
*   **多重起動とスケジューリング方式:** 周期的に実行されるジョブネットで、前回の処理が終了しなかった場合に、次の実行予定時刻に多重に実行させるか、スキップさせるかなどを設定できます。
*   **打ち切り時間:** ジョブの実行が開始されてからの経過時間によってジョブの実行を打ち切る設定が可能です。これにより、何らかの要因で処理が終了しない場合の長時間の滞留を防ぎ、原因調査や異常通知などの後続処理を自動実行させることができます。
*   **運用プロファイル:** スケジューラーサービスごとに運用環境設定（例えば、日次処理と月次処理で異なるログ出力設定など）を切り替えたい場合に利用できます。

---

### 3. 定期的なバックアップ処理

**目的:** システムの安定運用のために、データベースや重要なファイルの定期的なバックアップは不可欠です [会話履歴]。JP1/AJS3を利用することで、業務時間外の深夜などに自動でバックアップを取得し、世代管理を行うといった運用が可能です [会話履歴]。

**処理例の詳細:**
この例では、販売管理データベースと関連するデータファイルの毎日深夜のバックアップを自動化し、バックアップファイルの世代管理（7世代保持）と別のストレージへのコピーまでを行います。

1.  **システムバックアップジョブネット（時間指定起動）:**
    *   **JP1/AJS3ユニット:** ルートジョブネット。
    *   **設定:** 毎日深夜2時など、システムの負荷が低い時間帯に実行されるようスケジュールします。

    a.  **アプリケーションサービス停止ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** データベースの整合性を保つため、バックアップ対象の販売管理アプリケーションサービスおよびデータベースサービスを一時的に停止します。
        *   **スクリプト例 (`stop_app_db_service.bat`):**
            ```batch
            @echo off
            echo Stopping Sales Application Service...
            net stop "SalesApplicationService"
            if %errorlevel% neq 0 (
                echo WARNING: Sales Application Service might not be running or failed to stop. Continuing...
            )

            echo Stopping Sales Database Service...
            net stop "SalesDatabaseService"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to stop Sales Database Service! Aborting backup.
                exit /b 1
            )
            echo Services stopped.
            exit /b 0
            ```

    b.  **データベースバックアップジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 販売管理データベースのオンラインバックアップ（またはオフラインバックアップ、上記のサービス停止と組み合わせる）を実行します。
        *   **スクリプト例 (`backup_database.bat`):** (SQL Serverの`sqlcmd`と`BACKUP DATABASE`を例に)
            ```batch
            @echo off
            set "DB_SERVER=YourDbServer"
            set "DB_NAME=SalesDB"
            set "BACKUP_DIR=C:\Backup\Database\"
            set "BACKUP_FILENAME_PREFIX=SalesDB_FullBackup_"

            REM バックアップファイル名にタイムスタンプを付与
            for /f "tokens=1-3 delims=/ " %%a in ('echo %date%') do set "CURRENT_DATE=%%c%%a%%b"
            for /f "tokens=1-2 delims=:" %%a in ('echo %time%') do set "CURRENT_TIME=%%a%%b"
            set "BACKUP_FILE=%BACKUP_DIR%%BACKUP_FILENAME_PREFIX%%CURRENT_DATE%_%CURRENT_TIME%.bak"

            echo Backing up database %DB_NAME% to "%BACKUP_FILE%"...

            sqlcmd -S %DB_SERVER% -Q "BACKUP DATABASE %DB_NAME% TO DISK = N'%BACKUP_FILE%' WITH NOFORMAT, NOINIT, NAME = N'%DB_NAME%_FullBackup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
            if %errorlevel% neq 0 (
                echo ERROR: Database backup failed!
                exit /b 1
            )

            echo Database backup completed successfully to "%BACKUP_FILE%".
            echo AJS2ENV:DB_BACKUP_FILE_PATH=%BACKUP_FILE%
            exit /b 0
            ```

    c.  **ファイルシステムバックアップジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 重要な設定ファイルやデータファイルが格納されているフォルダを、別のバックアップディレクトリにコピーします。
        *   **スクリプト例 (`backup_files.bat`):**
            ```batch
            @echo off
            set "SOURCE_DIR=C:\SalesApp\Data"
            set "TARGET_DIR=C:\Backup\Files\"

            REM バックアップフォルダにタイムスタンプを付与
            for /f "tokens=1-3 delims=/ " %%a in ('echo %date%') do set "CURRENT_DATE=%%c%%a%%b"
            for /f "tokens=1-2 delims=:" %%a in ('echo %time%') do set "CURRENT_TIME=%%a%%b"
            set "BACKUP_FOLDER_NAME=SalesFiles_%CURRENT_DATE%_%CURRENT_TIME%"
            set "FINAL_TARGET_DIR=%TARGET_DIR%%BACKUP_FOLDER_NAME%"

            echo Copying files from "%SOURCE_DIR%" to "%FINAL_TARGET_DIR%"...

            robocopy "%SOURCE_DIR%" "%FINAL_TARGET_DIR%" /E /COPYALL /DCOPY:T /R:3 /W:10 /LOG+:"%FINAL_TARGET_DIR%\robocopy.log"
            REM /E:空のディレクトリを含むサブディレクトリをコピー
            REM /COPYALL:すべてのファイル情報をコピー (属性、タイムスタンプ、ACLなど)
            REM /DCOPY:T:ディレクトリのタイムスタンプをコピー
            REM /R:3:コピー失敗時のリトライ回数 (3回)
            REM /W:10:リトライ間隔 (10秒)
            REM /LOG+:"%FINAL_TARGET_DIR%\robocopy.log":ログファイルに追加書き込み

            if %errorlevel% ge 8 ( REM robocopyは成功でも0以外を返す場合がある (8はエラー)
                echo ERROR: File backup failed!
                exit /b 1
            )

            echo File backup completed successfully to "%FINAL_TARGET_DIR%".
            echo AJS2ENV:FILE_BACKUP_DIR_PATH=%FINAL_TARGET_DIR%
            exit /b 0
            ```

    d.  **アプリケーションサービス起動ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** バックアップ完了後、停止していたデータベースサービスおよびアプリケーションサービスを再起動します。
        *   **スクリプト例 (`start_app_db_service.bat`):**
            ```batch
            @echo off
            echo Starting Sales Database Service...
            net start "SalesDatabaseService"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to start Sales Database Service! Manual intervention required.
                exit /b 1
            )

            echo Starting Sales Application Service...
            net start "SalesApplicationService"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to start Sales Application Service! Manual intervention required.
                exit /b 1
            )
            echo Services started.
            exit /b 0
            ```

    e.  **リモートストレージ転送ジョブ:**
        *   **JP1/AJS3ユニット:** JP1/FTPカスタムジョブ、または標準ジョブでFTP/SFTPコマンドを呼び出す。
        *   **処理内容:** 作成されたデータベースバックアップファイルとファイルシステムバックアップファイルを、遠隔地のストレージ（NAS、別のサーバーなど）に転送します。セキュアな転送（SFTPなど）を推奨します。
        *   **スクリプト例 (`transfer_backup_to_remote.bat`):** (Windows OpenSSHのsftpコマンドを例に)
            ```batch
            @echo off
            set "DB_BACKUP_FILE=%AJS2_MACRO_DB_BACKUP_FILE_PATH%"
            set "FILE_BACKUP_DIR=%AJS2_MACRO_FILE_BACKUP_DIR_PATH%"

            set "REMOTE_HOST=remote.backup.server.com"
            set "REMOTE_USER=backup_user"
            set "REMOTE_PATH=/backups/daily/"
            set "SFTP_KEY_PATH=C:\Users\backupuser\.ssh\id_rsa"

            echo Transferring "%DB_BACKUP_FILE%" to %REMOTE_HOST%:%REMOTE_PATH%...
            sftp -i "%SFTP_KEY_PATH%" "%REMOTE_USER%@%REMOTE_HOST%" <<EOF
            put "%DB_BACKUP_FILE%" "%REMOTE_PATH%"
            bye
            EOF
            if %errorlevel% neq 0 (
                echo ERROR: SFTP transfer of DB backup failed!
                exit /b 1
            )

            echo Transferring "%FILE_BACKUP_DIR%" to %REMOTE_HOST%:%REMOTE_PATH%...
            REM robocopyでリモートパスに直接コピーすることも可能だが、ここではSFTPの例を拡張
            REM SFTPでディレクトリを再帰的にputするのは複雑なため、通常はzipで固めてから転送
            set "ZIPPED_FILE_BACKUP=%TEMP%\%~nxf_backup.zip"
            powershell -Command "Compress-Archive -Path '%FILE_BACKUP_DIR%' -DestinationPath '%ZIPPED_FILE_BACKUP%' -Force"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to zip file backup directory!
                exit /b 1
            )

            sftp -i "%SFTP_KEY_PATH%" "%REMOTE_USER%@%REMOTE_HOST%" <<EOF
            put "%ZIPPED_FILE_BACKUP%" "%REMOTE_PATH%"
            bye
            EOF
            if %errorlevel% neq 0 (
                echo ERROR: SFTP transfer of file backup failed!
                del "%ZIPPED_FILE_BACKUP%"
                exit /b 1
            )
            del "%ZIPPED_FILE_BACKUP%"

            echo All backups transferred to remote storage.
            exit /b 0
            ```

    f.  **バックアップ世代管理ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** ローカルのバックアップディレクトリ内で、指定した世代数（例: 7世代）を超える古いバックアップファイルを削除します。
        *   **スクリプト例 (`manage_backup_generations.bat`):**
            ```batch
            @echo off
            set "BACKUP_DIR_DB=C:\Backup\Database\"
            set "BACKUP_DIR_FILES=C:\Backup\Files\"
            set "RETENTION_DAYS=7"

            echo Deleting old database backups in "%BACKUP_DIR_DB%" (older than %RETENTION_DAYS% days)...
            forfiles /p "%BACKUP_DIR_DB%" /m SalesDB_FullBackup_*.bak /d -%RETENTION_DAYS% /c "cmd /c del @file"
            if %errorlevel% neq 0 (
                echo WARNING: Error or no files found for deletion in DB backup.
            )

            echo Deleting old file system backups in "%BACKUP_DIR_FILES%" (older than %RETENTION_DAYS% days)...
            REM robocopyでディレクトリごとコピーしているので、ディレクトリを削除
            for /d %%d in ("%BACKUP_DIR_FILES%SalesFiles_*") do (
                forfiles /p "%%d" /d -%RETENTION_DAYS% /c "cmd /c if @isdir==TRUE rmdir /s /q %%d"
                REM rmdirは空でないと削除できないので、ここでは簡易的な例。
                REM PowerShellのRemove-Item -Recurse -Forceを使用すると確実。
            )
            echo Backup generation management completed.
            exit /b 0
            ```

    g.  **バックアップ完了通知ジョブ（正常時/異常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** バックアップ処理の成功または失敗をシステム管理者に通知します。失敗時には詳細なエラー情報を付与し、迅速な原因究明と対応を支援します。

**JP1/AJS3の関連機能:**
*   **ディザスター・リカバリー運用:** JP1/AJS3は、大規模災害などに備え、通常運用するシステムと同じ環境のシステムを遠隔地に用意し、共有ディスクの内容をコピーすることでディザスター・リカバリーに対応しています。バックアップ処理はこの運用を支える重要な要素です。
*   **バックアップ強化機能:** JP1/AJS3自身の組み込みDBのバックアップとリカバリーを強化する機能も提供されています。これにより、ジョブ実行ごとに変化するパラメーターの値（マクロ変数や引き継ぎ情報）などもデータベースに格納され、運用中のバックアップが可能になります。
*   **ログの出力・監視:** 各ジョブの実行ログや稼働状況ログを適切に設定し、監視することで、バックアップ処理の進捗や問題発生を早期に検知できます.

---

### 4. 帳票作成と出力

**目的:** データベースに蓄積されたデータをもとに、日次や月次で定型的なレポート（帳票）を作成し、PDFファイルとして保存したり、プリンターで印刷したりする処理を自動化します [会話履歴]。

**処理例の詳細:**
毎月1日の早朝に、前月の売上データを集計し、月次売上報告書をPDFとして生成、特定のフォルダに保存し、同時に経理部のプリンターへ印刷するシナリオです。

1.  **月次売上報告書作成ジョブネット（時間指定起動）:**
    *   **JP1/AJS3ユニット:** ルートジョブネット。
    *   **設定:** 毎月1日の早朝（例: 午前4時）に実行されるようスケジュールします。これはカレンダー定義と組み合わせて設定します。JP1/AJS3では、運用日・休業日を定義し、カレンダーを作成できます。

    a.  **データ抽出ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 販売管理データベースから前月の売上データを抽出し、CSV形式の中間ファイルとして出力します。抽出期間は、ジョブ実行日時から動的に計算します。
        *   **スクリプト例 (`extract_monthly_sales.bat`):**
            ```batch
            @echo off
            set "DB_SERVER=YourDbServer"
            set "DB_NAME=SalesDB"
            set "DB_USER=your_db_user"
            set "DB_PASSWORD=your_db_password"
            set "OUTPUT_DIR=C:\Reports\MonthlySales\RawData\"

            REM 前月の開始日と終了日を計算 (PowerShellを使用)
            for /f "usebackq tokens=*" %%i in (`powershell -Command "& { $today = Get-Date; $firstOfThisMonth = $today.AddDays(1 - $today.Day); $firstOfLastMonth = $firstOfThisMonth.AddMonths(-1); $lastOfLastMonth = $firstOfThisMonth.AddDays(-1); Write-Output ($firstOfLastMonth.ToString('yyyy-MM-dd') + ' ' + $lastOfLastMonth.ToString('yyyy-MM-dd'))}"`) do set "DATE_RANGE=%%i"

            for /f "tokens=1,2" %%a in ("%DATE_RANGE%") do (
                set "START_DATE=%%a"
                set "END_DATE=%%b"
            )

            set "OUTPUT_FILE=%OUTPUT_DIR%monthly_sales_%START_DATE%_to_%END_DATE%.csv"

            echo Extracting monthly sales data from %START_DATE% to %END_DATE%...

            REM SQL Serverの例: sqlcmdでSQLクエリを実行し、CSVに出力
            sqlcmd -S %DB_SERVER% -d %DB_NAME% -U %DB_USER% -P %DB_PASSWORD% -o "%OUTPUT_FILE%" -h-1 -s"," -W -Q "SELECT SaleDate, ProductID, CustomerID, Quantity, Amount FROM DailySales WHERE SaleDate BETWEEN '%START_DATE%' AND '%END_DATE%' ORDER BY SaleDate, ProductID;"
            if %errorlevel% neq 0 (
                echo ERROR: Data extraction failed!
                exit /b 1
            )

            if not exist "%OUTPUT_FILE%" (
                echo ERROR: Output file "%OUTPUT_FILE%" was not created.
                exit /b 1
            )

            echo Data extracted to "%OUTPUT_FILE%".
            echo AJS2ENV:MONTHLY_SALES_CSV=%OUTPUT_FILE%
            exit /b 0
            ```

    b.  **帳票生成ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** `extract_monthly_sales.bat` から引き継いだ `MONTHLY_SALES_CSV` を使用して、帳票生成アプリケーション（例: Pythonスクリプト、Excelマクロ、専用の帳票ツールなど）を実行し、月次売上報告書をPDFファイルとして出力します。
        *   **スクリプト例 (`generate_report_pdf.bat`):** (Pythonスクリプトを呼び出す例)
            ```batch
            @echo off
            set "INPUT_CSV_FILE=%AJS2_MACRO_MONTHLY_SALES_CSV%"
            set "REPORT_OUTPUT_DIR=C:\Reports\MonthlySales\PDF\"

            REM PDFファイル名にタイムスタンプを付与
            for /f "tokens=1-3 delims=/ " %%a in ('echo %date%') do set "CURRENT_DATE=%%c%%a%%b"
            for /f "tokens=1-2 delims=:" %%a in ('echo %time%') do set "CURRENT_TIME=%%a%%b"
            set "REPORT_FILENAME=MonthlySales_Report_%CURRENT_DATE%_%CURRENT_TIME%.pdf"
            set "FINAL_REPORT_PATH=%REPORT_OUTPUT_DIR%%REPORT_FILENAME%"

            if not exist "%INPUT_CSV_FILE%" (
                echo ERROR: Input CSV file "%INPUT_CSV_FILE%" not found!
                exit /b 1
            )

            echo Generating PDF report from "%INPUT_CSV_FILE%"...
            python C:\Scripts\generate_sales_report.py "%INPUT_CSV_FILE%" "%FINAL_REPORT_PATH%"
            if %errorlevel% neq 0 (
                echo ERROR: PDF report generation failed!
                exit /b 1
            )

            if not exist "%FINAL_REPORT_PATH%" (
                echo ERROR: Generated PDF file "%FINAL_REPORT_PATH%" not found.
                exit /b 1
            )

            echo PDF report generated: "%FINAL_REPORT_PATH%".
            echo AJS2ENV:GENERATED_REPORT_PDF=%FINAL_REPORT_PATH%
            exit /b 0
            ```
        *   **Pythonスクリプト例 (`generate_sales_report.py`):** (簡易的な例、pandasとreportlabが必要)
            ```python
            # generate_sales_report.py
            import pandas as pd
            from reportlab.platypus import SimpleDocTemplate, Table, Paragraph
            from reportlab.lib.styles import getSampleStyleSheet
            from reportlab.lib import colors
            from reportlab.lib.pagesizes import letter
            import sys

            if len(sys.argv) != 3:
                print("Usage: python generate_sales_report.py <input_csv_path> <output_pdf_path>")
                sys.exit(1)

            input_csv_path = sys.argv
            output_pdf_path = sys.argv

            try:
                df = pd.read_csv(input_csv_path)
            except Exception as e:
                print(f"Error reading CSV: {e}")
                sys.exit(1)

            doc = SimpleDocTemplate(output_pdf_path, pagesize=letter)
            styles = getSampleStyleSheet()
            story = []

            # Title
            story.append(Paragraph("Monthly Sales Report", styles['h1']))
            story.append(Paragraph(f"Report Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}", styles['Normal']))
            story.append(Paragraph("<br/>", styles['Normal']))

            # Convert DataFrame to list of lists for ReportLab Table
            data = [df.columns.tolist()] + df.values.tolist()

            table_style = [
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]

            table = Table(data, style=table_style)
            story.append(table)

            try:
                doc.build(story)
                print(f"PDF report successfully generated at {output_pdf_path}")
            except Exception as e:
                print(f"Error building PDF: {e}")
                sys.exit(1)

            sys.exit(0)
            ```

    c.  **帳票ファイル保存ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 生成されたPDFファイルを、共有ネットワークフォルダ（例: `\\FileServer\Reports\MonthlySales\`）に保存します。ファイル名にはタイムスタンプを含め、世代管理が容易になるようにします。

    d.  **帳票印刷ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** 生成されたPDFファイルを、指定されたプリンター（例: 経理部のネットワークプリンター）に印刷します。
        *   **スクリプト例 (`print_report.bat`):**
            ```batch
            @echo off
            set "REPORT_FILE_PATH=%AJS2_MACRO_GENERATED_REPORT_PDF%"
            set "PRINTER_NAME=\\PrintServer\AccountingPrinter"

            if not exist "%REPORT_FILE_PATH%" (
                echo ERROR: Report file "%REPORT_FILE_PATH%" not found for printing!
                exit /b 1
            )

            echo Printing "%REPORT_FILE_PATH%" to "%PRINTER_NAME%"...
            REM Adobe Readerをインストールしている環境で、コマンドライン印刷の例
            "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe" /s /o /t "%REPORT_FILE_PATH%" "%PRINTER_NAME%"
            REM または、Windows標準のprintコマンド (PDFには非対応だがテキストファイルなら可)
            REM print /d:%PRINTER_NAME% "%REPORT_FILE_PATH%"
            REM または、より汎用的なPowershellでの印刷
            REM powershell -Command "& { $file = '%REPORT_FILE_PATH%'; $printer = '%PRINTER_NAME%'; $print_cmd = \"start-process -filepath '$file' -verb printto -argumentlist '$printer' \"; Invoke-Expression $print_cmd }"

            if %errorlevel% neq 0 (
                echo ERROR: Report printing failed!
                exit /b 1
            )

            echo Report printing completed.
            exit /b 0
            ```

    e.  **帳票作成完了通知ジョブ:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 帳票作成と出力が正常に完了したことを、関係者（例: 経理部長）に通知します。PDFファイルへのリンクや、PDFファイルを添付することも可能です。

    f.  **帳票作成異常通知ジョブ（異常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** いずれかのジョブが異常終了した場合、システム管理者にアラートメールを送信します。

**JP1/AJS3の関連機能:**
*   **運用上のカレンダー定義:** JP1/AJS3では、日曜日や祝祭日などの休日を含む運用カレンダーを作成できます。月初めの日付や1日のスケジュール計算基準時刻も設定可能で、これにより月次処理を正確にスケジュールできます。
*   **多重起動とスケジューリング方式:** 周期的に実行される帳票作成処理で、前回の処理がまだ実行中の場合に、次の処理を多重に実行させるか、またはスキップさせるかなどを設定できます。
*   **JP1/AJS3 - Print Option:** JP1/AJS3のジョブ運用情報をドキュメントとして出力する製品です。帳票出力機能とは直接連携しないものの、JP1/AJS3自体の運用状況をレポート化するのに役立ちます。

---

### 5. イベント監視とそれに連動した処理の実行

**目的:** 特定の事象（イベント）の発生をトリガーとして、後続の処理を自動的に開始させます [会話履歴]。例えば、特定のフォルダにファイルが作成されたことを監視し、そのファイルを処理するジョブを起動するといった使い方があります。

**処理例の詳細:**
この例では、外部システムからXML形式の注文データが特定のフォルダに送信されたことを検知し、そのデータを解析してデータベースに登録する一連の処理を自動化します。

1.  **注文ファイル監視ジョブ:**
    *   **JP1/AJS3ユニット:** イベントジョブ（ファイル監視ジョブ）。
    *   **設定:** `C:\Incoming\Orders\` フォルダを常時監視し、新しいXMLファイル（例: `order_*.xml`）が作成されることを検知するように設定します。
    *   **引き継ぎ情報:** 検知したXMLファイルのフルパスを、後続のジョブネットにマクロ変数として引き継ぎます。

2.  **注文データ処理ジョブネット（トリガー起動）:**
    *   注文ファイル監視ジョブによってトリガーされるジョブネットとして定義します。

    a.  **XMLファイル受領ログ・移動ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** イベントジョブから引き継いだXMLファイルのパスを基に、ファイルの受領をログに記録し、ファイルを処理中フォルダ（例: `C:\Processing\Orders\`）に移動します。これにより、ファイル監視ジョブが同じファイルを再度検知するのを防ぎます。
        *   **スクリプト例 (`log_and_move_xml.bat`):**
            ```batch
            @echo off
            set "RECEIVED_XML_PATH=%AJS2_MACRO_RECEIVED_FILE%"
            REM 例: %AJS2_MACRO_RECEIVED_FILE% が "C:\Incoming\Orders\order_A123.xml"
            set "PROCESSING_DIR=C:\Processing\Orders\"

            if not exist "%RECEIVED_XML_PATH%" (
                echo ERROR: Received XML file "%RECEIVED_XML_PATH%" not found!
                exit /b 1
            )

            REM ログに記録
            echo %DATE% %TIME% - Received XML file: "%RECEIVED_XML_PATH%" >> C:\Logs\order_processing.log

            REM ファイル名のみを抽出
            for %%f in ("%RECEIVED_XML_PATH%") do set "FILENAME=%%~nxf"
            set "NEW_XML_PATH=%PROCESSING_DIR%%FILENAME%"

            echo Moving "%RECEIVED_XML_PATH%" to "%NEW_XML_PATH%"...
            move "%RECEIVED_XML_PATH%" "%NEW_XML_PATH%"
            if %errorlevel% neq 0 (
                echo ERROR: Failed to move XML file!
                exit /b 1
            )

            echo File preparation completed.
            echo AJS2ENV:XML_FILE_TO_PROCESS=%NEW_XML_PATH%
            exit /b 0
            ```

    b.  **XMLデータ解析・登録ジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** `log_and_move_xml.bat` から引き継いだ `XML_FILE_TO_PROCESS` を使用して、XML解析スクリプトを実行します。このスクリプトは、XMLファイルから注文情報を抽出し、データベースの注文テーブルに登録します。
        *   **スクリプト例 (`process_order_xml.bat`):** (PowerShellで簡易XML解析とSQL Server挿入の例)
            ```batch
            @echo off
            set "XML_FILE_PATH=%AJS2_MACRO_XML_FILE_TO_PROCESS%"

            set "DB_SERVER=YourDbServer"
            set "DB_NAME=OrderDB"
            set "DB_USER=your_db_user"
            set "DB_PASSWORD=your_db_password"
            set "ORDER_TABLE=Orders"

            if not exist "%XML_FILE_PATH%" (
                echo ERROR: XML file "%XML_FILE_PATH%" not found for processing!
                exit /b 1
            )

            echo Parsing XML and inserting data into database from "%XML_FILE_PATH%"...

            powershell -Command "
                [xml]$xmlContent = Get-Content -Path '%XML_FILE_PATH%';
                $orderId = $xmlContent.Order.OrderId;
                $customerId = $xmlContent.Order.CustomerId;
                $orderDate = $xmlContent.Order.OrderDate;
                $totalAmount = $xmlContent.Order.TotalAmount;

                $sql = \"INSERT INTO %ORDER_TABLE% (OrderId, CustomerId, OrderDate, TotalAmount) VALUES ('$orderId', '$customerId', '$orderDate', '$totalAmount')\";
                $connectionString = \"Server=%DB_SERVER%;Database=%DB_NAME%;User ID=%DB_USER%;Password=%DB_PASSWORD%;\";
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString);
                $command = New-Object System.Data.SqlClient.SqlCommand($sql, $connection);
                try {
                    $connection.Open();
                    $command.ExecuteNonQuery();
                    Write-Host 'Data inserted successfully.';
                    exit 0;
                } catch {
                    Write-Host ('ERROR: ' + $_.Exception.Message);
                    exit 1;
                } finally {
                    $connection.Close();
                }
            "
            if %errorlevel% neq 0 (
                echo ERROR: XML parsing or database insertion failed!
                exit /b 1
            )

            echo Order data processed and inserted into DB.
            echo AJS2ENV:PROCESSED_ORDER_ID=%orderId%
            exit /b 0
            ```

    c.  **XMLファイルアーカイブジョブ:**
        *   **JP1/AJS3ユニット:** 標準ジョブ。
        *   **処理内容:** データベース登録が成功した後、処理済みのXMLファイルをアーカイブフォルダ（例: `C:\Archive\Orders\`）に移動します。
        *   **スクリプト例 (`archive_processed_xml.bat`):**
            ```batch
            @echo off
            set "PROCESSED_XML_PATH=%AJS2_MACRO_XML_FILE_TO_PROCESS%"
            set "ARCHIVE_DIR=C:\Archive\Orders\"

            REM ファイル名のみを抽出
            for %%f in ("%PROCESSED_XML_PATH%") do set "FILENAME=%%~nxf"
            set "ARCHIVE_XML_PATH=%ARCHIVE_DIR%%FILENAME%"

            echo Archiving processed XML file "%PROCESSED_XML_PATH%" to "%ARCHIVE_XML_PATH%"...
            move "%PROCESSED_XML_PATH%" "%ARCHIVE_XML_PATH%"
            if %errorlevel% neq 0 (
                echo WARNING: Failed to archive processed XML file. It might have been processed already.
                exit /b 0
            )
            echo Processed XML file archived.
            exit /b 0
            ```

    d.  **処理完了通知ジョブ（正常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** 注文データの取り込みとデータベース登録が正常に完了したことを関係部署に通知します。処理された注文IDや処理時間などの情報を含めます。

    e.  **処理エラー通知ジョブ（異常時）:**
        *   **JP1/AJS3ユニット:** アクションジョブ（メール送信）。
        *   **処理内容:** いずれかのジョブが異常終了した場合、システム管理者にアラートメールを送信します。エラーの原因となったファイル名、異常終了したジョブ名、エラーメッセージなどを記載し、迅速な調査を促します。

**JP1/AJS3の関連機能:**
*   **イベントジョブの種類:** ファイル監視ジョブ以外にも、JP1イベント受信監視ジョブ、実行間隔制御ジョブ、ログファイル監視ジョブ、メール受信監視ジョブ など、多様な事象を契機にジョブネットを実行できます。
*   **OR条件:** 起動条件に複数のイベントジョブを定義し、そのどれか一つでも発生したときにジョブネットを開始する「OR条件」を設定できます。これにより、例えばファイル到着と同時に手動イベントもトリガーとして受け付ける、といった柔軟な運用が可能です。
*   **ジョブ実行時のOSユーザー環境:** JP1/AJS3は、ジョブ実行時に指定されたOSユーザーのログインシェル（UNIXの場合）やアクセス権限に基づいて動作します。イベントジョブはJP1ユーザーには依存せず、JP1/AJS3サービスのアカウント権限に依存する特性があります。

---

