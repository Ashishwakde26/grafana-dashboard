@echo off
setlocal

set URL=http://3.93.57.179:3000

echo ============================================================
echo REGISTERING INITIAL USERS
echo ============================================================

call :REGISTER Anand
call :REGISTER Ashish
call :REGISTER Rohit
call :REGISTER Abhay
call :REGISTER Anurag
call :REGISTER Darshit
call :REGISTER Vikram
call :REGISTER Rahul
call :REGISTER Akshay
call :REGISTER Prasad
call :REGISTER Karan
call :REGISTER Sachin
call :REGISTER Raj
call :REGISTER Vivek
call :REGISTER Nikhil
call :REGISTER Manish
call :REGISTER Rakesh
call :REGISTER Suresh
call :REGISTER Amit
call :REGISTER Deepak

echo.
echo ============================================================
echo ALL USERS REGISTERED
echo STARTING RANDOM LOAD TEST
echo Press CTRL+C to stop
echo ============================================================

:LOOP

call :GET_RANDOM_USER

REM 0=REGISTER
REM 1=LOGIN_VALID
REM 2=LOGIN_INVALID
REM 3=GET_USERS
REM 4=ORDER_CREATE
REM 5=GET_ORDERS
REM 6=DELETE_ORDER

set /a ACTION=%RANDOM% %% 7

echo.
echo ============================================================
echo [%date% %time%]
echo ============================================================

if %ACTION%==0 goto REGISTER_RANDOM
if %ACTION%==1 goto LOGIN_VALID
if %ACTION%==2 goto LOGIN_INVALID
if %ACTION%==3 goto GET_USERS
if %ACTION%==4 goto CREATE_ORDER
if %ACTION%==5 goto GET_ORDERS
if %ACTION%==6 goto DELETE_ORDER

goto WAIT

:REGISTER_RANDOM

echo POST /register - User: %USERNAME%

curl -s -X POST "%URL%/register" ^
 -H "Content-Type: application/json" ^
 -d "{\"username\":\"%USERNAME%\",\"password\":\"password123\"}"

goto WAIT

:LOGIN_VALID

echo POST /login - VALID - User: %USERNAME%

curl -s -X POST "%URL%/login" ^
 -H "Content-Type: application/json" ^
 -d "{\"username\":\"%USERNAME%\",\"password\":\"password123\"}"

goto WAIT

:LOGIN_INVALID

set /a INVALIDTYPE=%RANDOM% %% 2

if %INVALIDTYPE%==0 (
    echo POST /login - INVALID PASSWORD - User: %USERNAME%

    curl -s -X POST "%URL%/login" ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"%USERNAME%\",\"password\":\"wrongpassword\"}"
) else (
    echo POST /login - INVALID USER

    curl -s -X POST "%URL%/login" ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"UnknownUser%RANDOM%\",\"password\":\"password123\"}"
)

goto WAIT

:GET_USERS

echo GET /users

curl -s "%URL%/users"

goto WAIT

:CREATE_ORDER

call :GET_RANDOM_PRODUCT

set /a QUANTITY=(%RANDOM% %% 5) + 1
set /a AMOUNT=((%RANDOM% %% 90) + 10) * 1000

echo POST /ordercreate - User: %USERNAME%
echo Product=%PRODUCT% Quantity=%QUANTITY% Amount=%AMOUNT%

curl -s -X POST "%URL%/ordercreate" ^
 -H "Content-Type: application/json" ^
 -d "{\"username\":\"%USERNAME%\",\"password\":\"password123\",\"order\":{\"product\":\"%PRODUCT%\",\"quantity\":%QUANTITY%,\"amount\":%AMOUNT%}}"

goto WAIT

:GET_ORDERS

set /a ORDERTYPE=%RANDOM% %% 3

if %ORDERTYPE%==0 (

    echo POST /orders - VALID - User: %USERNAME%

    curl -s -X POST "%URL%/orders" ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"%USERNAME%\",\"password\":\"password123\"}"

) else if %ORDERTYPE%==1 (

    echo POST /orders - INVALID PASSWORD - User: %USERNAME%

    curl -s -X POST "%URL%/orders" ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"%USERNAME%\",\"password\":\"wrongpassword\"}"

) else (

    echo POST /orders - INVALID USER

    curl -s -X POST "%URL%/orders" ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"UnknownUser%RANDOM%\",\"password\":\"password123\"}"

)

goto WAIT

:DELETE_ORDER

echo GET /randomorderid

set ORDERID=

for /f %%i in ('powershell -NoProfile -Command "(Invoke-RestMethod 'http://3.93.57.179:3000/randomorderid').orderId"') do (
    set ORDERID=%%i
)

echo OrderId=%ORDERID%

if "%ORDERID%"=="" (
    echo No order available for deletion.
    goto WAIT
)

echo DELETE /orders/%ORDERID%


curl -s -X DELETE "%URL%/orders" ^
 -H "Content-Type: application/json" ^
 -d "{\"orderId\":\"%ORDERID%\"}"

goto WAIT

:WAIT

echo.
echo ------------------------------------------------------------
timeout /t 1 /nobreak >nul
goto LOOP

:REGISTER

echo.
echo [%date% %time%] POST /register - %1

curl -s -X POST "%URL%/register" ^
 -H "Content-Type: application/json" ^
 -d "{\"username\":\"%~1\",\"password\":\"password123\"}"

timeout /t 1 /nobreak >nul
goto :eof

:GET_RANDOM_USER

set /a IDX=%RANDOM% %% 20

if %IDX%==0  set USERNAME=Anand
if %IDX%==1  set USERNAME=Ashish
if %IDX%==2  set USERNAME=Rohit
if %IDX%==3  set USERNAME=Abhay
if %IDX%==4  set USERNAME=Anurag
if %IDX%==5  set USERNAME=Darshit
if %IDX%==6  set USERNAME=Vikram
if %IDX%==7  set USERNAME=Rahul
if %IDX%==8  set USERNAME=Akshay
if %IDX%==9  set USERNAME=Prasad
if %IDX%==10 set USERNAME=Karan
if %IDX%==11 set USERNAME=Sachin
if %IDX%==12 set USERNAME=Raj
if %IDX%==13 set USERNAME=Vivek
if %IDX%==14 set USERNAME=Nikhil
if %IDX%==15 set USERNAME=Manish
if %IDX%==16 set USERNAME=Rakesh
if %IDX%==17 set USERNAME=Suresh
if %IDX%==18 set USERNAME=Amit
if %IDX%==19 set USERNAME=Deepak

goto :eof

:GET_RANDOM_PRODUCT

set /a P=%RANDOM% %% 10

if %P%==0 set PRODUCT=Laptop
if %P%==1 set PRODUCT=Mobile
if %P%==2 set PRODUCT=Headphones
if %P%==3 set PRODUCT=Monitor
if %P%==4 set PRODUCT=Keyboard
if %P%==5 set PRODUCT=Mouse
if %P%==6 set PRODUCT=Tablet
if %P%==7 set PRODUCT=SmartWatch
if %P%==8 set PRODUCT=Printer
if %P%==9 set PRODUCT=Camera

goto :eof