#!/bin/bash

# 快速設定模擬器為下午時間
# 使用方法：在模擬器運行時執行 ./scripts/set_afternoon.sh

# 取得今天的日期
TODAY=$(date +"%Y-%m-%d")

# 設定為今天下午 2:30
echo "⏰ 設定模擬器時間為今天下午 2:30..."
xcrun simctl status_bar booted override --time "14:30" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100

if [ $? -eq 0 ]; then
    echo "✅ 時間已設定為下午 2:30"
    echo "💡 提示：要恢復正常時間，執行：xcrun simctl status_bar booted clear"
else
    echo "❌ 設定失敗，請確認："
    echo "   1. 模擬器已經啟動（在 Xcode 中運行 App）"
    echo "   2. 模擬器已完全載入"
fi



