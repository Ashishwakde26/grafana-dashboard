@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo.
echo ============================================================
echo       KUBERNETES MONITORING STACK INSTALLATION
echo       Kind + Helm + Prometheus + Grafana
echo ============================================================
echo.

REM ============================================================
REM STEP 1 - CHECK REQUIRED TOOLS
REM ============================================================

echo.
echo ============================================================
echo STEP 1 - CHECK REQUIRED TOOLS
echo ============================================================
echo.

where kind >nul 2>&1
if errorlevel 1 (
echo ERROR: kind is not installed or not available in PATH.
goto FAIL
)
echo [OK] kind found.

where kubectl >nul 2>&1
if errorlevel 1 (
echo ERROR: kubectl is not installed or not available in PATH.
goto FAIL
)
echo [OK] kubectl found.

where helm >nul 2>&1
if errorlevel 1 (
echo ERROR: Helm is not installed or not available in PATH.
goto FAIL
)
echo [OK] Helm found.

where powershell >nul 2>&1
if errorlevel 1 (
echo ERROR: PowerShell is not available.
goto FAIL
)
echo [OK] PowerShell found.

echo.
echo Helm version:
helm version

if errorlevel 1 (
echo ERROR: Helm command failed.
goto FAIL
)

echo.
echo All required tools are available.

REM ============================================================
REM STEP 2 - CHECK KUBERNETES CLUSTER
REM ============================================================

echo.
echo ============================================================
echo STEP 2 - CHECK KUBERNETES CLUSTER
echo ============================================================
echo.

kubectl cluster-info >nul 2>&1

if errorlevel 1 (
echo ERROR: Kubernetes cluster is not reachable.
echo.
echo Please make sure your Kind cluster is running.
echo.
echo Check with:
echo kind get clusters
goto FAIL
)

echo [OK] Kubernetes cluster is reachable.

echo.
echo Kubernetes nodes:
kubectl get nodes

if errorlevel 1 (
echo ERROR: Unable to retrieve Kubernetes nodes.
goto FAIL
)

REM ============================================================
REM STEP 3 - CREATE MONITORING NAMESPACE
REM ============================================================

echo.
echo ============================================================
echo STEP 3 - CREATE MONITORING NAMESPACE
echo ============================================================
echo.

kubectl get namespace monitoring >nul 2>&1

if errorlevel 1 (
echo Monitoring namespace does not exist.
echo Creating monitoring namespace...

```
kubectl create namespace monitoring

if errorlevel 1 (
    echo ERROR: Failed to create monitoring namespace.
    goto FAIL
)

echo [OK] Monitoring namespace created.
```

) else (
echo [OK] Monitoring namespace already exists.
)

REM ============================================================
REM STEP 4 - ADD PROMETHEUS COMMUNITY HELM REPOSITORY
REM ============================================================

echo.
echo ============================================================
echo STEP 4 - ADD PROMETHEUS COMMUNITY HELM REPOSITORY
echo ============================================================
echo.

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

if errorlevel 1 (
echo ERROR: Failed to add prometheus-community Helm repository.
goto FAIL
)

echo [OK] Prometheus Community repository added.

REM ============================================================
REM STEP 5 - UPDATE HELM REPOSITORIES
REM ============================================================

echo.
echo ============================================================
echo STEP 5 - UPDATE HELM REPOSITORIES
echo ============================================================
echo.

helm repo update

if errorlevel 1 (
echo ERROR: Helm repository update failed.
goto FAIL
)

echo [OK] Helm repositories updated.

REM ============================================================
REM STEP 6 - INSTALL MONITORING STACK
REM ============================================================

echo.
echo ============================================================
echo STEP 6 - INSTALL / UPGRADE MONITORING STACK
echo ============================================================
echo.

echo Installing kube-prometheus-stack...
echo.

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

if errorlevel 1 (
echo.
echo ERROR: Monitoring stack installation failed.
goto FAIL
)

echo.
echo [OK] Monitoring stack installed/upgraded.

REM ============================================================
REM STEP 7 - CHECK HELM RELEASE
REM ============================================================

echo.
echo ============================================================
echo STEP 7 - CHECK HELM RELEASE
echo ============================================================
echo.

helm status monitoring --namespace monitoring

if errorlevel 1 (
echo ERROR: Helm release monitoring is not healthy.
goto FAIL
)

echo.
echo [OK] Helm release is available.

REM ============================================================
REM STEP 8 - WAIT FOR GRAFANA
REM ============================================================

echo.
echo ============================================================
echo STEP 8 - WAIT FOR GRAFANA
echo ============================================================
echo.

echo Waiting for Grafana deployment...

kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=400s

if errorlevel 1 (
echo ERROR: Grafana deployment did not become ready.
goto FAIL
)

echo [OK] Grafana deployment is ready.

REM ============================================================
REM STEP 9 - WAIT FOR PROMETHEUS
REM ============================================================

echo.
echo ============================================================
echo STEP 9 - WAIT FOR PROMETHEUS
echo ============================================================
echo.

echo Waiting for Prometheus pod...

set PROMETHEUS_READY=0

for /L %%N in (1,1,60) do (

```
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>nul | findstr /R "Running" >nul 2>&1

if not errorlevel 1 (
    set PROMETHEUS_READY=1
    goto PROMETHEUS_READY
)

echo Waiting for Prometheus... attempt %%N/60
timeout /t 5 /nobreak >nul
```

)

:PROMETHEUS_READY

if "!PROMETHEUS_READY!"=="0" (
echo ERROR: Prometheus did not become ready.
goto FAIL
)

echo [OK] Prometheus pod is running.

REM ============================================================
REM STEP 10 - WAIT FOR ALERTMANAGER
REM ============================================================

echo.
echo ============================================================
echo STEP 10 - WAIT FOR ALERTMANAGER
echo ============================================================
echo.

echo Waiting for Alertmanager pod...

set ALERTMANAGER_READY=0

for /L %%N in (1,1,60) do (

```
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers 2>nul | findstr /R "Running" >nul 2>&1

if not errorlevel 1 (
    set ALERTMANAGER_READY=1
    goto ALERTMANAGER_READY
)

echo Waiting for Alertmanager... attempt %%N/60
timeout /t 5 /nobreak >nul
```

)

:ALERTMANAGER_READY

if "!ALERTMANAGER_READY!"=="0" (
echo ERROR: Alertmanager did not become ready.
goto FAIL
)

echo [OK] Alertmanager pod is running.

REM ============================================================
REM STEP 11 - DISPLAY MONITORING PODS
REM ============================================================

echo.
echo ============================================================
echo STEP 11 - MONITORING PODS
echo ============================================================
echo.

kubectl get pods -n monitoring

if errorlevel 1 (
echo ERROR: Unable to retrieve monitoring pods.
goto FAIL
)

REM ============================================================
REM STEP 12 - CHECK REQUIRED SERVICES
REM ============================================================

echo.
echo ============================================================
echo STEP 12 - CHECK MONITORING SERVICES
echo ============================================================
echo.

echo Checking Grafana service...

kubectl get svc monitoring-grafana -n monitoring >nul 2>&1

if errorlevel 1 (
echo ERROR: monitoring-grafana service was not found.
echo.
echo Available services:
kubectl get svc -n monitoring
goto FAIL
)

echo [OK] Grafana service found.

echo.
echo Checking Prometheus service...

kubectl get svc monitoring-kube-prometheus-prometheus -n monitoring >nul 2>&1

if errorlevel 1 (
echo ERROR: Prometheus service was not found.
echo.
echo Available services:
kubectl get svc -n monitoring
goto FAIL
)

echo [OK] Prometheus service found.

echo.
echo Checking Alertmanager service...

kubectl get svc monitoring-kube-prometheus-alertmanager -n monitoring >nul 2>&1

if errorlevel 1 (
echo ERROR: Alertmanager service was not found.
echo.
echo Available services:
kubectl get svc -n monitoring
goto FAIL
)

echo [OK] Alertmanager service found.

REM ============================================================
REM STEP 13 - CHECK PORT AVAILABILITY
REM ============================================================

echo.
echo ============================================================
echo STEP 13 - CHECK LOCAL PORTS
echo ============================================================
echo.

netstat -ano | findstr /R /C:":3001 " >nul 2>&1

if not errorlevel 1 (
echo ERROR: Port 3001 is already in use.
echo Please stop the process using port 3001 and run this script again.
goto FAIL
)

echo [OK] Port 3001 available.

netstat -ano | findstr /R /C:":9090 " >nul 2>&1

if not errorlevel 1 (
echo ERROR: Port 9090 is already in use.
echo Please stop the process using port 9090 and run this script again.
goto FAIL
)

echo [OK] Port 9090 available.

netstat -ano | findstr /R /C:":9093 " >nul 2>&1

if not errorlevel 1 (
echo ERROR: Port 9093 is already in use.
echo Please stop the process using port 9093 and run this script again.
goto FAIL
)

echo [OK] Port 9093 available.

REM ============================================================
REM STEP 14 - GET GRAFANA PASSWORD
REM ============================================================

echo.
echo ============================================================
echo STEP 14 - GET GRAFANA ADMIN PASSWORD
echo ============================================================
echo.

set "GRAFANA_B64="
set "GRAFANA_PASSWORD="

for /f "delims=" %%i in ('kubectl get secret monitoring-grafana -n monitoring -o jsonpath^="{.data.admin-password}"') do (
set "GRAFANA_B64=%%i"
)

if "!GRAFANA_B64!"=="" (
echo ERROR: Could not retrieve Grafana admin password.
goto FAIL
)

for /f "delims=" %%i in ('powershell -NoProfile -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('!GRAFANA_B64!'))"') do (
set "GRAFANA_PASSWORD=%%i"
)

if "!GRAFANA_PASSWORD!"=="" (
echo ERROR: Could not decode Grafana admin password.
goto FAIL
)

echo [OK] Grafana admin password retrieved.

REM ============================================================
REM STEP 15 - START GRAFANA PORT FORWARD
REM ============================================================

echo.
echo ============================================================
echo STEP 15 - START GRAFANA PORT FORWARD
echo ============================================================
echo.

echo Starting Grafana port-forward...
echo.

start "Grafana Port Forward" cmd /c "kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80"

echo Grafana port-forward process started.
echo Waiting for Grafana to respond...

set GRAFANA_OK=0

for /L %%N in (1,1,30) do (

```
powershell -NoProfile -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:3001' -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1

if not errorlevel 1 (
    set GRAFANA_OK=1
    goto GRAFANA_RUNNING
)

echo Waiting for Grafana... attempt %%N/30
timeout /t 2 /nobreak >nul
```

)

:GRAFANA_RUNNING

if "!GRAFANA_OK!"=="0" (
echo ERROR: Grafana port-forward did not become ready.
goto FAIL
)

echo [OK] Grafana is accessible on port 3001.

REM ============================================================
REM STEP 16 - START PROMETHEUS PORT FORWARD
REM ============================================================

echo.
echo ============================================================
echo STEP 16 - START PROMETHEUS PORT FORWARD
echo ============================================================
echo.

echo Starting Prometheus port-forward...
echo.

start "Prometheus Port Forward" cmd /c "kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"

echo Prometheus port-forward process started.
echo Waiting for Prometheus to respond...

set PROMETHEUS_OK=0

for /L %%N in (1,1,30) do (

```
powershell -NoProfile -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:9090/-/ready' -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1

if not errorlevel 1 (
    set PROMETHEUS_OK=1
    goto PROMETHEUS_RUNNING
)

echo Waiting for Prometheus... attempt %%N/30
timeout /t 2 /nobreak >nul
```

)

:PROMETHEUS_RUNNING

if "!PROMETHEUS_OK!"=="0" (
echo ERROR: Prometheus port-forward did not become ready.
goto FAIL
)

echo [OK] Prometheus is accessible on port 9090.

REM ============================================================
REM STEP 17 - START ALERTMANAGER PORT FORWARD
REM ============================================================

echo.
echo ============================================================
echo STEP 17 - START ALERTMANAGER PORT FORWARD
echo ============================================================
echo.

echo Starting Alertmanager port-forward...
echo.

start "Alertmanager Port Forward" cmd /c "kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093"

echo Alertmanager port-forward process started.
echo Waiting for Alertmanager to respond...

set ALERTMANAGER_OK=0

for /L %%N in (1,1,30) do (

```
powershell -NoProfile -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:9093/-/ready' -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1

if not errorlevel 1 (
    set ALERTMANAGER_OK=1
    goto ALERTMANAGER_RUNNING
)

echo Waiting for Alertmanager... attempt %%N/30
timeout /t 2 /nobreak >nul
```

)

:ALERTMANAGER_RUNNING

if "!ALERTMANAGER_OK!"=="0" (
echo ERROR: Alertmanager port-forward did not become ready.
goto FAIL
)

echo [OK] Alertmanager is accessible on port 9093.

REM ============================================================
REM STEP 18 - FINAL STATUS
REM ============================================================

echo.
echo ============================================================
echo              MONITORING STACK READY
echo ============================================================
echo.

echo Monitoring namespace:
kubectl get pods -n monitoring

echo.
echo Monitoring services:
kubectl get svc -n monitoring

echo.
echo ============================================================
echo                 ACCESS INFORMATION
echo ============================================================
echo.

echo Grafana:
echo URL      : http://localhost:3001
echo Username : admin
echo Password : !GRAFANA_PASSWORD!

echo.
echo Prometheus:
echo URL      : http://localhost:9090

echo.
echo Alertmanager:
echo URL      : http://localhost:9093

echo.
echo ============================================================
echo IMPORTANT
echo ============================================================
echo.
echo Three separate CMD windows have been opened for:
echo.
echo 1. Grafana port-forward
echo 2. Prometheus port-forward
echo 3. Alertmanager port-forward
echo.
echo DO NOT CLOSE those three windows while using the monitoring stack.
echo.
echo To stop the monitoring port-forwards, close those CMD windows.
echo.
echo To stop the monitoring stack completely:
echo helm uninstall monitoring -n monitoring
echo.
echo To delete the Kind cluster:
echo kind delete cluster --name monitoring-cluster
echo.
echo ============================================================
echo                 INSTALLATION SUCCESSFUL
echo ============================================================
echo.

pause
exit /b 0

REM ============================================================
REM FAILURE HANDLER
REM ============================================================

:FAIL

echo.
echo ============================================================
echo                    SCRIPT FAILED
echo ============================================================
echo.
echo One of the required steps failed.
echo The script has been stopped.
echo.
echo Check the error message above.
echo.
echo Current Kubernetes status:
echo.

kubectl get nodes 2>nul
echo.

echo Monitoring namespace status:
kubectl get pods -n monitoring 2>nul

echo.
echo ============================================================

pause
exit /b 1
