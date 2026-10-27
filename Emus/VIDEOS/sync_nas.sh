#!/bin/sh

# ==============================================================================
# sync_nas.sh - TrimUI Brick DLNA / UPnP 局域网视频同步脚本 (迭代队列版)
# 协议：UPnP / DLNA ContentDirectory SOAP Browse
# 输出实时记录到 /mnt/SDCARD/nas_sync.log
# ==============================================================================

LOGFILE="/mnt/SDCARD/nas_sync.log"
echo "=== NAS DLNA Sync Started at $(date) ===" > "$LOGFILE"

log() {
    echo "[$(date +'%T')] $*" | tee -a "$LOGFILE"
}

info_msg() {
    if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh" ]; then
        if [ "$3" = "wait" ]; then
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$1" -t "$2" >/dev/null 2>&1
        else
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$1" -t "$2" >/dev/null 2>&1 &
        fi
    fi
}

export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

progdir="/mnt/SDCARD/Emus/VIDEOS"
romdir="/mnt/SDCARD/Roms/VIDEOS"
config_file="$progdir/nas_config.ini"

if [ ! -f "$config_file" ]; then
    log "ERROR: nas_config.ini not found at $config_file!"
    info_msg "错误: 未找到 nas_config.ini 配置文件" 3
    exit 1
fi

get_cfg() {
    awk -F "=" -v key="$1" '$1 ~ key {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$config_file"
}

NAS_IP=$(get_cfg "^ip")
NAS_PORT=$(get_cfg "^port")
FILTER_FOLDER=$(get_cfg "^folder")
MAX_DEPTH=$(get_cfg "^max_depth")

[ -z "$NAS_PORT" ] && NAS_PORT="50001"
[ -z "$MAX_DEPTH" ] && MAX_DEPTH="4"

log "Config: NAS_IP=$NAS_IP, NAS_PORT=$NAS_PORT, FOLDER=$FILTER_FOLDER, MAX_DEPTH=$MAX_DEPTH"

if [ -z "$NAS_IP" ] || [ "$NAS_IP" = "192.168.x.x" ]; then
    log "ERROR: Invalid NAS IP in nas_config.ini!"
    info_msg "请先在 nas_config.ini 中配置 NAS IP" 3
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    log "ERROR: curl binary not found!"
    info_msg "错误: 未找到 curl 工具" 3
    exit 1
fi

SOAP_URL="http://$NAS_IP:$NAS_PORT/ContentDirectory/control"
TMP_DIR="/tmp/dlna_sync_$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

QUEUE_FILE="$TMP_DIR/queue.txt"
touch "$QUEUE_FILE"

info_msg "正在连接 NAS (DLNA: $NAS_IP)..." 1

# 1. 验证 NAS DLNA 端口连通性
log "Testing connection to $SOAP_URL..."
HTTP_CODE=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://$NAS_IP:$NAS_PORT/" 2>/dev/null)
if [ "$HTTP_CODE" = "000" ]; then
    log "ERROR: Unable to connect to NAS DLNA service on $NAS_IP:$NAS_PORT"
    info_msg "连接失败: 无法访问 NAS DLNA 服务 ($NAS_IP:$NAS_PORT)" 4
    exit 1
fi
log "NAS DLNA port responded (HTTP $HTTP_CODE)."

# 2. 清理历史生成的 DLNA .m3u8 播放列表 (保留示例和 launch 脚本)
log "Cleaning previous DLNA playlists in $romdir..."
find "$romdir" -type f -name "*.m3u8" ! -name "nas-http-example.m3u8" -delete 2>/dev/null
find "$romdir" -mindepth 1 -type d -empty -delete 2>/dev/null

# 3. 定位根视频容器 (避免扫描 Music / Photo 等非视频大目录)
log "Querying root container 0 for Video storage..."
soap_body='<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:Browse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">
<ObjectID>0</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter>*</Filter>
<StartingIndex>0</StartingIndex>
<RequestedCount>30</RequestedCount>
<SortCriteria></SortCriteria>
</u:Browse>
</s:Body>
</s:Envelope>'

curl -s -m 10 -H 'Content-Type: text/xml; charset="utf-8"' \
     -H 'SOAPAction: "urn:schemas-upnp-org:service:ContentDirectory:1#Browse"' \
     -d "$soap_body" "$SOAP_URL" > "$TMP_DIR/root.xml" 2>/dev/null

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
' "$TMP_DIR/root.xml" > "$TMP_DIR/root_didl.xml"

VIDEO_ROOT_ID=$(awk '
BEGIN { RS="<container "; FS=">" }
NR > 1 {
    block = $0; id = ""; title = "";
    if (match(block, /id="([^"]+)"/)) { id = substr(block, RSTART+4, RLENGTH-5); }
    if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
    if (tolower(title) ~ /^video/) { print id; exit; }
}
' "$TMP_DIR/root_didl.xml")

if [ -n "$VIDEO_ROOT_ID" ]; then
    log "Located Video root container ID: $VIDEO_ROOT_ID"
    echo "$VIDEO_ROOT_ID|1|" > "$QUEUE_FILE"
else
    log "Notice: No explicit Video root found, starting at root ID 0"
    echo "0|1|" > "$QUEUE_FILE"
fi

TOTAL_ITEMS=0
TOTAL_FOLDERS=0

log "Starting iterative DLNA queue scanning..."

# 4. 队列主循环 (无递归，零变量冲突)
while [ -s "$QUEUE_FILE" ]; do
    line=$(head -n 1 "$QUEUE_FILE")
    sed -i '1d' "$QUEUE_FILE"

    IFS="|" read -r c_id c_depth c_path <<EOF
$line
EOF

    [ -z "$c_id" ] && continue
    TOTAL_FOLDERS=$((TOTAL_FOLDERS + 1))
    log "[$TOTAL_FOLDERS] Scanning folder: '$c_path' (ID: $c_id, depth: $c_depth)..."

    start_idx=0
    req_count=100

    while :; do
        soap_body="<?xml version=\"1.0\" encoding=\"utf-8\"?>
<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
<s:Body>
<u:Browse xmlns:u=\"urn:schemas-upnp-org:service:ContentDirectory:1\">
<ObjectID>$c_id</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter>*</Filter>
<StartingIndex>$start_idx</StartingIndex>
<RequestedCount>$req_count</RequestedCount>
<SortCriteria></SortCriteria>
</u:Browse>
</s:Body>
</s:Envelope>"

        curl -s -m 15 -H 'Content-Type: text/xml; charset="utf-8"' \
             -H 'SOAPAction: "urn:schemas-upnp-org:service:ContentDirectory:1#Browse"' \
             -d "$soap_body" "$SOAP_URL" > "$TMP_DIR/resp.xml" 2>/dev/null

        if ! grep -q "<Result>" "$TMP_DIR/resp.xml"; then
            break
        fi

        num_ret=$(awk 'match($0, /<NumberReturned>([0-9]+)<\/NumberReturned>/) {print substr($0, RSTART+16, RLENGTH-33)}' "$TMP_DIR/resp.xml")
        [ -z "$num_ret" ] && num_ret=0

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
        ' "$TMP_DIR/resp.xml" > "$TMP_DIR/didl.xml"

        # 4.1 提取并入队子文件夹
        if [ "$c_depth" -lt "$MAX_DEPTH" ]; then
            awk -v depth="$c_depth" -v base="$c_path" -v filter="$FILTER_FOLDER" '
            BEGIN { RS="<container "; FS=">" }
            NR > 1 {
                block = $0; id = ""; title = "";
                if (match(block, /id="([^"]+)"/)) { id = substr(block, RSTART+4, RLENGTH-5); }
                if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) { title = substr(block, RSTART+10, RLENGTH-21); }
                if (id != "" && title != "") {
                    # 如果指定了 filter 且处于第一层，只匹配该目录
                    if (depth == 1 && filter != "" && tolower(title) != tolower(filter)) {
                        next;
                    }
                    clean_t = title;
                    gsub(/[\/\\:*?"<>|]/, "_", clean_t);
                    new_p = (base == "") ? clean_t : (base "/" clean_t);
                    print id "|" (depth + 1) "|" new_p;
                }
            }
            ' "$TMP_DIR/didl.xml" >> "$QUEUE_FILE"
        fi

        # 4.2 提取视频项目并生成播放列表
        awk '
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
        ' "$TMP_DIR/didl.xml" > "$TMP_DIR/current_items.txt"

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
        done < "$TMP_DIR/current_items.txt"

        if [ "$num_ret" -lt "$req_count" ]; then
            break
        fi
        start_idx=$((start_idx + num_ret))
    done
done

log "DLNA Sync completed. Total video playlists generated: $TOTAL_ITEMS across $TOTAL_FOLDERS folders."

# 5. 刷新 MainUI ROM 列表缓存
if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh" ]; then
    log "Updating MainUI VIDEOS cache via reset_list.sh..."
    /mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "VIDEOS" >> "$LOGFILE" 2>&1
else
    rm -f "$romdir/VIDEOS_cache7.db" 2>/dev/null
fi

sync

info_msg "同步完成！共发现 $TOTAL_ITEMS 部视频" 3
log "=== NAS DLNA Sync Finished Successfully ==="
exit 0