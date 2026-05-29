#!/bin/bash

# Xcode 模擬器時間調整腳本
# 使用方法：
#   ./simulator_time.sh set "2025-01-23 14:30:00"  # 設定時間
#   ./simulator_time.sh clear                      # 恢復正常時間
#   ./simulator_time.sh now                        # 顯示當前模擬器時間

ACTION=$1
TIME=$2

# 檢查是否有模擬器在運行
if ! xcrun simctl list devices booted | grep -q "Booted"; then
    echo "❌ 沒有模擬器在運行，請先啟動一個模擬器"
    exit 1
fi

case $ACTION in
    set)
        if [ -z "$TIME" ]; then
            echo "❌ 請提供時間，格式：YYYY-MM-DD HH:MM:SS"
            echo "   範例：./simulator_time.sh set \"2025-01-23 14:30:00\""
            exit 1
        fi
        echo "⏰ 設定模擬器時間為：$TIME"
        xcrun simctl status_bar booted override --time "$TIME" \
            --dataNetwork wifi \
            --wifiMode active \
            --wifiBars 3 \
            --cellularMode active \
            --cellularBars 4 \
            --batteryState charged \
            --batteryLevel 100
        echo "✅ 時間已設定"
        ;;
    clear)
        echo "🔄 恢復模擬器正常時間"
        xcrun simctl status_bar booted clear
        echo "✅ 時間已恢復"
        ;;
    now)
        echo "📅 當前模擬器時間："
        xcrun simctl status_bar booted list
        ;;
    *)
        echo "使用方法："
        echo "  ./simulator_time.sh set \"2025-01-23 14:30:00\"  # 設定時間"
        echo "  ./simulator_time.sh clear                      # 恢復正常時間"
        echo "  ./simulator_time.sh now                        # 顯示當前時間"
        echo ""
        echo "常用時間範例："
        echo "  上課時間（週一上午）：./simulator_time.sh set \"2025-01-20 09:00:00\""
        echo "  上課時間（週五下午）：./simulator_time.sh set \"2025-01-24 14:00:00\""
        echo "  週末：./simulator_time.sh set \"2025-01-25 10:00:00\""
        exit 1
        ;;
esac



