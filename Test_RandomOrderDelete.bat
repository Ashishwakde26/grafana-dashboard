@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM CONFIGURATION
REM ============================================================

set /a totalUsers=20
set /a registerCount=0

REM Temporary file used to store /orders API response
set "ordersResponseFile=%TEMP%\orders_response.json"

echo ============================================================
echo REGISTERING INITIAL USERS
echo ============================================================
echo.

:registerLoop
if !registerCount! LSS 20 (
    call :registerUser
    timeout /t 1 /nobreak >nul
    goto registerLoop
)

echo.
echo ============================================================
echo ALL USERS REGISTERED
echo STARTING LOAD TEST
echo ============================================================
echo.

:loop

REM ============================================================
REM RANDOM API SELECTION
REM
REM 0-3 = Login API          40%
REM 4-5 = Users API          20%
REM 6-7 = Order Create       20%
REM 8   = Orders API         10%
REM 9   = Order Delete       10%
REM
REM Register API is selected separately while registrations
REM are still below 20.
REM ============================================================

set /a apiType=%random% %% 10


REM ============================================================
REM LOGIN API
REM ============================================================

if !apiType! LSS 4 (


call :selectUser

REM --------------------------------------------------------
REM 70% VALID
REM 30% INVALID
REM --------------------------------------------------------

set /a loginType=%random% %% 10

if !loginType! LSS 7 (

    echo.
    echo [%date% %time%] POST /login - VALID - !username!

) else (

    set /a invalidType=%random% %% 2

    if !invalidType!==0 (

        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /login - INVALID PASSWORD - !username!

    ) else (

        set "username=InvalidUser"
        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /login - INVALID USERNAME + PASSWORD

    )
)

curl -s -X POST "http://localhost:3000/login" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"!username!\",\"password\":\"!password!\"}"

echo.
goto wait


)

REM ============================================================
REM USERS API
REM ============================================================

if !apiType! LSS 6 (


echo.
echo [%date% %time%] GET /users

curl -s -X GET "http://localhost:3000/users"

echo.
goto wait


)

REM ============================================================
REM ORDER CREATE API
REM ============================================================

if !apiType! LSS 8 (


call :selectUser

REM --------------------------------------------------------
REM 70% VALID
REM 30% INVALID
REM --------------------------------------------------------

set /a orderAuthType=%random% %% 10

if !orderAuthType! LSS 7 (

    echo.
    echo [%date% %time%] POST /ordercreate - VALID - User: !username!

) else (

    set /a invalidType=%random% %% 2

    if !invalidType!==0 (

        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /ordercreate - INVALID PASSWORD - User: !username!

    ) else (

        set "username=InvalidUser"
        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /ordercreate - INVALID USERNAME + PASSWORD

    )
)


REM --------------------------------------------------------
REM RANDOM ORDER DETAILS
REM --------------------------------------------------------

set /a productType=%random% %% 4

if !productType!==0 (

    set "product=Laptop"
    set "quantity=1"
    set "amount=75000"

) else if !productType!==1 (

    set "product=Mobile"
    set "quantity=1"
    set "amount=35000"

) else if !productType!==2 (

    set "product=Keyboard"
    set "quantity=2"
    set "amount=5000"

) else (

    set "product=Monitor"
    set "quantity=1"
    set "amount=25000"

)


REM --------------------------------------------------------
REM CALL ORDER CREATE API
REM --------------------------------------------------------

curl -s -X POST "http://localhost:3000/ordercreate" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"!username!\",\"password\":\"!password!\",\"order\":{\"product\":\"!product!\",\"quantity\":!quantity!,\"amount\":!amount!}}"

echo.
goto wait


)

REM ============================================================
REM ORDERS API
REM ============================================================

if !apiType!==8 (


call :selectUser

REM --------------------------------------------------------
REM 70% VALID
REM 30% INVALID
REM --------------------------------------------------------

set /a ordersAuthType=%random% %% 10

if !ordersAuthType! LSS 7 (

    echo.
    echo [%date% %time%] POST /orders - VALID - User: !username!

) else (

    set /a invalidType=%random% %% 2

    if !invalidType!==0 (

        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /orders - INVALID PASSWORD - User: !username!

    ) else (

        set "username=InvalidUser"
        set "password=wrongPassword123"

        echo.
        echo [%date% %time%] POST /orders - INVALID USERNAME + PASSWORD

    )
)


REM --------------------------------------------------------
REM CALL ORDERS API
REM --------------------------------------------------------

curl -s -X POST "http://localhost:3000/orders" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"!username!\",\"password\":\"!password!\"}"

echo.
goto wait


)

REM ============================================================
REM ORDER DELETE API
REM
REM First get the orders using VALID credentials.
REM Then randomly select one order_id from the response.
REM
REM Delete authentication:
REM
REM 70% = Correct username + password
REM 15% = Correct username + incorrect password
REM 15% = Incorrect username + password
REM ============================================================

if !apiType!==9 (

REM ============================================================
REM GET RANDOM ORDER ID
REM ============================================================

set "selectedOrderId="
set "randomOrderResponse=%TEMP%\randomOrderResponse.json"

curl -s "http://localhost:3000/randomorderid" -o "%randomOrderResponse%"

for /f "delims=" %%I in ('
powershell -NoProfile -Command ^
"$json = Get-Content -Raw '%randomOrderResponse%' | ConvertFrom-Json; if($json.orderId){$json.orderId}"
') do (
    set "selectedOrderId=%%I"
)

if not defined selectedOrderId (
    echo.
    echo [%date% %time%] NO ORDERS FOUND - SKIPPING DELETE
    echo Response:
    type "%randomOrderResponse%"
    echo.
    goto :AfterDelete
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

:AfterDelete

REM ============================================================
REM NEXT API CALLS CONTINUE HERE
REM ============================================================

echo [%date% %time%] CONTINUING LOAD TEST...


goto wait


)


REM ============================================================
REM WAIT 1 SECOND
REM ============================================================

:wait

timeout /t 1 /nobreak >nul
goto loop

REM ============================================================
REM FUNCTION: SELECT RANDOM USER
REM
REM These are the SAME 20 users that are registered.
REM ============================================================

:selectUser

set /a randomUser=%random% %% 20

if !randomUser!==0 (


set "username=Anand"
set "password=password123"


) else if !randomUser!==1 (


set "username=Ashish"
set "password=password123"


) else if !randomUser!==2 (


set "username=Rohit"
set "password=password123"


) else if !randomUser!==3 (


set "username=Abhay"
set "password=password123"


) else if !randomUser!==4 (


set "username=Anurag"
set "password=password123"


) else if !randomUser!==5 (


set "username=Darshit"
set "password=password123"


) else if !randomUser!==6 (


set "username=Vikram"
set "password=password123"


) else if !randomUser!==7 (


set "username=Rahul"
set "password=password123"


) else if !randomUser!==8 (


set "username=Akshay"
set "password=password123"


) else if !randomUser!==9 (


set "username=Prasad"
set "password=password123"


) else if !randomUser!==10 (


set "username=Karan"
set "password=password123"


) else if !randomUser!==11 (


set "username=Sachin"
set "password=password123"


) else if !randomUser!==12 (


set "username=Raj"
set "password=password123"


) else if !randomUser!==13 (


set "username=Vivek"
set "password=password123"


) else if !randomUser!==14 (


set "username=Nikhil"
set "password=password123"


) else if !randomUser!==15 (


set "username=Manish"
set "password=password123"


) else if !randomUser!==16 (


set "username=Rakesh"
set "password=password123"


) else if !randomUser!==17 (


set "username=Suresh"
set "password=password123"


) else if !randomUser!==18 (


set "username=Amit"
set "password=password123"


) else (


set "username=Deepak"
set "password=password123"


)

exit /b

REM ============================================================
REM FUNCTION: REGISTER USER
REM
REM Registration happens in sequence:
REM
REM 1  Anand
REM 2  Ashish
REM 3  Rohit
REM ...
REM 20 Deepak
REM
REM Each user is registered only once.
REM ============================================================

:registerUser

if !registerCount!==0 (


set "username=Anand"
set "password=password123"


) else if !registerCount!==1 (


set "username=Ashish"
set "password=password123"


) else if !registerCount!==2 (


set "username=Rohit"
set "password=password123"


) else if !registerCount!==3 (


set "username=Abhay"
set "password=password123"


) else if !registerCount!==4 (


set "username=Anurag"
set "password=password123"


) else if !registerCount!==5 (


set "username=Darshit"
set "password=password123"


) else if !registerCount!==6 (


set "username=Vikram"
set "password=password123"


) else if !registerCount!==7 (


set "username=Rahul"
set "password=password123"


) else if !registerCount!==8 (


set "username=Akshay"
set "password=password123"


) else if !registerCount!==9 (


set "username=Prasad"
set "password=password123"


) else if !registerCount!==10 (


set "username=Karan"
set "password=password123"


) else if !registerCount!==11 (


set "username=Sachin"
set "password=password123"


) else if !registerCount!==12 (


set "username=Raj"
set "password=password123"


) else if !registerCount!==13 (


set "username=Vivek"
set "password=password123"


) else if !registerCount!==14 (


set "username=Nikhil"
set "password=password123"


) else if !registerCount!==15 (


set "username=Manish"
set "password=password123"


) else if !registerCount!==16 (


set "username=Rakesh"
set "password=password123"


) else if !registerCount!==17 (


set "username=Suresh"
set "password=password123"


) else if !registerCount!==18 (


set "username=Amit"
set "password=password123"


) else (


set "username=Deepak"
set "password=password123"


)

REM ------------------------------------------------------------
REM CALL REGISTER API
REM ------------------------------------------------------------

echo.
echo [%date% %time%] POST /register - !username! - Registration !registerCount! of 20

curl -s -X POST "http://localhost:3000/register" ^
-H "Content-Type: application/json" ^
-d "{""username"":""!username!"",""password"":""!password!""}"

echo.

REM ------------------------------------------------------------
REM INCREMENT REGISTRATION COUNTER
REM ------------------------------------------------------------

set /a registerCount+=1

echo Registration count: !registerCount! / 20

exit /b
