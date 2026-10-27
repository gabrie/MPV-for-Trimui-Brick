#!/bin/sh

# ==============================================================================
# sync_nas.sh - TrimUI Brick DLNA / UPnP 局域网视频同步脚本 (精准路径定位版)
# 协议：UPnP / DLNA ContentDirectory SOAP Browse
# 输出实时记录到 /mnt/SDCARD/nas_sync.log
# ==============================================================================

LOGFILE="/mnt/SDCARD/nas_sync.log"
echo "=== NAS DLNA Sync Started at $(date) ===" > "$LOGFILE"

log() {
    echo "[$(date +'%T')] $*" >> "$LOGFILE"
}

export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

progdir="/mnt/SDCARD/Emus/VIDEOS"
romdir="/mnt/SDCARD/Roms/VIDEOS"
config_file="$progdir/nas_config.ini"

if [ ! -f "$config_file" ]; then
    log "ERROR: nas_config.ini not found at $config_file!"
    exit 1
fi

get_cfg() {
    awk -F "=" -v key="$1" '$1 ~ key {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$config_file"
}

NAS_IP=$(get_cfg "^ip")
NAS_PORT=$(get_cfg "^port")
TARGET_PATH=$(get_cfg "^folder")
MAX_DEPTH=$(get_cfg "^max_depth")

[ -z "$NAS_PORT" ] && NAS_PORT="50001"
[ -z "$MAX_DEPTH" ] && MAX_DEPTH="2"

log "Config: NAS_IP=$NAS_IP, NAS_PORT=$NAS_PORT, TARGET_PATH=$TARGET_PATH"

if [ -z "$NAS_IP" ] || [ "$NAS_IP" = "192.168.x.x" ]; then
    log "ERROR: Invalid NAS IP in nas_config.ini!"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    log "ERROR: curl binary not found!"
    exit 1
fi

SOAP_URL="http://$NAS_IP:$NAS_PORT/ContentDirectory/control"
TMP_DIR="/tmp/dlna_sync_$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

QUEUE_FILE="$TMP_DIR/queue.txt"
touch "$QUEUE_FILE"

# 1. 验证 NAS DLNA 服务端口连通性
log "Testing connection to $SOAP_URL..."
HTTP_CODE=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://$NAS_IP:$NAS_PORT/" 2>/dev/null)
if [ "$HTTP_CODE" = "000" ]; then
    log "ERROR: Unable to connect to NAS DLNA service on $NAS_IP:$NAS_PORT"
    exit 1
fi
log "NAS DLNA port responded (HTTP $HTTP_CODE)."

# SOAP Browse 辅助函数 (返回解码后的 DIDL-Lite XML)
browse_didl() {
    b_oid="$1"
    b_start="${2:-0}"
    b_count="${3:-100}"
    b_out="$TMP_DIR/browse_resp.xml"

    body="<?xml version=\"1.0\" encoding=\"utf-8\"?>
<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
<s:Body>
<u:Browse xmlns:u=\"urn:schemas-upnp-org:service:ContentDirectory:1\">
<ObjectID>$b_oid</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter>*</Filter>
<StartingIndex>$b_start</StartingIndex>
<RequestedCount>$b_count</RequestedCount>
<SortCriteria></SortCriteria>
</u:Browse>
</s:Body>
</s:Envelope>"

    curl -s -m 10 -H 'Content-Type: text/xml; charset="utf-8"' \
         -H 'SOAPAction: "urn:schemas-upnp-org:service:ContentDirectory:1#Browse"' \
         -d "$body" "$SOAP_URL" > "$b_out" 2>/dev/null

    awk '
    BEGIN { in_res=0; result="" }
    /<Result>/ { in_res=1; sub(/.*<Result>/, ""); }
    in_res {
        if ($0 ~ /<\/Result>/) {
            sub(/<\/Result>.*/, "");
            result = result $0;
            in_res=0;
        } else {
            result = result $0 "\n";
        }
    }
    END {
        gsub(/&lt;/, "<", result);
        gsub(/&gt;/, ">", result);
        gsub(/&quot;/, "\"", result);
        gsub(/&apos;/, "\x27", result);
        gsub(/&amp;/, "\\&", result);
        print result;
    }
    ' "$b_out"
}

# 2. 定位视频起始容器 (群晖下为 Video 容器 33)
log "Locating Video storage root container..."
didl_0=$(browse_didl "0" 0 20)
VIDEO_ROOT=$(echo "$didl_0" | awk '
BEGIN { RS="<container "; FS=">" }
NR > 1 {
    block = $0; id = ""; title = "";
    if (match(block, /id="([^"]+)"/)) { id = substr(block, RSTART+4, RLENGTH-5); }
    if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
    if (tolower(title) ~ /^video/) { print id; exit; }
}
')

if [ -z "$VIDEO_ROOT" ]; then
    VIDEO_ROOT="33"
fi
log "Using Video root container ID: $VIDEO_ROOT"

# 3. 逐级路径定位 (支持如 "video/火影忍者 剧场版11部" 或 "火影忍者 剧场版11部")
CURRENT_CID="$VIDEO_ROOT"
FINAL_FOLDER_NAME=""

if [ -n "$TARGET_PATH" ]; then
    log "Resolving target path: '$TARGET_PATH'..."
    # 拆分路径段
    OLD_IFS="$IFS"
    IFS="/"
    set -- $TARGET_PATH
    IFS="$OLD_IFS"

    for seg in "$@"; do
        [ -z "$seg" ] && continue
        log "Looking for subfolder '$seg' in container $CURRENT_CID..."
        didl_sub=$(browse_didl "$CURRENT_CID" 0 100)
        
        MATCHED_ID=$(echo "$didl_sub" | awk -v seg="$seg" '
        BEGIN { RS="<container "; FS=">" }
        NR > 1 {
            block = $0; id = ""; title = "";
            if (match(block, /id="([^"]+)"/)) { id = substr(block, RSTART+4, RLENGTH-5); }
            if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
            if (title == seg || tolower(title) == tolower(seg)) { print id; exit; }
        }
        ')

        if [ -n "$MATCHED_ID" ]; then
            log "Resolved '$seg' -> Container ID $MATCHED_ID"
            CURRENT_CID="$MATCHED_ID"
            FINAL_FOLDER_NAME="$seg"
        else
            log "Warning: Subfolder '$seg' not found directly. Will try recursive search."
            break
        fi
    done
fi

log "Target root set to Container ID: $CURRENT_CID (Folder: '$FINAL_FOLDER_NAME')"

# 4. 清理旧播放列表 (保留示例和 launch 脚本)
log "Cleaning previous DLNA playlists in $romdir..."
find "$romdir" -type f -name "*.m3u8" ! -name "nas-http-example.m3u8" -delete 2>/dev/null
find "$romdir" -mindepth 1 -type d -empty -delete 2>/dev/null

# 5. 抓取目标容器下的所有视频 (支持分页，单目录秒级完成)
TOTAL_ITEMS=0

# 将起始节点推入队列
if [ -n "$FINAL_FOLDER_NAME" ]; then
    echo "$CURRENT_CID|1|$FINAL_FOLDER_NAME" > "$QUEUE_FILE"
else
    echo "$CURRENT_CID|1|" > "$QUEUE_FILE"
fi

while [ -s "$QUEUE_FILE" ]; do
    line=$(head -n 1 "$QUEUE_FILE")
    sed -i '1d' "$QUEUE_FILE"

    IFS="|" read -r c_id c_depth c_path <<EOF
$line
EOF

    [ -z "$c_id" ] && continue
    log "Scanning Container $c_id (path: '$c_path', depth: $c_depth)..."

    start_idx=0
    req_count=100

    while :; do
        didl_cur=$(browse_didl "$c_id" "$start_idx" "$req_count")

        # 5.1 提取视频文件
        echo "$didl_cur" | awk '
        BEGIN { RS="<item "; FS=">" }
        NR > 1 {
            block = $0; title = ""; url = "";
            if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
            if (match(block, /<res[^>]*>([^<]+)<\/res>/)) {
                res_part = substr(block, RSTART, RLENGTH);
                sub(/^<res[^>]*>/, "", res_part);
                sub(/<\/res>$/, "", res_part);
                url = res_part;
            }
            if (title != "" && url != "") {
                clean_t = title;
                gsub(/[\/\\:*?"<>|]/, "_", clean_t);
                print clean_t "\t" url;
            }
        }
        ' > "$TMP_DIR/items.txt"

        item_count=0
        while IFS="$(printf '\t')" read -r item_name item_url; do
            [ -z "$item_name" ] || [ -z "$item_url" ] && continue
            if [ -n "$c_path" ]; then
                target_d="$romdir/$c_path"
            else
                target_d="$romdir"
            fi
            mkdir -p "$target_d"
            printf "#EXTM3U\n%s\n" "$item_url" > "$target_d/$item_name.m3u8"
            TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
            item_count=$((item_count + 1))
            log "Created playlist: $c_path/$item_name.m3u8"
        done < "$TMP_DIR/items.txt"

        # 5.2 若未达到深度限制，入队子容器
        if [ "$c_depth" -lt "$MAX_DEPTH" ]; then
            echo "$didl_cur" | awk -v depth="$c_depth" -v base="$c_path" '
            BEGIN { RS="<container "; FS=">" }
            NR > 1 {
                block = $0; id = ""; title = "";
                if (match(block, /id="([^"]+)"/)) { id = substr(block, RSTART+4, RLENGTH-5); }
                if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
                if (id != "" && title != "") {
                    clean_t = title;
                    gsub(/[\/\\:*?"<>|]/, "_", clean_t);
                    new_p = (base == "") ? clean_t : (base "/" clean_t);
                    print id "|" (depth + 1) "|" new_p;
                }
            }
            ' >> "$QUEUE_FILE"
        fi

        # 检查是否读完当前容器
        num_ret=$(awk 'match($0, /<NumberReturned>([0-9]+)<\/NumberReturned>/) {print substr($0, RSTART+16, RLENGTH-33)}' "$TMP_DIR/browse_resp.xml")
        [ -z "$num_ret" ] && num_ret=0

        if [ "$num_ret" -lt "$req_count" ]; then
            break
        fi
        start_idx=$((start_idx + num_ret))
    done
done

log "Sync finished. Generated $TOTAL_ITEMS playlists."

# 6. 刷新 MainUI 列表缓存
if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh" ]; then
    log "Refreshing MainUI VIDEOS list cache..."
    /mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "VIDEOS" >> "$LOGFILE" 2>&1
else
    rm -f "$romdir/VIDEOS_cache7.db" 2>/dev/null
fi

sync
log "=== NAS DLNA Sync Completed Successfully at $(date) ==="
exit 0