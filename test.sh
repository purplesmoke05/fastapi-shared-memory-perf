#!/bin/bash

echo "Network Creating...."
docker network create normal_py310_default >/dev/null 2>&1
docker network create normal_py3112_default >/dev/null 2>&1

echo "Build...."
docker build -t fastapi-py310-normal-mem-leak-test py3.10-normal >/dev/null 2>&1
docker build -t fastapi-py3112-normal-mem-leak-test py3.11.2-normal >/dev/null 2>&1

echo "Start Server...."
docker run --name fastapi-py310-normal --network normal_py310_default -p 15000:5000 -d -e WORKER_MAX_REQUESTS=0 fastapi-py310-normal-mem-leak-test >/dev/null 2>&1
docker run --name fastapi-py3112-normal --network normal_py3112_default -p 15002:5000 -d -e WORKER_MAX_REQUESTS=0 fastapi-py3112-normal-mem-leak-test >/dev/null 2>&1
echo "Initial Mem Usage"
echo "=========================================="
docker stats fastapi-py310-normal fastapi-py3112-normal --no-stream --format "{{.Name}}: {{.MemUsage}}"
echo "=========================================="
echo "Run fastapi-py310-normal"
echo "=========================================="
echo "Run vegeta to Normal(10req/sec, 10sec)"
docker run --name normal-vegeta --rm --network normal_py310_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py310-normal:5000/' | vegeta attack -rate=10 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "Run fastapi-py3112-normal"
echo "=========================================="
echo "Run vegeta to Normal(10req/sec, 10sec)"
docker run --name normal-vegeta --rm --network normal_py3112_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py3112-normal:5000/' | vegeta attack -rate=10 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "After Requests Mem Usage"
docker stats fastapi-py310-normal fastapi-py3112-normal --no-stream --format "{{.Name}}: {{.MemUsage}}"

echo "=========================================="
echo "=[LOG] Processed successfully(Python3.10 Normal)====="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.10 Normal)="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.10 Normal)=============="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Processed successfully(Python3.11.0 Normal)====="
bash -c "docker logs fastapi-py3112-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3112-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Python3.11.0 Normal)="
bash -c "docker logs fastapi-py3112-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3112-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Python3.11.0 Normal)=============="
bash -c "docker logs fastapi-py3112-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py3112-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=========================================="
echo "Cleanup...."
# docker stop fastapi-py310-normal fastapi-py3112-normal >/dev/null 2>&1
docker stop normal-vegeta >/dev/null 2>&1
echo "=========================================="
# docker rm fastapi-py310-normal fastapi-py3112-normal >/dev/null 2>&1
docker rm normal-vegeta >/dev/null 2>&1
docker network rm normal_py310_default normal_py3112_default >/dev/null 2>&1
