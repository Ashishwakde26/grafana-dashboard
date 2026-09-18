@echo off

echo =================================================
echo STEP 1 - Create Kind Cluster
echo =================================================
kind create cluster --name monitoring-cluster --config kind-cluster.yaml
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 2 - Verify Cluster Nodes
echo =================================================
kubectl get nodes
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 3 - Deploy Application
echo =================================================
kubectl apply -f deployment.yaml
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 4 - Wait For Deployment
echo =================================================
kubectl rollout status deployment/nodejs-app --timeout=120s
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 5 - Verify Nodes
echo =================================================
kubectl get nodes
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 6 - Verify Pods
echo =================================================
kubectl get pods
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 7 - View Deployment
echo =================================================
kubectl get deployment nodejs-app -o yaml
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 8 - Create Service
echo =================================================
kubectl expose deployment nodejs-app --name=nodejs-app-service --port=3000 --target-port=3000
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 9 - Verify Service
echo =================================================
kubectl get svc
if errorlevel 1 exit /b 1

echo.
echo =================================================
echo STEP 10 - Port Forward
echo =================================================
kubectl port-forward service/nodejs-app-service 3000:3000 --address=0.0.0.0