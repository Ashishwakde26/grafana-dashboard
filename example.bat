REM ============================================================
REM GET RANDOM ORDER ID
REM ============================================================

set "selectedOrderId="
set "randomOrderResponse=%TEMP%\randomOrderResponse.json"

curl -s "http://localhost:3000/randomorderid" -o "%randomOrderResponse%"

for /f "delims=" %%I in ('
powershell -NoProfile -Command "(Get-Content -Raw '%randomOrderResponse%' | ConvertFrom-Json).orderId"
') do (
    set "selectedOrderId=%%I"
)

if not defined selectedOrderId (
    echo ERROR: No valid order ID returned.
    type "%randomOrderResponse%"
    exit /b 1
)

echo.
echo ============================================================
echo RANDOM ORDER SELECTED
echo Order ID : %selectedOrderId%
echo ============================================================
echo.

REM ============================================================
REM DELETE SELECTED ORDER
REM ============================================================

echo [%date% %time%] DELETE ORDER %selectedOrderId%

curl -s -X DELETE "http://localhost:3000/orders/%selectedOrderId%"

echo.
echo DELETE REQUEST COMPLETED
echo.