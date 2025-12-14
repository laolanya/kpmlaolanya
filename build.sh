MODDIR="${0%/*}"

# 判断并删除当前目录下的文件
[ -e "kernel" ] && ${MODDIR}/libmagiskboot.so --cleanup 2>/dev/null
[ -e "new-boot.img" ] && rm "new-boot.img"

# 判断并删除 kpm 目录下的文件
[ -e "$MODDIR/kpm/patched_kernel" ] && rm "$MODDIR/kpm/patched_kernel"
[ -e "$MODDIR/kpm/kernel" ] && rm "$MODDIR/kpm/kernel"

echo "[✓] 已成功清理修补产生的文件"
#!/system/bin/sh

# ================================================
# KPM模块嵌入工具 v2.9 - 极简版
# 作者：老懒鸭
# QQ群：1072773359
# 说明：直接GitHub链接下载 + KPM嵌入
# ================================================

MODDIR="${0%/*}"

# 自定义密钥
KEY="aqmJau7K"
KPM_DIR="${MODDIR}/kpm"
QQ_GROUP="1072773359"

# GitHub直连配置 - 直接在这里添加链接
# ================================================
# 格式：模块名.kpm=GitHub原始链接
# ================================================

GITHUB_MODULES=(
    # 示例：kma_v6.12.608.kpm
    "kma_v6.12.608.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/kma_v6.12.608.kpm"
    "kma_v6.12.607.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/kma_v6.12.607.kpm"
    "kma_v6.12.605.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/kma_v6.12.605.kpm"
    "kma_v6.12.603.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/kma_v6.12.603.kpm"
    "kma_v6.12.503.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/kma_v6.12.503.kpm"
    # 在这里添加更多模块（取消注释并修改）
    # "ReKernel.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/ReKernel.kpm"
    # "network.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/network.kpm"
    # "Battery_Optimize.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/Battery_Optimize.kpm"
    # "Performance_Boost.kpm=https://raw.githubusercontent.com/laolanya/kpmlaolanya/refs/heads/main/Performance_Boost.kpm"
)

# 下载配置
MAX_RETRY=3
DOWNLOAD_TIMEOUT=30

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# 显示作者信息
show_author_info() {
    clear
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                            ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${CYAN}╦ ╦╔═╗╔╦╗  ╔╗ ╔═╗╔╦╗╔═╗╦═╗        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${CYAN}║║║╠═╣║║║  ╠╩╗║ ║║║║║╣ ╠╦╝        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${CYAN}╚╩╝╩ ╩╩ ╩  ╚═╝╚═╝╩ ╩╚═╝╩╚═        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                            ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}        ${WHITE}KPM模块嵌入工具 v2.9${NC}           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}          ${YELLOW}作者：老懒鸭${NC}                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}        ${PURPLE}QQ群：${QQ_GROUP}${NC}               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                            ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}GitHub直链下载 + 极简配置${NC}        ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

show_line() {
    echo -e "${GRAY}────────────────────────────────────────────${NC}"
}

show_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

show_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

show_step() {
    echo -e "${PURPLE}» $1${NC}"
}

# 基础检查
Basic_Check() {
    if [ "$(whoami)" != "root" ]; then
        show_error "请使用 Root 权限运行此脚本"
        exit 1
    fi
    
    if [ ! -f "boot.img" ]; then
        show_error "当前目录下未找到 boot.img"
        show_warning "即将尝试提取"
        echo -n -e "${YELLOW}确认已备份并愿意继续操作？输入 y 继续，其他任意键退出: ${NC}"
        read -r confirm
        if [ "$confirm" == "y" ]; then
            extract_boot
        else
            exit 1
        fi
    fi

    if echo "$MODDIR" | grep -qE "sdcard|storage/emulated"; then
        show_error "请勿在 sdcard 以及它的子目录下执行该脚本"
        show_warning "建议在 /data/local/tmp 目录下执行"
        exit 1
    elif [ ! -x . ]; then
        show_error "当前目录没有可执行权限"
        exit 1
    fi

    if test -x "$MODDIR/kpm/kptools-android"; then
        show_success "kptools 可执行"
    else
        chmod +x "$MODDIR/kpm/kptools-android"
        if test -x "$MODDIR/kpm/kptools-android"; then
            show_success "kptools 已获得可执行权限"
        else
            show_error "kptools 获取可执行权限失败"
            exit 1
        fi
    fi

    if [ ! -d "$KPM_DIR" ]; then
        mkdir -p "$KPM_DIR"
        show_warning "已创建kpm目录"
    fi

    if [[ -e "kernel" && -e "new-boot.img" ]]; then
        show_warning "正在清理目录..."
        rm -f kernel new-boot.img 2>/dev/null
        show_success "已清理完成"
    fi
}

# 提取 Boot 镜像
extract_boot() {
    AB_check=$(getprop ro.build.ab_update)
    Partition_location=$(getprop ro.boot.slot_suffix)

    if [ "$AB_check" == "true" ]; then
        show_info "AB分区设备"
        if [ "$Partition_location" == "_a" ]; then
            current="a"
        elif [ "$Partition_location" == "_b" ]; then
            current="b"
        else
            current="a"
        fi
        show_step "正在提取Boot镜像..."
        dd if="/dev/block/bootdevice/by-name/boot_$current" of="boot.img" bs=4096 2>/dev/null
    else
        show_info "非AB分区设备"
        dd if="/dev/block/bootdevice/by-name/boot" of="boot.img" bs=4096 2>/dev/null
    fi

    if [ -f "boot.img" ]; then
        show_success "提取成功"
    else
        show_error "提取失败"
        return 1
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output_file="$2"
    
    local temp_file="/tmp/download_$$"
    local success=0
    
    # 优先使用curl
    if command -v curl >/dev/null 2>&1; then
        for i in $(seq 1 $MAX_RETRY); do
            if [ $i -gt 1 ]; then
                show_info "重试下载 ($i/$MAX_RETRY)..."
            fi
            
            if curl -s -L --connect-timeout $DOWNLOAD_TIMEOUT -o "$temp_file" "$url"; then
                if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                    local size=$(stat -c%s "$temp_file" 2>/dev/null || echo "0")
                    if [ "$size" -gt 1024 ]; then
                        success=1
                        break
                    fi
                fi
            fi
            if [ $i -lt $MAX_RETRY ]; then
                sleep 2
            fi
        done
    # 如果没有curl，尝试wget
    elif command -v wget >/dev/null 2>&1; then
        for i in $(seq 1 $MAX_RETRY); do
            if [ $i -gt 1 ]; then
                show_info "重试下载 ($i/$MAX_RETRY)..."
            fi
            
            if wget -q -T $DOWNLOAD_TIMEOUT -O "$temp_file" "$url"; then
                if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                    local size=$(stat -c%s "$temp_file" 2>/dev/null || echo "0")
                    if [ "$size" -gt 1024 ]; then
                        success=1
                        break
                    fi
                fi
            fi
            if [ $i -lt $MAX_RETRY ]; then
                sleep 2
            fi
        done
    else
        show_error "未找到curl或wget，无法下载"
        return 1
    fi
    
    if [ $success -eq 1 ]; then
        mv "$temp_file" "$output_file" 2>/dev/null
        if [ -f "$output_file" ]; then
            local final_size=$(stat -c%s "$output_file" 2>/dev/null || echo "未知")
            show_success "下载成功 ($final_size 字节)"
            return 0
        fi
    fi
    
    rm -f "$temp_file" 2>/dev/null
    show_error "下载失败"
    return 1
}

# 从GitHub下载模块
download_github_module() {
    local module_name="$1"
    local url="$2"
    
    show_step "下载模块: $module_name"
    show_info "链接: $(echo "$url" | cut -c1-50)..."
    
    local output_file="$KPM_DIR/$module_name"
    
    # 检查是否已存在
    if [ -f "$output_file" ]; then
        echo ""
        echo -n -e "${YELLOW}模块已存在，是否重新下载？(y/n): ${NC}"
        read -r overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            show_info "使用现有模块"
            return 0
        fi
    fi
    
    # 下载文件
    if download_file "$url" "$output_file"; then
        # 检查文件类型，如果是ZIP则解压
        if command -v file >/dev/null 2>&1; then
            local file_type=$(file -b "$output_file" 2>/dev/null)
            if [[ "$file_type" == *"Zip archive"* ]] || [[ "$file_type" == *"ZIP"* ]]; then
                show_step "检测到ZIP文件，正在解压..."
                if command -v unzip >/dev/null 2>&1; then
                    local extract_dir="/tmp/extract_$$"
                    mkdir -p "$extract_dir"
                    if unzip -o "$output_file" -d "$extract_dir" >/dev/null 2>&1; then
                        local kpm_file=$(find "$extract_dir" -name "*.kpm" -type f | head -1)
                        if [ -n "$kpm_file" ]; then
                            mv "$kpm_file" "$output_file"
                            show_success "从ZIP中提取.kpm文件"
                        fi
                        rm -rf "$extract_dir"
                    fi
                fi
            fi
        fi
        return 0
    fi
    return 1
}

# 显示并选择GitHub模块
select_github_module() {
    if [ ${#GITHUB_MODULES[@]} -eq 0 ]; then
        show_error "没有配置任何GitHub模块"
        echo ""
        echo -e "${YELLOW}如何添加模块：${NC}"
        echo "1. 打开脚本文件"
        echo "2. 找到 GITHUB_MODULES 数组"
        echo "4. 保存并重新运行脚本"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}GitHub模块列表:${NC}"
    show_line
    
    for i in "${!GITHUB_MODULES[@]}"; do
        local config="${GITHUB_MODULES[$i]}"
        local name=$(echo "$config" | cut -d'=' -f1)
        local url=$(echo "$config" | cut -d'=' -f2)
        
        # 检查本地是否已存在
        local status=""
        if [ -f "$KPM_DIR/$name" ]; then
            status="(已下载)"
        fi
        
        echo -e "  ${GREEN}[$((i+1))]${NC} $name $status"
    done
    
    echo -e "  ${GREEN}[A]${NC} 下载所有模块"
    echo -e "  ${RED}[0]${NC} 返回"
    show_line
    
    echo -n -e "${WHITE}请选择要下载的模块: ${NC}"
    read -r choice
    
    if [ "$choice" == "0" ]; then
        return 1
    elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
        # 下载所有模块
        show_step "开始下载所有模块..."
        local success_count=0
        local total_count=${#GITHUB_MODULES[@]}
        
        for config in "${GITHUB_MODULES[@]}"; do
            local name=$(echo "$config" | cut -d'=' -f1)
            local url=$(echo "$config" | cut -d'=' -f2)
            
            if download_github_module "$name" "$url"; then
                success_count=$((success_count + 1))
            fi
        done
        
        if [ $success_count -gt 0 ]; then
            show_success "下载完成: $success_count/$total_count 个模块"
        else
            show_error "所有模块下载失败"
            return 1
        fi
        return 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#GITHUB_MODULES[@]} ]; then
        local index=$((choice-1))
        local config="${GITHUB_MODULES[$index]}"
        local name=$(echo "$config" | cut -d'=' -f1)
        local url=$(echo "$config" | cut -d'=' -f2)
        
        if download_github_module "$name" "$url"; then
            return 0
        else
            return 1
        fi
    else
        show_error "无效选择"
        return 1
    fi
}

# 检查本地模块
check_local_modules() {
    kpm_files=("$KPM_DIR"/*.kpm)
    
    if [ ${#kpm_files[@]} -eq 0 ] || [ ! -f "${kpm_files[0]}" ]; then
        show_warning "本地未找到KPM模块"
        echo ""
        
        echo -e "${CYAN}是否从GitHub下载模块？${NC}"
        echo -n -e "${YELLOW}(y下载/n退出): ${NC}"
        read -r download_choice
        
        if [ "$download_choice" == "y" ] || [ "$download_choice" == "Y" ]; then
            if select_github_module; then
                # 重新检查模块
                kpm_files=("$KPM_DIR"/*.kpm)
                if [ ${#kpm_files[@]} -gt 0 ]; then
                    show_success "找到 ${#kpm_files[@]} 个KPM模块"
                else
                    show_error "下载后仍未找到模块"
                    return 1
                fi
            else
                return 1
            fi
        else
            show_error "没有KPM模块，无法继续"
            return 1
        fi
    else
        show_success "找到 ${#kpm_files[@]} 个KPM模块"
    fi
    
    # 显示模块列表
    echo ""
    echo -e "${CYAN}本地KPM模块:${NC}"
    show_line
    for i in "${!kpm_files[@]}"; do
        echo -e "  ${GREEN}[$((i+1))]${NC} $(basename "${kpm_files[$i]}")"
    done
    show_line
    
    return 0
}

# 选择KPM模块
select_kpm_module() {
    kpm_files=("$KPM_DIR"/*.kpm)
    
    if [ ${#kpm_files[@]} -eq 0 ] || [ ! -f "${kpm_files[0]}" ]; then
        show_error "没有找到KPM模块"
        return 1
    fi
    
    if [ ${#kpm_files[@]} -eq 1 ]; then
        selected_module="${kpm_files[0]}"
        show_success "自动选择: $(basename "$selected_module")"
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}请选择要嵌入的KPM模块:${NC}"
    show_line
    for i in "${!kpm_files[@]}"; do
        echo -e "  ${GREEN}[$((i+1))]${NC} $(basename "${kpm_files[$i]}")"
    done
    echo -e "  ${GREEN}[A]${NC} 嵌入所有模块"
    echo -e "  ${RED}[0]${NC} 退出"
    show_line
    
    echo -n -e "${WHITE}请输入序号: ${NC}"
    read -r choice
    
    if [ "$choice" == "0" ]; then
        exit 0
    elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
        selected_module="all"
        return 0
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#kpm_files[@]} ]; then
        show_error "无效的选择"
        return 1
    fi
    
    selected_module="${kpm_files[$((choice-1))]}"
    show_success "已选择: $(basename "$selected_module")"
    return 0
}

# 解包 boot
boot_unpack() {
    show_step "正在解包 boot 获取 kernel"
    
    if [ ! -f "./libmagiskboot.so" ]; then
        show_error "libmagiskboot.so 不存在于当前目录"
        return 1
    fi
    
    ./libmagiskboot.so unpack boot.img >/dev/null 2>&1
    if [ -e "kernel" ]; then
        show_success "已成功获取 kernel"
        cp kernel "$KPM_DIR/" 2>/dev/null
        return 0
    else
        show_error "解包 boot 失败"
        return 1
    fi
}

# 修补 Kernel
Kernel_patching() {
    local kpm_file="$1"
    local module_name=$(basename "$kpm_file" .kpm)
    
    show_step "正在对 kernel 执行修补"
    show_info "使用模块: $(basename "$kpm_file")"
    show_info "使用密钥: ${KEY}"
    
    cd "$KPM_DIR" || return 1
    
    if [ "$(dirname "$kpm_file")" != "." ]; then
        cp "$kpm_file" "./$module_name.kpm"
        kpm_file="./$module_name.kpm"
    fi
    
    show_step "开始修补内核..."
    
    ./kptools-android -p -i kernel -k kpimg-linux -M "$kpm_file" -V pre-kernel-init -T kpm -s "$KEY" -o patched_kernel
    
    if [ -e "patched_kernel" ]; then
        show_success "Kernel 修补已完成"
        cp -f patched_kernel ../kernel
        cd ..
        return 0
    else
        show_error "内核修补失败"
        cd ..
        return 1
    fi
}

# 批量修补所有模块
batch_patch_modules() {
    cd "$KPM_DIR" || return 1
    show_step "开始批量嵌入 ${#kpm_files[@]} 个模块..."
    
    local success_count=0
    local temp_kernel="kernel"
    
    for kpm_file in "${kpm_files[@]}"; do
        module_name=$(basename "$kpm_file" .kpm)
        show_step "正在嵌入: $module_name"
        
        cp "$kpm_file" "./$module_name.kpm"
        
        if [ $success_count -eq 0 ]; then
            ./kptools-android -p -i kernel -k kpimg-linux -M "./$module_name.kpm" -V pre-kernel-init -T kpm -s "$KEY" -o patched_kernel_tmp
        else
            ./kptools-android -p -i "$temp_kernel" -k kpimg-linux -M "./$module_name.kpm" -V pre-kernel-init -T kpm -s "$KEY" -o patched_kernel_tmp
        fi
        
        if [ -f "patched_kernel_tmp" ]; then
            show_success "$module_name 嵌入成功"
            mv patched_kernel_tmp "$temp_kernel"
            success_count=$((success_count + 1))
        else
            show_error "$module_name 嵌入失败，跳过"
        fi
        
        rm -f "./$module_name.kpm"
    done
    
    if [ $success_count -gt 0 ]; then
        show_success "成功嵌入 $success_count 个模块"
        cp -f "$temp_kernel" ../kernel
        cd ..
        return 0
    else
        show_error "所有模块嵌入失败"
        cd ..
        return 1
    fi
}

# 打包 boot
boot_repack() {
    show_step "正在打包 boot"
    
    if [ ! -f "./libmagiskboot.so" ]; then
        show_error "libmagiskboot.so 不存在于当前目录"
        return 1
    fi
    
    ./libmagiskboot.so repack boot.img >/dev/null 2>&1
    if [ -e "new-boot.img" ]; then
        show_success "boot 已打包成功"
        
        echo ""
        show_line
        echo -e "${GREEN}            修补完成！${NC}"
        show_line
        echo -e "${CYAN}作者：老懒鸭${NC}"
        echo -e "${CYAN}QQ群：${QQ_GROUP}${NC}"
        show_line
        echo -e "原始文件: boot.img"
        echo -e "修补文件: new-boot.img"
        
        if [ -f "boot.img" ] && [ -f "new-boot.img" ]; then
            orig_size=$(stat -c%s "boot.img" 2>/dev/null || echo "未知")
            new_size=$(stat -c%s "new-boot.img" 2>/dev/null || echo "未知")
            echo -e "原始大小: $orig_size 字节"
            echo -e "修补大小: $new_size 字节"
        fi
        
        echo ""
        show_success "new-boot.img 已生成在当前目录"
        return 0
    else
        show_error "boot 打包失败"
        return 1
    fi
}

# 刷入镜像
flash_boot_image() {
    echo ""
    show_line
    echo -e "${CYAN}           刷入镜像选项${NC}"
    show_line
    
    if [ ! -f "new-boot.img" ]; then
        show_error "未找到 new-boot.img 文件"
        return 1
    fi
    
    show_warning "刷入操作有风险，请确保已备份原始 boot 镜像"
    echo ""
    
    echo -e "${CYAN}请选择操作:${NC}"
    show_line
    echo -e "  ${GREEN}[1]${NC} 自动刷入"
    echo -e "  ${GREEN}[2]${NC} 仅生成镜像，不刷入"
    echo -e "  ${RED}[0]${NC} 退出"
    show_line
    
    echo -n -e "${WHITE}请选择操作: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            auto_flash_boot
            ;;
        2)
            show_success "已选择仅生成镜像"
            show_info "生成的 new-boot.img 可在以下位置找到:"
            echo -e "${YELLOW}    $(pwd)/new-boot.img${NC}"
            ;;
        0)
            return 1
            ;;
        *)
            show_error "无效选择"
            return 1
            ;;
    esac
}

# 自动刷入boot镜像
auto_flash_boot() {
    show_step "检测设备分区信息..."
    
    AB_check=$(getprop ro.build.ab_update)
    Partition_location=$(getprop ro.boot.slot_suffix)
    
    if [ "$AB_check" == "true" ]; then
        show_info "AB分区设备"
        if [ "$Partition_location" == "_a" ]; then
            target_partition="boot_a"
        elif [ "$Partition_location" == "_b" ]; then
            target_partition="boot_b"
        else
            target_partition="boot_a"
        fi
        partition_path="/dev/block/bootdevice/by-name/$target_partition"
    else
        show_info "非AB分区设备"
        target_partition="boot"
        partition_path="/dev/block/bootdevice/by-name/boot"
    fi
    
    show_warning "即将刷入到分区: $target_partition"
    echo -e "${RED}警告：刷入操作不可逆，请确保已备份！${NC}"
    echo ""
    
    echo -n -e "${YELLOW}请输入 '刷入' 确认操作: ${NC}"
    read -r confirm_input
    
    if [ "$confirm_input" != "刷入" ]; then
        show_error "刷入取消"
        return 1
    fi
    
    show_step "正在刷入 boot 镜像..."
    
    if dd if="new-boot.img" of="$partition_path" bs=4096 2>&1; then
        show_success "boot镜像刷入成功！"
        
        echo ""
        show_line
        echo -e "${GREEN}          刷入完成！${NC}"
        show_line
        
        echo ""
        echo -n -e "${YELLOW}是否立即重启设备？(y/n): ${NC}"
        read -r reboot_choice
        
        if [ "$reboot_choice" == "y" ] || [ "$reboot_choice" == "Y" ]; then
            show_step "正在重启设备..."
            if command -v reboot >/dev/null 2>&1; then
                reboot
            elif command -v busybox >/dev/null 2>&1; then
                busybox reboot
            else
                /system/bin/reboot
            fi
            show_success "重启命令已发送"
        else
            show_success "刷入完成，请稍后手动重启设备"
        fi
    else
        show_error "boot镜像刷入失败！"
        return 1
    fi
}

# 主函数
main() {
    show_author_info
    
    echo ""
    echo -e "${CYAN}使用方法:${NC}"
    show_line
    echo -e "  ${GREEN}1.${NC} 检查并下载KPM模块"
    echo -e "  ${GREEN}2.${NC} 选择要嵌入的模块"
    echo -e "  ${GREEN}3.${NC} 修补boot镜像"
    echo -e "  ${GREEN}4.${NC} 选择是否刷入"
    echo ""
    
    echo -e "${CYAN}当前预设模块 (${#GITHUB_MODULES[@]}个):${NC}"
    show_line
    if [ ${#GITHUB_MODULES[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}没有预设模块${NC}"
        echo -e "  ${BLUE}请在脚本开头GITHUB_MODULES数组中添加${NC}"
    else
        for config in "${GITHUB_MODULES[@]}"; do
            local name=$(echo "$config" | cut -d'=' -f1)
            local status=""
            if [ -f "$KPM_DIR/$name" ]; then
                status="✓"
            else
                status="○"
            fi
            echo -e "  ${GREEN}$status${NC} $name"
        done
    fi
    show_line
    
    # 基础检查
    Basic_Check
    
    # 检查本地模块
    if ! check_local_modules; then
        exit 1
    fi
    
    echo ""
    show_step "开始处理..."
    
    # 解包boot
    if ! boot_unpack; then
        exit 1
    fi
    
    # 选择模块
    if select_kpm_module; then
        # 处理模块
        if [ "$selected_module" == "all" ]; then
            # 批量处理
            if batch_patch_modules; then
                if boot_repack; then
                    show_success "批量嵌入完成！"
                    flash_boot_image
                fi
            fi
        else
            # 单个处理
            if Kernel_patching "$selected_module"; then
                if boot_repack; then
                    show_success "模块嵌入完成！"
                    flash_boot_image
                fi
            fi
        fi
    fi
    
    echo ""
    show_line
    echo -e "${CYAN}    QQ群: ${QQ_GROUP}${NC}"
    echo -e "${CYAN}    作者：老懒鸭${NC}"
    show_line
}

# 运行主函数
main