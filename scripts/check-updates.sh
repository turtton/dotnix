#!/usr/bin/env bash

# グローバル配列：更新があるパッケージを記録
declare -a updated_packages
declare -a major_updates
declare -a minor_updates
declare -a patch_updates

# バージョン比較と分類関数
classify_update_type() {
	local current="$1"
	local new="$2"
	local pkg_name="$3"

	# バージョン番号を抽出（数字とドットのみ）
	local current_ver=$(echo "$current" | grep -oE '^[0-9]+(\.[0-9]+)*' || echo "$current")
	local new_ver=$(echo "$new" | grep -oE '^[0-9]+(\.[0-9]+)*' || echo "$new")

	# メジャーバージョンを比較
	local current_major=$(echo "$current_ver" | cut -d'.' -f1)
	local new_major=$(echo "$new_ver" | cut -d'.' -f1)

	if [ "$current_major" != "$new_major" ] && [ "$current_major" -lt "$new_major" ] 2>/dev/null; then
		major_updates+=("$pkg_name: $current → $new")
		return
	fi

	# マイナーバージョンを比較
	local current_minor=$(echo "$current_ver" | cut -d'.' -f2 2>/dev/null || echo "0")
	local new_minor=$(echo "$new_ver" | cut -d'.' -f2 2>/dev/null || echo "0")

	if [ "$current_minor" != "$new_minor" ] && [ "$current_minor" -lt "$new_minor" ] 2>/dev/null; then
		minor_updates+=("$pkg_name: $current → $new")
		return
	fi

	# それ以外はパッチ更新とみなす
	patch_updates+=("$pkg_name: $current → $new")
}

# キャッシュディレクトリ
CACHE_DIR="/tmp/nix_version_cache_$$"
mkdir -p "$CACHE_DIR"

# クリーンアップ関数
cleanup() {
	rm -rf "$CACHE_DIR"
}
trap cleanup EXIT

# 高速化された並列処理関数
check_package_batch_fast() {
	local packages=("$@")
	local temp_dir="/tmp/nix_check_fast_$$"
	local updates_file="$1" # 最初の引数を更新ファイルとして使用
	shift                   # 最初の引数を削除
	local packages=("$@")

	mkdir -p "$temp_dir"

	local running_jobs=0
	local max_parallel=40

	# 各パッケージを並列で処理（並列数制限付き）
	for pkg_idx in "${!packages[@]}"; do
		# 並列数制限
		while [ $running_jobs -ge $max_parallel ]; do
			wait -n # いずれかのジョブ完了を待つ
			running_jobs=$((running_jobs - 1))
		done

		{
			local pkg_info="${packages[$pkg_idx]}"
			local pkg_name=$(echo "$pkg_info" | cut -d'|' -f1)
			local current_version=$(echo "$pkg_info" | cut -d'|' -f2)

			# キャッシュをチェック
			local cache_file="$CACHE_DIR/${pkg_name}.cache"
			if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 3600 ]; then
				# 1時間以内のキャッシュを使用
				cp "$cache_file" "$temp_dir/result_$pkg_idx"
			else
				# より短いタイムアウトでunstableのみをチェック
				local unstable_version=$(timeout 3 nix eval --raw "github:nixos/nixpkgs/nixos-unstable#$pkg_name.version" 2>/dev/null || echo "N/A")

				# 結果をキャッシュに保存
				echo "$pkg_name|$current_version|N/A|$unstable_version" >"$cache_file"
				echo "$pkg_name|$current_version|N/A|$unstable_version" >"$temp_dir/result_$pkg_idx"
			fi
		} &

		running_jobs=$((running_jobs + 1))
	done

	# 残りのジョブ完了を待つ
	wait

	# 結果を処理
	for pkg_idx in "${!packages[@]}"; do
		if [ -f "$temp_dir/result_$pkg_idx" ]; then
			local result=$(cat "$temp_dir/result_$pkg_idx")
			local pkg_name=$(echo "$result" | cut -d'|' -f1)
			local current_version=$(echo "$result" | cut -d'|' -f2)
			local nixpkgs_version=$(echo "$result" | cut -d'|' -f3)
			local unstable_version=$(echo "$result" | cut -d'|' -f4)

			if [ "$unstable_version" != "N/A" ] && [ "$current_version" != "$unstable_version" ]; then
				# 進捗表示
				echo -n "."
				# 更新パッケージ情報をファイルに保存（ロック付き）
				(
					flock -x 200
					echo "$pkg_name|$current_version|$unstable_version" >>"$updates_file"
				) 200>"$updates_file.lock"
			fi
		fi
	done

	rm -rf "$temp_dir"
}

# メイン処理
check_all_package_updates() {
	echo "システム全体のパッケージ更新確認"
	echo "=============================="

	# グローバル更新リストファイルを作成
	local global_updates_file="/tmp/global_updates_$$"
	touch "$global_updates_file"

	# システムパッケージを取得（全パッケージ対象）
	echo "システムパッケージを取得中..."
	system_packages=($(nix-store -q --requisites /nix/var/nix/profiles/system |
		grep -v '\.drv$' |
		sed 's|/nix/store/[a-z0-9]*-||' |
		grep -E '^[a-zA-Z0-9][a-zA-Z0-9_+.-]*-[0-9]' |
		# ドキュメントや開発用ファイルのみ除外（アプリケーション本体は残す）
		grep -v '\-\(man\|doc\|dev\|static\)$' |
		sed 's/^\(.*\)-\([0-9].*\)$/\1|\2/' |
		sort -u))

	total_packages=${#system_packages[@]}
	echo "検出されたパッケージ数: $total_packages"
	echo ""

	# 大量パッケージ処理用の並列設定
	local batch_size=100
	local max_parallel=30
	local updates_found=0

	local i=0
	while [ $i -lt $total_packages ]; do
		local batch=()
		local end=$((i + batch_size))
		if [ $end -gt $total_packages ]; then
			end=$total_packages
		fi

		# バッチを作成
		for ((j = i; j < end; j++)); do
			batch+=("${system_packages[$j]}")
		done

		# 進捗表示を修正：1ベースの開始位置を使用
		echo -n "進捗: $((i + 1))-$end / $total_packages 処理中 (バッチサイズ: ${#batch[@]}) "

		# バッチを非同期処理（並列数制限）
		check_package_batch_fast "$global_updates_file" "${batch[@]}"
		echo " [完了]"

		# レート制限を緩和
		sleep 0.2

		# iを明示的に更新
		i=$((i + batch_size))
	done

	echo "========================================="
	# 更新データを分類
	echo ""
	echo "更新情報を分析中..."
	if [ -f "$global_updates_file" ]; then
		while IFS='|' read -r pkg_name current_ver new_ver; do
			[ -z "$pkg_name" ] && continue
			updated_packages+=("$pkg_name ($current_ver -> $new_ver)")
			classify_update_type "$current_ver" "$new_ver" "$pkg_name"
		done <"$global_updates_file"
	fi

	echo ""
	echo "📊 更新サマリー: ${#updated_packages[@]}件の更新あり"

	if [ ${#updated_packages[@]} -gt 0 ]; then
		echo "├─ 🚨 メジャー: ${#major_updates[@]}件  ⚡ マイナー: ${#minor_updates[@]}件  🔧 パッチ: ${#patch_updates[@]}件"

		# 最も重要な更新を表示
		important_updates=()
		[ ${#major_updates[@]} -gt 0 ] && important_updates+=("${major_updates[0]}")
		[ ${#major_updates[@]} -gt 1 ] && important_updates+=("${major_updates[1]}")
		if [ ${#important_updates[@]} -gt 0 ]; then
			echo -n "└─ 最も重要: "
			printf "%s" "${important_updates[0]}"
			[ ${#important_updates[@]} -gt 1 ] && printf ", %s" "${important_updates[1]}"
			echo ""
		fi

		echo ""
		read -p "詳細を表示しますか？ [y/N]: " -n 1 -r
		echo ""

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo ""

			if [ ${#major_updates[@]} -gt 0 ]; then
				echo "🚨 メジャー更新 (${#major_updates[@]}件):"
				for update in "${major_updates[@]}"; do
					echo "  • $update"
				done
				echo ""
			fi

			if [ ${#minor_updates[@]} -gt 0 ]; then
				echo "⚡ マイナー更新 (${#minor_updates[@]}件):"
				for update in "${minor_updates[@]}"; do
					echo "  • $update"
				done
				echo ""
			fi

			if [ ${#patch_updates[@]} -gt 0 ]; then
				echo "🔧 パッチ更新 (${#patch_updates[@]}件):"
				for update in "${patch_updates[@]}"; do
					echo "  • $update"
				done
			fi
		fi
	else
		echo "└─ すべてのパッケージが最新です 🎉"
	fi

	# クリーンアップ
	rm -f "$global_updates_file" "$global_updates_file.lock"
}

echo "システムパッケージ更新チェッカー"
echo "=============================="
echo ""

check_all_package_updates
