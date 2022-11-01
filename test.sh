#!/bin/bash

echo "Network Creating...."
docker network create normal_py310_default >/dev/null 2>&1
docker network create shared_py310_default >/dev/null 2>&1
docker network create normal_py3110_default >/dev/null 2>&1
docker network create shared_py3110_default >/dev/null 2>&1

echo "Build...."
docker build -t fastapi-py310-normal-mem-leak-test py3.10-normal >/dev/null 2>&1
docker build -t fastapi-py310-shared-mem-leak-test py3.10-shared >/dev/null 2>&1
docker build -t fastapi-py3110-normal-mem-leak-test py3.11.0-normal >/dev/null 2>&1
docker build -t fastapi-py3110-shared-mem-leak-test py3.11.0-shared >/dev/null 2>&1

echo "Start Server...."
docker run --name fastapi-py310-normal --network normal_py310_default -p 15000:5000 -d fastapi-py310-normal-mem-leak-test >/dev/null 2>&1
docker run --name fastapi-py310-shared --network shared_py310_default -p 15001:5000 -d fastapi-py310-shared-mem-leak-test >/dev/null 2>&1
docker run --name fastapi-py3110-normal --network normal_py3110_default -p 15002:5000 -d fastapi-py3110-normal-mem-leak-test >/dev/null 2>&1
docker run --name fastapi-py3110-shared --network shared_py3110_default -p 15003:5000 -d fastapi-py3110-shared-mem-leak-test >/dev/null 2>&1
echo "Initial Mem Usage"
echo "=========================================="
docker stats fastapi-py310-normal fastapi-py310-shared fastapi-py3110-normal fastapi-py3110-shared --no-stream --format "{{.Name}}: {{.MemUsage}}"
echo "=========================================="
echo "Run fastapi-py310-normal"
echo "=========================================="
echo "Run vegeta to Normal(200req/sec, 10sec)"
docker run --name normal-vegeta --rm --network normal_py310_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py310-normal:5000/' | vegeta attack -rate=200 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "Run fastapi-py310-shared"
echo "=========================================="
echo "Run vegeta to Shared(200req/sec, 10sec)"
docker run --name shared-vegeta --rm --network shared_py310_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py310-shared:5000/' | vegeta attack -rate=200 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "Run fastapi-py3110-normal"
echo "=========================================="
echo "Run vegeta to Normal(200req/sec, 10sec)"
docker run --name normal-vegeta --rm --network normal_py3110_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py3110-normal:5000/' | vegeta attack -rate=200 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "Run fastapi-py3110-shared"
echo "=========================================="
echo "Run vegeta to Shared(200req/sec, 10sec)"
docker run --name shared-vegeta --rm --network shared_py3110_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py3110-shared:5000/' | vegeta attack -rate=200 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "After Requests Mem Usage"
docker stats fastapi-py310-normal fastapi-py310-shared fastapi-py3110-normal fastapi-py3110-shared --no-stream --format "{{.Name}}: {{.MemUsage}}"
# docker exec -it fastapi-py310-shared bash -c "ps -ef | grep [g]unicorn | awk '{print \$2}' | xargs -I{} ls -al /proc/{}/fd | grep sm_tokens"
echo "=========================================="
echo "=[LOG] Processed successfully(Python3.10 Normal)====="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.10 Normal)="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.10 Normal)=============="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Processed successfully(Python3.11.0 Normal)====="
bash -c "docker logs fastapi-py3110-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.11.0 Normal)="
bash -c "docker logs fastapi-py3110-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.11.0 Normal)=============="
bash -c "docker logs fastapi-py3110-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Processed successfully(Python3.10 Shared)====="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.10 Shared)="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.10 Shared)=============="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Cached Memory(Python3.10 Shared)=============="
docker logs fastapi-py310-shared 2>&1 | grep  Extend

echo "=[LOG] Processed successfully(Python3.11.0 Shared)====="
bash -c "docker logs fastapi-py3110-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.11.0 Shared)="
bash -c "docker logs fastapi-py3110-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.11.0 Shared)=============="
bash -c "docker logs fastapi-py3110-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3110-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Cached Memory(Python3.11.0 Shared)=============="
docker logs fastapi-py3110-shared 2>&1 | grep  Extend

# docker logs fastapi-py310-shared 2>&1 | grep -v Exceeded
echo "=========================================="
echo "Cleanup...."
docker stop fastapi-py310-normal fastapi-py310-shared fastapi-py3110-normal fastapi-py3110-shared >/dev/null 2>&1
docker stop normal-vegeta shared-vegeta >/dev/null 2>&1
echo "=========================================="
docker rm fastapi-py310-normal fastapi-py310-shared fastapi-py3110-normal fastapi-py3110-shared >/dev/null 2>&1
docker rm normal-vegeta shared-vegeta >/dev/null 2>&1
docker network rm normal_py310_default shared_py310_default normal_py3110_default shared_py3110_default >/dev/null 2>&1
