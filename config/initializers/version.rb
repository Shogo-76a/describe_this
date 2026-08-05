# VERSIONファイルの値を読み込み、スペースや改行を除去して定数に代入
version_file_path = Rails.root.join("VERSION")

APP_VERSION = if File.exist?(version_file_path)
                File.read(version_file_path).strip
else
                "development" # ファイルがない場合のフォールバック
end
