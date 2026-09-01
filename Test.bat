@echo off
setlocal EnableDelayedExpansion

:loop

REM ============================================================
REM RANDOMLY SELECT API
REM
REM 0-3 = Login API       (40%)
REM 4-5 = Users API       (20%)
REM 6-7 = Order Create    (20%)
REM 8-9 = Orders API      (20%)
REM ============================================================

set /a apiType=%random% %% 10


REM ============================================================
REM LOGIN API
REM ============================================================

if !apiType! LSS 4 (

    call :selectUser

    REM 70% valid / 30% invalid
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
    REM Decide whether credentials should be valid
    REM 70% valid
    REM 30% invalid
    REM --------------------------------------------------------

    set /a orderAuthType=%random% %% 10

    if !orderAuthType! LSS 7 (

        REM Valid username + password

        echo.
        echo [%date% %time%] POST /ordercreate - VALID - User: !username!

    ) else (

        set /a invalidType=%random% %% 2

        if !invalidType!==0 (

            REM Valid username + wrong password

            set "password=wrongPassword123"

            echo.
            echo [%date% %time%] POST /ordercreate - INVALID PASSWORD - User: !username!

        ) else (

            REM Invalid username + wrong password

            set "username=InvalidUser"
            set "password=wrongPassword123"

            echo.
            echo [%date% %time%] POST /ordercreate - INVALID USERNAME + PASSWORD

        )
    )


    REM --------------------------------------------------------
    REM Random order details
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
    REM Call Order Create API
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

if !apiType! GEQ 8 (

    call :selectUser

    REM --------------------------------------------------------
    REM Decide whether credentials should be valid
    REM 70% valid
    REM 30% invalid
    REM --------------------------------------------------------

    set /a ordersAuthType=%random% %% 10

    if !ordersAuthType! LSS 7 (

        REM Valid username + password

        echo.
        echo [%date% %time%] POST /orders - VALID - User: !username!

    ) else (

        set /a invalidType=%random% %% 2

        if !invalidType!==0 (

            REM Valid username + wrong password

            set "password=wrongPassword123"

            echo.
            echo [%date% %time%] POST /orders - INVALID PASSWORD - User: !username!

        ) else (

            REM Invalid username + wrong password

            set "username=InvalidUser"
            set "password=wrongPassword123"

            echo.
            echo [%date% %time%] POST /orders - INVALID USERNAME + PASSWORD

        )
    )


    REM --------------------------------------------------------
    REM Call Orders API
    REM --------------------------------------------------------

    curl -s -X POST "http://localhost:3000/orders" ^
        -H "Content-Type: application/json" ^
        -d "{\"username\":\"!username!\",\"password\":\"!password!\"}"

    echo.
    goto wait
)


REM ============================================================
REM WAIT 1 SECOND
REM ============================================================

:wait

timeout /t 1 /nobreak >nul

goto loop


REM ============================================================
REM FUNCTION: SELECT RANDOM VALID USER
REM ============================================================

:selectUser

set /a randomUser=%random% %% 6

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
) else (
    set "username=Darshit"
    set "password=password123"
)

exit /b