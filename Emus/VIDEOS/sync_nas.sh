#!/bin/sh

# ==============================================================================
# sync_nas.sh - TrimUI Brick DLNA / UPnP 局域网视频同步脚本
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
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$1" -t "$2"
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

# 检查 curl
if ! command -v curl >/dev/null 2>&1; then
    log "ERROR: curl binary not found!"
    info_msg "错误: 未找到 curl 工具" 3
    exit 1
fi

info_msg "正在连接 NAS (DLNA: $NAS_IP)..." 1

SOAP_URL="http://$NAS_IP:$NAS_PORT/ContentDirectory/control"
TMP_DIR="/tmp/dlna_sync_$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# 验证 NAS DLNA 端口连通性
log "Testing connection to $SOAP_URL..."
HTTP_CODE=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://$NAS_IP:$NAS_PORT/" 2>/dev/null)
if [ "$HTTP_CODE" = "000" ]; then
    log "ERROR: Unable to connect to NAS DLNA service on $NAS_IP:$NAS_PORT"
    info_msg "连接失败: 无法访问 NAS DLNA 服务 ($NAS_IP:$NAS_PORT)" 4
    exit 1
fi
log "NAS DLNA port responded (HTTP $HTTP_CODE)."

# 清理历史生成的 DLNA .m3u8 播放列表 (保留示例和 launch 脚本)
log "Cleaning previous DLNA playlists in $romdir..."
find "$romdir" -type f -name "*.m3u8" ! -name "nas-http-example.m3u8" -delete 2>/dev/null
# 清理空子文件夹
find "$romdir" -mindepth 1 -type d -empty -delete 2>/dev/null

# 状态计数
TOTAL_ITEMS=0

# DLNA SOAP 浏览函数
# 参数: $1=ObjectID, $2=CurrentRelativePath, $3=CurrentDepth
crawl_container() {
    c_id="$1"
    c_path="$2"
    c_depth="$3"

    if [ "$c_depth" -gt "$MAX_DEPTH" ]; then
        log "Reached max depth ($MAX_DEPTH) at: $c_path"
        return
    fi

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

        resp_file="$TMP_DIR/resp_${c_id}_${start_idx}.xml"
        curl -s -m 15 -H "Content-Type: text/xml; charset=\"utf-8\"" \
             -H "SOAPAction: \"urn:schemas-upnp-org:service:ContentDirectory:1#Browse\"" \
             -d "$soap_body" "$SOAP_URL" > "$resp_file" 2>/dev/null

        # 检查是否返回 DIDL-Lite
        if ! grep -q "<Result>" "$resp_file"; then
            log "No Result in SOAP response for container ID $c_id"
            break
        fi

        # 解析 NumberReturned
        num_ret=$(awk 'match($0, /<NumberReturned>([0-9]+)<\/NumberReturned>/) {print substr($0, RSTART+16, RLENGTH-33)}' "$resp_file")
        [ -z "$num_ret" ] && num_ret=0

        # 解码 XML 实体并提取 containers 和 items
        # 写入临时解析脚本执行提取
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
        ' "$resp_file" > "$TMP_DIR/didl.xml"

        # 1. 递归处理 sub-containers (<container ...>)
        awk '
        BEGIN { RS="<container "; FS=">" }
        NR > 1 {
            block = $0;
            id = ""; title = "";
            if (match(block, /id="([^"]+)"/)) {
                id = substr(block, RSTART+4, RLENGTH-5);
            }
            if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) {
                t_raw = substr(block, RSTART+10, RLENGTH-21);
                title = t_raw;
            }
            if (id != "" && title != "") {
                print id "\t" title;
            }
        }
        ' "$TMP_DIR/didl.xml" > "$TMP_DIR/sub_containers.txt"

        while IFS="$(printf '\t')" read -r sub_id sub_title; do
            [ -z "$sub_id" ] && continue
            # 过滤特殊字符
            clean_title=$(echo "$sub_title" | tr '/\\:*?"<>|' '_')
            
            # 如果配置了 FILTER_FOLDER 且在顶层，只进入匹配的文件夹
            if [ "$c_depth" -eq 1 ] && [ -n "$FILTER_FOLDER" ]; then
                if [ "$sub_title" != "$FILTER_FOLDER" ]; then
                    continue
                fi
            fi

            if [ -z "$c_path" ]; then
                next_path="$clean_title"
            else
                next_path="$c_path/$clean_title"
            fi
            
            log "Entering folder: $next_path (ID: $sub_id)"
            crawl_container "$sub_id" "$next_path" $((c_depth + 1))
        done < "$TMP_DIR/sub_containers.txt"

        # 2. 提取视频文件 items (<item ...>)
        awk '
        BEGIN { RS="<item "; FS=">" }
        NR > 1 {
            block = $0;
            title = ""; url = "";
            if (match(block, /<dc:title>([^<]+)<\/dc:title>/)) {
                title = substr(block, RSTART+10, RLENGTH-21);
            }
            if (match(block, /<res[^>]*>([^<]+)<\/res>/)) {
                res_part = substr(block, RSTART, RLENGTH);
                sub(/^<res[^>]*>/, "", res_part);
                sub(/<\/res>$/, "", res_part);
                url = res_part;
            }
            if (title != "" && url != "") {
                print title "\t" url;
            }
        }
        ' "$TMP_DIR/didl.xml" > "$TMP_DIR/items.txt"

        while IFS="$(printf '\t')" read -r item_title item_url; do
            [ -z "$item_title" ] || [ -z "$item_url" ] && continue
            clean_name=$(echo "$item_title" | tr '/\\:*?"<>|' '_')
            
            # 确定输出目录
            if [ -n "$c_path" ]; then
                target_dir="$romdir/$c_path"
            else
                target_dir="$romdir"
            fi
            mkdir -p "$target_dir"

            m3u8_file="$target_dir/$clean_name.m3u8"
            printf "#EXTM3U\n%s\n" "$item_url" > "$m3u8_file"
            TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
        done < "$TMP_DIR/items.txt"

        # 翻页判断
        if [ "$num_ret" -lt "$req_count" ]; then
            break
        fi
        start_idx=$((start_idx + num_ret))
    done
}

# 顶层入口探索：通常根目录 ID 为 0
# 如果用户指定了 folder，可从 0 目录递归查找；默认深度从 1 开始
info_msg "正在同步 NAS 视频列表..." 1
log "Starting DLNA crawl from root container ID 0..."
crawl_container "0" "" 1

log "DLNA Sync completed. Total video playlists generated: $TOTAL_ITEMS"

# 刷新 TrimUI MainUI 列表缓存
if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh" ]; then
    log "Updating MainUI VIDEOS cache via reset_list.sh..."
    /mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "VIDEOS" >> "$LOGFILE" 2>&1
else
    # 备用：直接移除数据库缓存
    rm -f "$romdir/VIDEOS_cache7.db" 2>/dev/null
fi

sync

info_msg "同步完成！共发现 $TOTAL_ITEMS 部视频" 3
log "=== NAS DLNA Sync Finished Successfully ==="
exit 0